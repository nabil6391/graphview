library graphview;

import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

part 'Graph.dart';
part 'Layout.dart';
part 'edgerenderer/ArrowEdgeRenderer.dart';
part 'edgerenderer/EdgeRenderer.dart';
part 'forcedirected/FruchtermanReingoldAlgorithm.dart';
part 'layered/SugiyamaAlgorithm.dart';
part 'layered/SugiyamaConfiguration.dart';
part 'layered/SugiyamaEdgeData.dart';
part 'layered/SugiyamaEdgeRenderer.dart';
part 'layered/SugiyamaNodeData.dart';
part 'tree/BuchheimWalkerAlgorithm.dart';
part 'tree/BuchheimWalkerConfiguration.dart';
part 'tree/BuchheimWalkerNodeData.dart';
part 'tree/TreeEdgeRenderer.dart';

class GraphView extends MultiChildRenderObjectWidget {
  final Graph graph;
  final Layout algorithm;
  final Paint paint;

  GraphView({Key key, @required this.graph, @required this.algorithm, this.paint})
      : assert(graph != null),
        assert(algorithm != null),
        super(key: key, children: _extractChildren(graph));

  // Traverses the InlineSpan tree and depth-first collects the list of
  // child widgets that are created in WidgetSpans.
  static List<Widget> _extractChildren(Graph graph) {
    final result = <Widget>[];

    graph.nodes.forEach((element) {
      result.add(element.data);
    });
    return result;
  }

  @override
  RenderCustomLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomLayoutBox(graph, algorithm, paint);
  }

  @override
  void updateRenderObject(BuildContext context, RenderCustomLayoutBox renderObject) {
    renderObject
      ..graph = graph
      ..algorithm = algorithm
      ..edgePaint = paint;
  }
}

class RenderCustomLayoutBox extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, NodeBoxData>, RenderBoxContainerDefaultsMixin<RenderBox, NodeBoxData> {
  Graph _graph;
  Layout _algorithm;
  Paint _paint;

  RenderCustomLayoutBox(
    Graph graph,
    Layout algorithm,
    Paint paint, {
    List<RenderBox> children,
  }) {
    _algorithm = algorithm;
    _graph = graph;
    edgePaint = paint;
    addAll(children);
  }

  Paint get edgePaint => _paint;

  set edgePaint(Paint value) {
    _paint = value ??
        (Paint()
          ..color = Colors.black
          ..strokeWidth = 3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    markNeedsPaint();
  }

  Graph get graph => _graph;

  set graph(Graph value) {
    _graph = value;
    markNeedsLayout();
  }

  Layout get algorithm => _algorithm;

  set algorithm(Layout value) {
    _algorithm = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeBoxData) {
      child.parentData = NodeBoxData();
    }
  }

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.biggest;
      assert(size.isFinite);
      return;
    }

    var child = firstChild;
    var position = 0;
    while (child != null) {
      final node = child.parentData as NodeBoxData;

      child.layout(BoxConstraints.loose(constraints.biggest), parentUsesSize: true);
      graph.getNodeAtPosition(position).size = child.size;

      child = node.nextSibling;
      position++;
    }

    size = algorithm.run(graph, 10, 10);

    child = firstChild;
    position = 0;
    while (child != null) {
      final node = child.parentData as NodeBoxData;

      node.offset = graph.getNodeAtPosition(position).position;

      child = node.nextSibling;
      position++;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);

    algorithm.renderer.render(context.canvas, graph, edgePaint);

    context.canvas.restore();

    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Graph>('graph', graph));
    properties.add(DiagnosticsProperty<Layout>('algorithm', algorithm));
    properties.add(DiagnosticsProperty<Paint>('paint', edgePaint));
  }
}

class NodeBoxData extends ContainerBoxParentData<RenderBox> {}
