import 'dart:convert';

import 'package:js/js_util.dart';
import 'package:flutter/material.dart';
import 'package:graphview/graph.dart';
import 'package:graphview/algorithm.dart';
import 'package:graphview/edge_renderer/edge_renderer.dart';
import 'elk_js_interop.dart';

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

  ELKAlgorithm({
    this.layoutOptions = const {
      'elk.algorithm': 'layered',
      'elk.direction': 'DOWN',
      'elk.spacing.nodeNode': '40',
    },
    this.renderer,
  });

  /// Asynchronously computes the ELK layout and writes x/y positions directly
  /// onto each [Node] in [graph]. Call this BEFORE building the [GraphView].
  Future<Size> computeLayout(Graph graph) async {
    // 1. Build a plain Dart map describing the graph for ELK.
    final graphDescription = <String, dynamic>{
      'id': 'root',
      'layoutOptions': <String, String>{
        for (final e in layoutOptions.entries) e.key: e.value.toString(),
      },
      'children': <Map<String, dynamic>>[
        for (final node in graph.nodes)
          <String, dynamic>{
            'id': node.key?.value.toString() ?? node.hashCode.toString(),
            'width': node.width <= 0 ? 50.0 : node.width,
            'height': node.height <= 0 ? 50.0 : node.height,
          },
      ],
      'edges': <Map<String, dynamic>>[
        for (int i = 0; i < graph.edges.length; i++)
          if (!graph.edges[i].ghost)
            <String, dynamic>{
              'id': 'e$i',
              'sources': <String>[graph.edges[i].source.key!.value.toString()],
              'targets': <String>[graph.edges[i].destination.key!.value.toString()],
            },
      ],
    };

    // 2. jsonEncode → JSON.parse roundtrip to guarantee native JS objects.
    final jsGraph = jsonParse(jsonEncode(graphDescription));

    // 3. Call ELK.
    final elk = ELK();
    final jsResult = await promiseToFuture(elk.layout(jsGraph));

    // 4. Read results and set node positions.
    double maxX = 0, maxY = 0;
    final dynamic children = getProperty(jsResult, 'children');
    if (children != null) {
      final int len = getProperty(children, 'length') ?? 0;
      for (int i = 0; i < len; i++) {
        final dynamic elkNode = getProperty(children, i);
        final String id = getProperty(elkNode, 'id').toString();
        final double x = (getProperty(elkNode, 'x') as num?)?.toDouble() ?? 0;
        final double y = (getProperty(elkNode, 'y') as num?)?.toDouble() ?? 0;

        final node = graph.nodes.firstWhere(
          (n) => n.key?.value.toString() == id,
          orElse: () => Node.Id('__missing__'),
        );

        if (node.key?.value.toString() != '__missing__') {
          node.x = x;
          node.y = y;
          maxX = maxX > (x + node.width) ? maxX : (x + node.width);
          maxY = maxY > (y + node.height) ? maxY : (y + node.height);
        }
      }
    }

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

    // Just apply the shift offset to each node (GraphView may pass nonzero shifts).
    if (shiftX != 0 || shiftY != 0) {
      for (final node in graph.nodes) {
        node.x = node.x + shiftX;
        node.y = node.y + shiftY;
      }
    }

    return _graphSize;
  }

  @override
  void setDimensions(double width, double height) {}
}
