library graphview;

import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
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

class GraphView extends StatefulWidget {
  final Graph graph;
  final Layout algorithm;
  final Paint paint;

  GraphView({Key key, @required this.graph, @required this.algorithm, this.paint})
      : assert(graph != null),
        assert(algorithm != null),
        super(key: key);

  @override
  _GraphViewState createState() => _GraphViewState();
}

class GraphTween extends Tween<List<Offset>> {
  /// Creates a [Size] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as an empty size.
  GraphTween({List<Offset> begin, List<Offset> end}) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  List<Offset> lerp(double t) {
    var k = begin?.length ?? 0;
    var list = List.generate(k, (index) => Offset(0, 0));

    for(var i = 0; i<k ;i++){
      list[i] = Offset.lerp(begin[i], end[i], t);
    }

    //   if (b == null) {
    //     if (a == null) {
    //       return null;
    //     } else {
    //
    //       a.nodes.forEach((n) {
    //         n.position = Offset.lerp(n.position, null, t);
    //       });
    //       return a;
    //     }
    //   } else {
    //     if (a == null) {
    //       b.nodes.forEach((n) {
    //         n.position = Offset.lerp(null, n.position, t);
    //       });
    //       return b;
    //     } else {
    //
    //       return a;
    //     }
    //   }
    // }
    return list;
  }

  @override
  List<Offset> transform(double t) {
    if (t == 0.0) return begin;
    if (t == 1.0) return end;
    return lerp(t);
  }
}

class _GraphViewState extends State<GraphView> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return _GraphView(
      graph: widget.graph,
      algorithm: widget.algorithm,
      paint: widget.paint,
      vsync: this,
    );
  }
}

class _GraphView extends MultiChildRenderObjectWidget {
  final Graph graph;
  final Layout algorithm;
  final Paint paint;

  /// The [TickerProvider] for this widget.
  final TickerProvider vsync;

  _GraphView({Key key, @required this.graph, @required this.algorithm, this.paint, this.vsync})
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
    return RenderCustomLayoutBox(graph, algorithm, paint, vsync);
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
  double _lastValue;
  Layout _algorithm;
  Paint _paint;
  AnimationController _controller;
  final GraphTween _graphTween = GraphTween();
  RenderAnimatedSizeState _state = RenderAnimatedSizeState.start;

  RenderCustomLayoutBox(
    Graph graph,
    Layout algorithm,
    Paint paint,
    TickerProvider vsync, {
    List<RenderBox> children,
  }) {
    _algorithm = algorithm;
    _graph = graph;
    edgePaint = paint;
    addAll(children);

    _controller = AnimationController(duration: Duration(milliseconds: 500), vsync: vsync)
      ..addListener(() {
        if (_controller.value != _lastValue) {
          markNeedsLayout();
        }
      });
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

  // Graph get graph => _graph;

  set graph(Graph value) {
    _graph = value;
    markNeedsLayout();
  }

  Layout get algorithm => _algorithm;

  set algorithm(Layout value) {
    _algorithm = value;
    _lastValue = 0.0;
    _controller.stop();
    _restartAnimation();
    _state = RenderAnimatedSizeState.start;

    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeBoxData) {
      child.parentData = NodeBoxData();
    }
  }

  @override
  void detach() {
    _controller.stop();
    super.detach();
  }

  Size sizea;

  @override
  void performLayout() {
    _lastValue = _controller.value;
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
      _graph.getNodeAtPosition(position).size = child.size;

      child = node.nextSibling;
      position++;
    }

    // size = algorithm.run(graph, 10, 10);
    if(sizea!=null) {
      size = sizea;
    }
    assert(_state != null);
    switch (_state) {
      case RenderAnimatedSizeState.start:
        sizea = algorithm.run(_graph, 10, 10);
        size = sizea;
        _layoutStart();
        break;
      case RenderAnimatedSizeState.stable:
        _layoutStable();
        break;
      case RenderAnimatedSizeState.changed:
        _layoutChanged();
        break;
      case RenderAnimatedSizeState.unstable:
        _layoutUnstable();
        break;
    }

    var trans = _graphTween.transform(_lastValue) ?? _graph.getOffsets();

    child = firstChild;
    position = 0;
    while (child != null) {
      final node = child.parentData as NodeBoxData;

      node.offset = trans[position];

      child = node.nextSibling;
      position++;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);

    var graph1 = Graph();;

    var trans = _graphTween.transform(_lastValue) ?? _graph.getOffsets();

    _graph.edges.forEach((element) {
      graph1.addEdge(Node.clone(element.source), Node.clone(element.destination), paint: element.paint);
    });

    graph1.nodes.asMap().forEach((key, value) {
     // value.position = trans[key];
   });

    algorithm.renderer.render(context.canvas, graph1, edgePaint);

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
    properties.add(DiagnosticsProperty<Graph>('graph', _graph));
    properties.add(DiagnosticsProperty<Layout>('algorithm', algorithm));
    properties.add(DiagnosticsProperty<Paint>('paint', edgePaint));
  }

  /// Laying out the child for the first time.
  ///
  /// We have the initial size to animate from, but we do not have the target
  /// size to animate to, so we set both ends to child's size.
  void _layoutStart() {
    _graphTween.begin = _graphTween.transform(_lastValue) ?? _graph.getOffsets();
    _graphTween.end = _graph.getOffsets();

    _state = RenderAnimatedSizeState.stable;
  }

  /// At this state we're assuming the child size is stable and letting the
  /// animation run its course.
  ///
  /// If during animation the size of the child changes we restart the
  /// animation.
  void _layoutStable() {
    if (!equal(_graphTween.end, _graph.getOffsets())) {
      _graphTween.begin = _graphTween.transform(_lastValue);
      _graphTween.end = _graph.getOffsets();

      _restartAnimation();
      _state = RenderAnimatedSizeState.changed;
    } else if (_controller.value == _controller.upperBound) {
      // Animation finished. Reset target sizes.
      _graphTween.begin = _graphTween.end = _graph.getOffsets();
    } else if (!_controller.isAnimating) {
      _controller.forward(); // resume the animation after being detached
    }
  }

  /// This state indicates that the size of the child changed once after being
  /// considered stable.
  ///
  /// If the child stabilizes immediately, we go back to stable state. If it
  /// changes again, we match the child's size, restart animation and go to
  /// unstable state.
  void _layoutChanged() {
    if (!equal(_graphTween.end, _graph.getOffsets())) {
      // Child size changed again. Match the child's size and restart animation.
      _graphTween.begin = _graphTween.end = _graph.getOffsets();
      _restartAnimation();
      _state = RenderAnimatedSizeState.unstable;
    } else {
      // Child size stabilized.
      _state = RenderAnimatedSizeState.stable;
      if (!_controller.isAnimating) _controller.forward(); // resume the animation after being detached
    }
  }

  /// The child's size is not stable.
  ///
  /// Continue tracking the child's size until is stabilizes.
  void _layoutUnstable() {
    if (!equal(_graphTween.end, _graph.getOffsets())) {
      // Still unstable. Continue tracking the child.
      _graphTween.begin = _graphTween.end = _graph.getOffsets();
      _restartAnimation();
    } else {
      // Child size stabilized.
      _controller.stop();
      _state = RenderAnimatedSizeState.stable;
    }
  }

  bool equal(List<Offset> a, List<Offset> b) {
    if (a == null) return false;

    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }

  void _restartAnimation() {
    _lastValue = 0.0;
    _controller.forward(from: 0.0);
  }
}

class NodeBoxData extends ContainerBoxParentData<RenderBox> {}

enum RenderAnimatedSizeState {
  /// The initial state, when we do not yet know what the starting and target
  /// sizes are to animate.
  ///
  /// The next state is [stable].
  start,

  /// At this state the child's size is assumed to be stable and we are either
  /// animating, or waiting for the child's size to change.
  ///
  /// If the child's size changes, the state will become [changed]. Otherwise,
  /// it remains [stable].
  stable,

  /// At this state we know that the child has changed once after being assumed
  /// [stable].
  ///
  /// The next state will be one of:
  ///
  /// * [stable] if the child's size stabilized immediately. This is a signal
  ///   for the render object to begin animating the size towards the child's new
  ///   size.
  ///
  /// * [unstable] if the child's size continues to change.
  changed,

  /// At this state the child's size is assumed to be unstable (changing each
  /// frame).
  ///
  /// Instead of chasing the child's size in this state, the render object
  /// tightly tracks the child's size until it stabilizes.
  ///
  /// The render object remains in this state until a frame where the child's
  /// size remains the same as the previous frame. At that time, the next state
  /// is [stable].
  unstable,
}