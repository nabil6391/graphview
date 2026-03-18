import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:graphview/graph.dart';
import 'package:graphview/algorithm.dart';
import 'package:graphview/edge_renderer/edge_renderer.dart';
import 'elk_js_interop.dart';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:collection/collection.dart';

/// An [Algorithm] that uses ELK JS for layout computation (web only).
///
/// **Usage:** Call [computeLayout] first to asynchronously compute positions.
/// Then pass this algorithm to [GraphView]. The synchronous [run] method only
/// reports the bounding box of the already-positioned nodes.
class ELKAlgorithm implements Algorithm {
  @override
  EdgeRenderer? renderer;

  final Map<String, dynamic> layoutOptions;

  /// The computed bounding size of the graph after [computeLayout] finishes.
  Size _graphSize = Size.zero;
  final Map<Node, Offset> _basePositions = {};
  final Map<Edge, List<Offset>> _baseSections = {};

  ELKAlgorithm({
    this.layoutOptions = const {
      'elk.algorithm': 'radial',
      'elk.radial.definition': 'LEVEL_BASED',
      'elk.radial.root': '0',
      'elk.separateConnectedComponents': 'true',
      'elk.radial.radius': '350',
      'elk.spacing.nodeNode': '100',
      'elk.spacing.componentComponent': '200',
      'elk.radial.compactor': 'NONE'
    },
    this.renderer,
  });

  Future<Size> computeLayout(
    Graph graph, {
    Set<String> collapsedNodeIds = const {},
    Set<String> hiddenNodeIds = const {},
    Set<String> hubNodeIds = const {},
  }) async {
    // 0. Clear stale data
    for (final e in graph.edges) { e.sections = null; }
    _basePositions.clear();
    _baseSections.clear();

    // 1. Build hierarchy map from structural edges, ignoring hidden nodes
    final childrenMap = <String, List<Node>>{};
    final containedNodeIds = <String>{};
    final containmentEdges = <Edge>{};

    final visibleNodes = graph.nodes
        .where((n) => !hiddenNodeIds.contains(n.key!.value.toString()))
        .toList();

    for (final edge in graph.edges) {
      final sourceId = edge.source.key!.value.toString();
      final targetId = edge.destination.key!.value.toString();

      // SourceId is the Parent (Hub). TargetId is the Child.
      if (hubNodeIds.contains(sourceId)) {
        if (!hiddenNodeIds.contains(sourceId) &&
            !hiddenNodeIds.contains(targetId)) {
          // Enforce strict tree containment: a node can only be nested in one parent
          if (!containedNodeIds.contains(targetId)) {
            childrenMap.putIfAbsent(sourceId, () => []).add(edge.destination);
            containedNodeIds.add(targetId);
            containmentEdges.add(edge);
          }
        }
      }
    }

    // Identify root nodes (nodes with no containment parent among visible nodes)
    final roots = visibleNodes
        .where((n) => !containedNodeIds.contains(n.key!.value.toString()))
        .toList();

    // Helper to get the correct ELK ID for an edge target
    String getElkNodeId(String nodeId) =>
        (childrenMap[nodeId]?.isNotEmpty ?? false)
            ? 'container_$nodeId'
            : nodeId;

    // 2. Build recursive ELK JSON
    Map<String, dynamic> buildElkNode(Node node) {
      final id = node.key!.value.toString();
      final isCollapsed = collapsedNodeIds.contains(id);
      final children = isCollapsed ? <Node>[] : (childrenMap[id] ?? []);

      if (children.isNotEmpty) {
        return <String, dynamic>{
          'id': 'container_$id',
          'layoutOptions': <String, String>{
            'elk.algorithm': 'radial',
            'elk.radial.root': id,
            'elk.radial.radius': '450',
            'elk.radial.compactor': 'NONE',
            'elk.padding': '[top=100,left=100,bottom=100,right=100]',
            'elk.spacing.nodeNode': '150',
            'elk.spacing.componentComponent': '150',
          },
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': id,
              'width': node.width <= 0 ? 350.0 : node.width,
              'height': node.height <= 0 ? 150.0 : node.height,
              if (node.metadata.containsKey('partition'))
                'partition': node.metadata['partition'],
            },
            ...children.map((c) => buildElkNode(c)),
          ],
          'edges': <Map<String, dynamic>>[
            for (final edge in containmentEdges
                .where((e) => e.source.key!.value.toString() == id))
              <String, dynamic>{
                'id': 'e_${edge.hashCode}',
                'sources': <String>[id],
                // Point to the container if the child is a hub to prevent hierarchical cross-edges
                'targets': <String>[
                  getElkNodeId(edge.destination.key!.value.toString())
                ],
              }
          ]
        };
      }

      return <String, dynamic>{
        'id': id,
        'width': node.width <= 0 ? 350.0 : node.width,
        'height': node.height <= 0 ? 150.0 : node.height,
        if (node.metadata.containsKey('partition'))
          'partition': node.metadata['partition'],
      };
    }

    final graphDescription = <String, dynamic>{
      'id': 'root',
      'layoutOptions': <String, String>{
        for (final e in layoutOptions.entries) e.key: e.value.toString(),
      },
      'children': roots.map((r) => buildElkNode(r)).toList(),
      // We only pass structural edges to ELK.
      // Containment edges are handled internally by the Hub containers.
      // Non-structural cross-dependencies remain invisible to ELK and are drawn by Flutter post-render.
      'edges': <Map<String, dynamic>>[
        for (int i = 0; i < graph.edges.length; i++)
          if (!containmentEdges.contains(graph.edges[i]) &&
              !hiddenNodeIds
                  .contains(graph.edges[i].source.key!.value.toString()) &&
              !hiddenNodeIds
                  .contains(graph.edges[i].destination.key!.value.toString()))
            <String, dynamic>{
              'id': 'e$i',
              'sources': <String>[
                getElkNodeId(graph.edges[i].source.key!.value.toString())
              ],
              'targets': <String>[
                getElkNodeId(graph.edges[i].destination.key!.value.toString())
              ],
            }
      ],
    };

    // 3. Call ELK
    final jsGraph = jsonParse(jsonEncode(graphDescription));
    final elk = ELK();
    final jsResult = await elk.layout(jsGraph).toDart;

    if (jsResult == null) return Size.zero;
    final resultObj = jsResult as JSObject;

    // 4. Recursively apply relative coordinates to calculate absolute positions
    double maxX = 0, maxY = 0;

    void processElkNode(JSObject elkNode, double offsetX, double offsetY) {
      final id = (elkNode.getProperty('id'.toJS) as JSString).toDart;
      final x = (elkNode.getProperty('x'.toJS) as JSNumber).toDartDouble;
      final y = (elkNode.getProperty('y'.toJS) as JSNumber).toDartDouble;

      final absoluteX = x + offsetX;
      final absoluteY = y + offsetY;

      final node = graph.nodes.firstWhereOrNull(
        (n) => n.key?.value.toString() == id,
      );

      if (node != null) {
        node.x = absoluteX;
        node.y = absoluteY;
        _basePositions[node] = Offset(absoluteX, absoluteY);

        maxX =
            maxX > (absoluteX + node.width) ? maxX : (absoluteX + node.width);
        maxY =
            maxY > (absoluteY + node.height) ? maxY : (absoluteY + node.height);
      }

      final children = elkNode.getProperty('children'.toJS) as JSArray?;
      if (children != null) {
        for (var i = 0; i < children.length; i++) {
          final childNode = children.getProperty(i.toJS) as JSObject;
          // IMPORTANT: ELK coordinates are relative to the parent box's padding/content area.
          // However, in ELK JSON layout, 'x' and 'y' of a node are relative to its parent's (0,0).
          processElkNode(childNode, absoluteX, absoluteY);
        }
      }
    }

    final resultChildren = resultObj.getProperty('children'.toJS) as JSArray?;
    if (resultChildren != null) {
      for (var i = 0; i < resultChildren.length; i++) {
        final elkNode = resultChildren.getProperty(i.toJS) as JSObject;
        processElkNode(elkNode, 0, 0);
      }
    }

    // 5. Recursively process edges to capture sections and bend points
    void processEdges(JSObject elkNode, double offsetX, double offsetY) {
        final edges = elkNode.getProperty('edges'.toJS) as JSArray?;
        if (edges != null) {
            for (var i = 0; i < edges.length; i++) {
                final elkEdge = edges.getProperty(i.toJS) as JSObject;
                final id = (elkEdge.getProperty('id'.toJS) as JSString).toDart;
                
                // Identify the graph edge. We used 'e$i' or 'e_${edge.hashCode}'
                Edge? edge;
                if (id.startsWith('e_')) {
                    final hashCodeString = id.substring(2);
                    final hashCode = int.tryParse(hashCodeString);
                    edge = graph.edges.firstWhereOrNull((e) => e.hashCode == hashCode);
                } else if (id.startsWith('e')) {
                    final indexString = id.substring(1);
                    final index = int.tryParse(indexString);
                    if (index != null && index < graph.edges.length) {
                        edge = graph.edges[index];
                    }
                }

                if (edge != null) {
                    final sections = elkEdge.getProperty('sections'.toJS) as JSArray?;
                    if (sections != null && sections.length > 0) {
                        final section = sections.getProperty(0.toJS) as JSObject;
                        final start = section.getProperty('startPoint'.toJS) as JSObject;
                        final end = section.getProperty('endPoint'.toJS) as JSObject;
                        final bends = section.getProperty('bendPoints'.toJS) as JSArray?;

                        final List<Offset> points = [];
                        points.add(Offset(
                            (start.getProperty('x'.toJS) as JSNumber).toDartDouble + offsetX,
                            (start.getProperty('y'.toJS) as JSNumber).toDartDouble + offsetY,
                        ));

                        if (bends != null) {
                            for (var j = 0; j < bends.length; j++) {
                                final bend = bends.getProperty(j.toJS) as JSObject;
                                points.add(Offset(
                                    (bend.getProperty('x'.toJS) as JSNumber).toDartDouble + offsetX,
                                    (bend.getProperty('y'.toJS) as JSNumber).toDartDouble + offsetY,
                                ));
                            }
                        }

                        points.add(Offset(
                            (end.getProperty('x'.toJS) as JSNumber).toDartDouble + offsetX,
                            (end.getProperty('y'.toJS) as JSNumber).toDartDouble + offsetY,
                        ));

                        edge.sections = points;
                        _baseSections[edge] = List<Offset>.from(points);
                    }
                }
            }
        }

        final children = elkNode.getProperty('children'.toJS) as JSArray?;
        if (children != null) {
            for (var i = 0; i < children.length; i++) {
                final child = children.getProperty(i.toJS) as JSObject;
                final x = (child.getProperty('x'.toJS) as JSNumber).toDartDouble;
                final y = (child.getProperty('y'.toJS) as JSNumber).toDartDouble;
                processEdges(child, offsetX + x, offsetY + y);
            }
        }
    }

    processEdges(resultObj, 0, 0);

    _graphSize = Size(maxX, maxY);
    return _graphSize;
  }

  // ---------- Algorithm interface (synchronous) ----------

  @override
  void init(Graph? graph) {}

  /// Returns the bounding size. Does NOT compute layout — that must be done
  /// beforehand via [computeLayout].
  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null) return _graphSize;

    // Apply the shift offset relative to the original computed base positions.
    // This prevents cumulative shifting when run() is called multiple times.
    for (final node in graph.nodes) {
      final base = _basePositions[node] ?? Offset(node.x, node.y);
      node.x = base.dx + shiftX;
      node.y = base.dy + shiftY;
    }

    for (final edge in graph.edges) {
        final base = _baseSections[edge];
        if (base != null) {
            edge.sections = base.map((p) => Offset(p.dx + shiftX, p.dy + shiftY)).toList();
        }
    }

    return _graphSize;
  }

  @override
  void setDimensions(double width, double height) {}
}
