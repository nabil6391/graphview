import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:graphview/graph.dart';
import 'package:graphview/algorithm.dart';
import 'package:graphview/edge_renderer/edge_renderer.dart';
import 'package:collection/collection.dart';
import 'elk_js_interop.dart';

/// The ELK (Eclipse Layout Kernel) algorithm implementation for the web.
class ELKAlgorithm extends Algorithm {
  final Map<String, String> layoutOptions;
  @override
  EdgeRenderer? renderer;
  Size _graphSize = Size.zero;

  final Map<Node, Offset> _basePositions = {};
  final Map<Edge, List<Offset>> _baseSections = {};

  ELKAlgorithm({
    this.layoutOptions = const {
      'elk.algorithm': 'layered',
      'elk.direction': 'RIGHT',
      'elk.edgeRouting': 'ORTHOGONAL',
      'elk.layered.edgeRouting': 'ORTHOGONAL',
      'elk.portConstraints': 'FREE',
      'elk.layered.spacing.nodeNodeLayered': '150',
      'elk.spacing.nodeNode': '150',
      'elk.spacing.componentComponent': '250',
      'elk.padding': '[top=50,left=50,bottom=50,right=50]',
      'elk.spacing.edgeNode': '40',
      'elk.spacing.edgeEdge': '20',
    },
    this.renderer,
  });

  @override
  void init(Graph? graph) {}

  Future<Size> computeLayout(
    Graph graph, {
    double shiftX = 0,
    double shiftY = 0,
    Set<String> collapsedNodeIds = const {},
    Set<String> hiddenNodeIds = const {},
    Set<String> hubNodeIds = const {},
  }) async {
    final elkGraph = <String, dynamic>{
      'id': 'virtual_root',
      'layoutOptions': layoutOptions,
      'children': <Map<String, dynamic>>[],
      'edges': <Map<String, dynamic>>[],
    };

    final nodeLookup = <String, Node>{};
    final containers = <String, Map<String, dynamic>>{};

    Map<String, dynamic> getElkNode(String id) {
      if (containers.containsKey(id)) return containers[id]!;

      final node =
          graph.nodes.firstWhereOrNull((n) => n.key?.value.toString() == id);
      if (node == null) return elkGraph;

      final Map<String, dynamic> elkNode;
      if (node.metadata['isParent'] == true) {
        elkNode = {
          'id': id,
          'layoutOptions': {
            ...layoutOptions,
            'elk.padding': '[top=150,left=150,bottom=150,right=150]',
            'elk.spacing.edgeNode': '60',
          },
          'children': <Map<String, dynamic>>[],
          'edges': <Map<String, dynamic>>[],
        };
      } else {
        elkNode = {
          'id': id,
          'width': node.width,
          'height': node.height,
        };
      }

      containers[id] = elkNode;

      final parentId = node.metadata['parentId']?.toString();
      if (parentId != null && parentId != id) {
        final parentElk = getElkNode(parentId);
        final childrenList = (parentElk['children'] ?? elkGraph['children'])
            as List<Map<String, dynamic>>;
        childrenList.add(elkNode);
      } else {
        final childrenList = elkGraph['children'] as List<Map<String, dynamic>>;
        childrenList.add(elkNode);
      }

      return elkNode;
    }

    for (final node in graph.nodes) {
      final id = node.key?.value.toString() ?? '';
      nodeLookup[id] = node;
      getElkNode(id);
    }

    for (final edge in graph.edges) {
      final sourceId = edge.source.key?.value.toString() ?? '';
      final destinationId = edge.destination.key?.value.toString() ?? '';

      final elkEdges = elkGraph['edges'] as List<Map<String, dynamic>>;
      elkEdges.add({
        'id': 'e_${sourceId}_$destinationId',
        'sources': [sourceId],
        'targets': [destinationId],
      });
    }

    final jsGraph = jsonParse(jsonEncode(elkGraph));
    final resultPromise = ELK().layout(jsGraph);
    final jsResult = await resultPromise.toDart;
    final resultJson = jsonStringify(jsResult as JSObject);
    final result = jsonDecode(resultJson) as Map<String, dynamic>;

    _basePositions.clear();
    _baseSections.clear();

    void updateNodePositions(
        Map<String, dynamic> elkNode, double offsetX, double offsetY) {
      final id = elkNode['id']?.toString() ?? '';
      final x = (elkNode['x'] as num?)?.toDouble() ?? 0.0;
      final y = (elkNode['y'] as num?)?.toDouble() ?? 0.0;

      final absoluteX = x + offsetX;
      final absoluteY = y + offsetY;

      if (nodeLookup.containsKey(id)) {
        final node = nodeLookup[id]!;
        node.position = Offset(absoluteX, absoluteY);
        _basePositions[node] = node.position;
      }

      final children = elkNode['children'] as List?;
      if (children != null) {
        for (final child in children) {
          updateNodePositions(
              child as Map<String, dynamic>, absoluteX, absoluteY);
        }
      }
    }

    updateNodePositions(result, 0.0, 0.0);

    final edges = result['edges'] as List?;
    if (edges != null) {
      for (final edgeData in edges) {
        final rawId = edgeData['id']?.toString() ?? '';
        final id = rawId.startsWith('e_') ? rawId.substring(2) : rawId;
        final parts = id.split('_');
        if (parts.length < 2) continue;

        final srcId = parts[0];
        final dstId = parts[1];

        final edge = graph.edges.firstWhereOrNull((e) =>
            e.source.key?.value.toString() == srcId &&
            e.destination.key?.value.toString() == dstId);

        if (edge != null) {
          final sections = edgeData['sections'] as List?;
          if (sections != null && sections.isNotEmpty) {
            final section = sections.first as Map<String, dynamic>;
            final startPoint = section['startPoint'] as Map<String, dynamic>;
            final endPoint = section['endPoint'] as Map<String, dynamic>;
            final bendPoints = section['bendPoints'] as List?;

            final points = <Offset>[];
            points.add(Offset((startPoint['x'] as num).toDouble(),
                (startPoint['y'] as num).toDouble()));
            if (bendPoints != null) {
              for (final bend in bendPoints) {
                points.add(Offset((bend['x'] as num).toDouble(),
                    (bend['y'] as num).toDouble()));
              }
            }
            points.add(Offset((endPoint['x'] as num).toDouble(),
                (endPoint['y'] as num).toDouble()));
            edge.sections = points;
            _baseSections[edge] = List.from(points);
          }
        }
      }
    }

    _graphSize = Size((result['width'] as num).toDouble(),
        (result['height'] as num).toDouble());
    return run(graph, shiftX, shiftY);
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null) return _graphSize;

    for (var node in graph.nodes) {
      final base = _basePositions[node];
      if (base != null) {
        node.position = Offset(base.dx + shiftX, base.dy + shiftY);
      }
    }

    for (final edge in graph.edges) {
      final base = _baseSections[edge];
      if (base != null) {
        edge.sections =
            base.map((p) => Offset(p.dx + shiftX, p.dy + shiftY)).toList();
      }
    }

    return _graphSize;
  }

  @override
  void setDimensions(double width, double height) {}
}
