library graphview;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'ArrowEdgeRenderer.dart';
import 'EdgeRenderer.dart';
import 'Graph.dart';
import 'Layout.dart';

typedef PressCallback = Function(Node node, Widget item);

class GraphView extends MultiChildRenderObjectWidget {
  Graph graph;
  Layout algorithm;
  EdgeRenderer renderer;

  GraphView({Key key, @required this.graph, @required this.algorithm, EdgeRenderer renderer})
      : assert(graph != null),
        assert(algorithm != null),
        renderer = renderer ?? ArrowEdgeRenderer(),
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
    return RenderCustomLayoutBox(graph, algorithm, renderer);
  }

  @override
  void updateRenderObject(BuildContext context, RenderCustomLayoutBox renderObject) {
    renderObject
      ..graph = graph
      ..algorithm = algorithm
      ..renderer = renderer;
  }
}

class RenderCustomLayoutBox extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, NodeBoxData>, RenderBoxContainerDefaultsMixin<RenderBox, NodeBoxData> {
  Graph _graph;
  Layout _algorithm;
  EdgeRenderer _renderer;

  EdgeRenderer get renderer => _renderer;

  set renderer(EdgeRenderer value) {
    _renderer = value;
    markNeedsLayout();
  }

  RenderCustomLayoutBox(
    Graph graph,
   Layout algorithm,
   EdgeRenderer renderer, {
    List<RenderBox> children,
  }) {
    _algorithm = algorithm;
    _graph = graph;
    _renderer = renderer;
    addAll(children);
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

    RenderBox child = firstChild;
    int position = 0;
    while (child != null) {
      final NodeBoxData node = child.parentData as NodeBoxData;

      child.layout(BoxConstraints.loose(constraints.biggest), parentUsesSize: true);
      graph.getNodeAtPosition(position).size = child.size;

      child = node.nextSibling;
      position++;
    }

    size = algorithm.run(graph, 10, 10);

    child = firstChild;
    position = 0;
    while (child != null) {
      final NodeBoxData node = child.parentData as NodeBoxData;

      node.offset = graph.getNodeAtPosition(position).position;

      child = node.nextSibling;
      position++;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);

    _renderer.render(context.canvas, graph, paint);

    context.canvas.restore();

    defaultPaint(context, offset);
  }
}

class NodeBoxData extends ContainerBoxParentData<RenderBox> {}
