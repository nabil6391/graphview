import 'package:flutter/material.dart';
import 'package:graphview/graph.dart';
import 'package:graphview/algorithm.dart';
import 'package:graphview/edge_renderer/edge_renderer.dart';

/// Stub implementation of [ELKAlgorithm] for non-web platforms.
/// Layout is not supported — nodes remain at their default positions.
class ELKAlgorithm implements Algorithm {
  @override
  EdgeRenderer? renderer;

  final Map<String, dynamic> layoutOptions;

  ELKAlgorithm({
    this.layoutOptions = const {},
    this.renderer,
  });

  /// No-op on non-web platforms. Returns [Size.zero].
  Future<Size> computeLayout(
    Graph graph, {
    Set<String> collapsedNodeIds = const {},
    Set<String> hiddenNodeIds = const {},
    Set<String> hubNodeIds = const {},
  }) async {
    debugPrint('ELKAlgorithm.computeLayout: not supported on this platform.');
    return Size.zero;
  }

  @override
  void init(Graph? graph) {}

  @override
  Size run(Graph? graph, double shiftX, double shiftY) => Size.zero;

  @override
  void setDimensions(double width, double height) {}
}
