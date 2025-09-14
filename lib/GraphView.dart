library graphview;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

part 'Algorithm.dart';
part 'Graph.dart';
part 'edgerenderer/ArrowEdgeRenderer.dart';
part 'edgerenderer/EdgeRenderer.dart';
part 'familytree/FamilyTreeAlgorithm.dart';
part 'familytree/FamilyTreeBuchheimWalkerConfiguration.dart';
part 'familytree/FamilyTreeEdgeRenderer.dart';
part 'forcedirected/FruchtermanReingoldAlgorithm.dart';
part 'forcedirected/FruchtermanReingoldConfiguration.dart';
part 'layered/EiglspergerAlgorithm.dart';
part 'layered/SugiyamaAlgorithm.dart';
part 'layered/SugiyamaConfiguration.dart';
part 'layered/SugiyamaEdgeData.dart';
part 'layered/SugiyamaEdgeRenderer.dart';
part 'layered/SugiyamaNodeData.dart';
part 'mindmap/MindMapAlgorithm.dart';
part 'mindmap/MindmapEdgeRenderer.dart';
part 'tree/BaloonLayoutAlgorithm.dart';
part 'tree/BuchheimWalkerAlgorithm.dart';
part 'tree/BuchheimWalkerConfiguration.dart';
part 'tree/BuchheimWalkerNodeData.dart';
part 'tree/CircleLayoutAlgorithm.dart';
part 'tree/RadialTreeLayoutAlgorithm.dart';
part 'tree/TidierTreeLayoutAlgorithm.dart';
part 'tree/TreeEdgeRenderer.dart';
part 'tree/TreeLayoutAlgorithm.dart';

typedef NodeWidgetBuilder = Widget Function(Node node);
typedef EdgeWidgetBuilder = Widget Function(Edge edge);

class GraphViewController {
  dynamic _state;
  final TransformationController? transformationController;

  GraphViewController({this.transformationController});

  void _attach(dynamic state) => _state = state;

  void _detach() => _state = null;

  void animateToNode(ValueKey key) => _state?.jumpToNode(key, true);

  void jumpToNode(ValueKey key) => _state?.jumpToNode(key, false);

  void animateToMatrix(Matrix4 target) => _state?.animateToMatrix(target);

  void resetView() => _state?.resetView();

  void zoomToFit() => _state?.zoomToFit();

  void forceRecalculation() => _state?.forceRecalculation();

  final Map<ValueKey, bool> _expandedNodes = <ValueKey, bool>{};

  bool isNodeExpanded(ValueKey key) => _expandedNodes[key] ?? true;

  void expandNode(ValueKey key) {
    _expandedNodes[key] = true;
    forceRecalculation();
  }

  void collapseNode(ValueKey key) {
    _expandedNodes[key] = false;
    forceRecalculation();
  }

  void toggleNodeExpanded(ValueKey key) {
    if (isNodeExpanded(key)) {
      collapseNode(key);
    } else {
      expandNode(key);
    }
  }
}

class GraphView extends StatefulWidget {
  final Graph graph;
  final Algorithm algorithm;
  final Paint? paint;
  final NodeWidgetBuilder builder;
  final bool animated;
  final GraphViewController? controller;
  final bool _isBuilder;

  Duration? animationDuration;
  ValueKey? initialNode;
  bool autoZoomToFit = false;

  GraphView({
    Key? key,
    required this.graph,
    required this.algorithm,
    this.paint,
    required this.builder,
    this.animated = true,
  })  : controller = null,
        _isBuilder = false,
        super(key: key);

  GraphView.builder({
    Key? key,
    required this.graph,
    required this.algorithm,
    this.paint,
    required this.builder,
    this.controller,
    this.animated = true,
    this.initialNode,
    this.autoZoomToFit = false,
    this.animationDuration,
  })  : _isBuilder = true,
        assert(!(autoZoomToFit && initialNode != null),
        'Cannot use both autoZoomToFit and initialNode together. Choose one.'),
        super(key: key);

  @override
  _GraphViewState createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> with TickerProviderStateMixin {
  late TransformationController _transformationController;
  late final AnimationController _cameraController;
  late final AnimationController _nodeController;
  Animation<Matrix4>? _cameraAnimation;

  _GraphViewState() {
    _transformationController = TransformationController();
  }

  @override
  void initState() {
    super.initState();

    if (widget.controller?.transformationController != null) {
      _transformationController.dispose();
      _transformationController = widget.controller!.transformationController!;
    }

    _cameraController = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? const Duration(milliseconds: 600),
    );

    _nodeController = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? const Duration(milliseconds: 600),
    );

    widget.controller?._attach(this);

    if (widget.autoZoomToFit || widget.initialNode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.autoZoomToFit) {
          zoomToFit();
        } else if (widget.initialNode != null) {
          jumpToNode(widget.initialNode!, false);
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _cameraController.dispose();
    _nodeController.dispose();
    if (widget.controller?.transformationController == null) {
      _transformationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = _GraphView(
        graph: widget.graph,
        algorithm: widget.algorithm,
        paint: widget.paint,
        nodeAnimationController: _nodeController,
        builder: widget.builder,
        controller: widget.controller);

    if (widget._isBuilder) {
      return InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        boundaryMargin: EdgeInsets.all(double.infinity),
        minScale: 0.01,
        maxScale: 5.6,
        child: view,
      );
    }

    return view;
  }

  void jumpToNode(ValueKey key, bool animated) {
    final node = widget.graph.nodes.firstWhereOrNull((n) => n.key == key);
    if (node == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewport = renderBox.size;
    final center = Offset(viewport.width / 2, viewport.height / 2);
    final nodeCenter = Offset(
        node.position.dx + node.width / 2, node.position.dy + node.height / 2);

    final target = Matrix4.identity()
      ..translate(center.dx - nodeCenter.dx, center.dy - nodeCenter.dy);

    if (animated) {
      animateToMatrix(target);
    } else {
      _transformationController.value = target;
    }
  }

  void resetView() => animateToMatrix(Matrix4.identity());

  void zoomToFit() {
    if (widget.graph.nodes.isEmpty) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final vp = renderBox.size;
    final bounds = widget.graph.calculateGraphBounds();
    final scale = (vp.shortestSide * 0.8 / bounds.longestSide).clamp(0.01, 5.6);
    final centerOffset = Offset(vp.width / 2 - bounds.center.dx * scale,
        vp.height / 2 - bounds.center.dy * scale);

    final target = Matrix4.identity()
      ..translate(centerOffset.dx, centerOffset.dy)
      ..scale(scale);
    animateToMatrix(target);
  }

  void animateToMatrix(Matrix4 target) {
    _cameraController.reset();
    _cameraAnimation =
        Matrix4Tween(begin: _transformationController.value, end: target)
            .animate(CurvedAnimation(
            parent: _cameraController, curve: Curves.easeInOut));
    _cameraAnimation!.addListener(_onCameraTick);
    _cameraController.forward();
  }

  void _onCameraTick() {
    if (_cameraAnimation == null) return;
    _transformationController.value = _cameraAnimation!.value;
    if (!_cameraController.isAnimating) {
      _cameraAnimation!.removeListener(_onCameraTick);
      _cameraAnimation = null;
      _cameraController.reset();
    }
  }

  void forceRecalculation() => setState(() {});
}

class _GraphView extends MultiChildRenderObjectWidget {
  final Graph graph;
  final Algorithm algorithm;
  final Paint? paint;
  final AnimationController nodeAnimationController;
  GraphViewController? controller;

  _GraphView({
    Key? key,
    required this.graph,
    required this.algorithm,
    this.paint,
    required this.nodeAnimationController,
    required NodeWidgetBuilder builder,
    this.controller,
  }) : super(key: key, children: _extractChildren(graph, builder)) {
    assert(children.isNotEmpty, 'Children must not be empty');
  }

  static List<Widget> _extractChildren(
      Graph graph, NodeWidgetBuilder builder) =>
      graph.nodes.map((n) => n.data ?? builder(n)).toList(growable: false);

  @override
  RenderCustomLayoutBox createRenderObject(BuildContext context) =>
      RenderCustomLayoutBox(graph, algorithm, paint,
          nodeAnimationController: nodeAnimationController,
          controller: controller);

  @override
  void updateRenderObject(
      BuildContext context, RenderCustomLayoutBox renderObject) {
    renderObject
      ..graph = graph
      ..algorithm = algorithm
      ..edgePaint = paint
      ..nodeAnimationController = nodeAnimationController;
  }
}

class RenderCustomLayoutBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeBoxData> {
  late Graph _graph;
  late Algorithm _algorithm;
  late Paint _paint;
  late AnimationController _nodeAnimationController;

  Size? _cachedSize;
  bool _isInitialized = false;
  bool _needsFullRecalculation = false;
  bool _needsLayout = false;
  late GraphViewController? _controller;

  RenderCustomLayoutBox(Graph graph, Algorithm algorithm, Paint? paint,
      {List<RenderBox>? children,
        required AnimationController nodeAnimationController,
        required GraphViewController? controller}) {
    _algorithm = algorithm;
    _graph = graph;
    _nodeAnimationController = nodeAnimationController;
    edgePaint = paint;
    _controller = controller;
    addAll(children);
  }

  Graph get graph => _graph;

  set graph(Graph value) {
    // if (identical(_graph, value)) return;

    _needsFullRecalculation = true;
    _isInitialized = false;
    _graph = value;
    markNeedsLayout();
  }

  Algorithm get algorithm => _algorithm;

  set algorithm(Algorithm value) {
    _needsFullRecalculation = true;
    _isInitialized = false;
    _algorithm = value;
    markNeedsLayout();
  }

  Graph _createVisibleGraph() {
    if (_cachedVisibleGraph != null && !_needsFullRecalculation) {
      return _cachedVisibleGraph!;
    }

    final visibleGraph = Graph();

    for (final edge in graph.edges) {
      if (_isNodeVisible(edge.source) && _isNodeVisible(edge.destination)) {
        visibleGraph.addEdgeS(edge);
      }
    }

    if (visibleGraph.nodes.isEmpty) {
      visibleGraph.addNode(graph.nodes.first);
    }

    _cachedVisibleGraph = visibleGraph;
    return visibleGraph;
  }

  bool _isNodeVisible(Node node) {
    // Walk up the ancestor chain
    Node? current = node;
    while (current != null) {
      final parent = graph.predecessorsOf(current).firstOrNull;

      if (parent != null) {
        if (parent.collapse) {
          // if (!_controller!.isNodeExpanded(parent.key as ValueKey)) {
          return false;
        }
      }
      current = parent;
    }
    return true;
  }

  Graph? _cachedVisibleGraph;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _nodeAnimationController.addListener(_onAnimationTick);
  }

  @override
  void detach() {
    _nodeAnimationController.removeListener(_onAnimationTick);
    super.detach();
  }

  void forceRecalculation() {
    _needsFullRecalculation = true;
    _isInitialized = false;
    markNeedsLayout();
  }

  Paint get edgePaint => _paint;

  set edgePaint(Paint? value) {
    final newPaint = value ??
        (Paint()
          ..color = Colors.black
          ..strokeWidth = 3)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt;

    _paint = newPaint;
    markNeedsPaint();
  }

  AnimationController get nodeAnimationController => _nodeAnimationController;

  set nodeAnimationController(AnimationController value) {
    if (identical(_nodeAnimationController, value)) return;
    _nodeAnimationController.removeListener(_onAnimationTick);
    _nodeAnimationController = value;
    _nodeAnimationController.addListener(_onAnimationTick);
    markNeedsLayout();
  }

  void _onAnimationTick() {
    markNeedsPaint();
  }

  final animatedPositions = <Node, Offset>{};

  // computeDryLayout to provide a size for nodes not shown

  var enableAnimation = true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final t = _nodeAnimationController.value;
    animatedPositions.clear();

    var child = firstChild;
    var i = 0;
    while (child != null) {
      final node = child.parentData as NodeBoxData;
      final pos = Offset.lerp(node.startOffset, node.targetOffset, t)!;
      animatedPositions[graph.getNodeAtPosition(i)] = pos;
      child = node.nextSibling;
      i++;
    }

    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);
    algorithm.renderer?.setAnimatedPositions(animatedPositions);
    algorithm.renderer?.render(context.canvas, graph, edgePaint);
    context.canvas.restore();

    child = firstChild;
    i = 0;
    while (child != null) {
      final node = child.parentData as NodeBoxData;
      final graphNode = graph.getNodeAtPosition(i);
      final pos = animatedPositions[graphNode]!;

      final isVisible = _isNodeVisible(graphNode);
      if (isVisible) {
        context.paintChild(child, offset + pos);
      } else {
        // Collapsing nodes: paint while animation is running, fade out & move toward parent
        if (_nodeAnimationController.isAnimating &&
            node.startOffset != node.targetOffset) {
          // context.paintChild(child, offset + pos);
          final progress = 1.0 - _nodeAnimationController.value; // 1 → 0
          final shrink = progress.clamp(0.0, 1.0);

          final center = pos +
              offset +
              Offset(child.size.width * 0.5, child.size.height * 0.5);

          context.canvas.save();
          // move pivot to center
          context.canvas.translate(center.dx, center.dy);
          context.canvas.scale(shrink, shrink);
          context.canvas.translate(-center.dx, -center.dy);

          context.paintChild(
              child, offset + pos); // paint normally (size is scaled)
          context.canvas.restore();
        } else if (_nodeAnimationController.isCompleted) {
          node.startOffset = node.targetOffset;
        }
        debugPrint(
            "Collapsing node ${graphNode.key} at $pos ${graphNode.position} old:${node.startOffset} new:${node.targetOffset} ${_nodeAnimationController}");
      }

      if (_nodeAnimationController.isCompleted) {
        node.offset = graphNode.position;
      }
      child = node.nextSibling;
      i++;
    }
  }

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.biggest;
      return;
    }

    final looseConstraints = BoxConstraints.loose(constraints.biggest);
    var child = firstChild;
    var position = 0;

    if (_needsFullRecalculation || !_isInitialized) {
      while (child != null) {
        final nodeData = child.parentData as NodeBoxData;
        final graphNode = graph.getNodeAtPosition(position);

        child.layout(looseConstraints, parentUsesSize: true);
        graphNode.size = child.size;
        child = nodeData.nextSibling;
        position++;
      }

      final visibleGraph = _createVisibleGraph();
      final layoutSize = _algorithm.run(visibleGraph, 0, 0);

      // copy positions back to main graph
      var visibleIndex = 0;
      for (final originalNode in graph.nodes) {
        if (_isNodeVisible(originalNode)) {
          originalNode.position =
              visibleGraph.getNodeAtPosition(visibleIndex).position;
          visibleIndex++;
        }
      }

      _cachedSize = layoutSize;
      _isInitialized = true;
      _needsFullRecalculation = false;
    }

    size = _cachedSize ?? Size.zero;

    var needsAnimation = false;
    child = firstChild;
    position = 0;

    while (child != null) {
      final nodeData = child.parentData as NodeBoxData;
      final graphNode = graph.getNodeAtPosition(position);

      final prevNew = nodeData.targetOffset;
      final newPos = graphNode.position;
      var isVisible = _isNodeVisible(graphNode);

      if (isVisible) {
        // nodeData.offset = newPos;

        if (enableAnimation) {
          if (prevNew == null) {
            final parent = graph.predecessorsOf(graphNode).firstOrNull;
            nodeData.startOffset = parent?.position ?? newPos;
            nodeData.targetOffset = newPos;
            needsAnimation = true;
          } else if ((prevNew - newPos).distance >= 1.0) {
            nodeData.startOffset = prevNew;
            nodeData.targetOffset = newPos;
            needsAnimation = true;
          } else {
            nodeData.startOffset = newPos;
            nodeData.targetOffset = newPos;
          }
        }
        // debugPrint("PerformLayout: Visible node ${graphNode.key} at $newPos, currentPostion ${graphNode.position} old: ${nodeData.oldOffset} new: ${nodeData.newOffset}");
      } else {
        if (enableAnimation) {
          // collapsing nodes animate toward parent
          final parent = _findClosestVisibleAncestor(graphNode);
          final parentPos = parent!.position;
          debugPrint(
              "PerformLayout: Collapsing node ${graphNode.key} from ${nodeData.startOffset} ${nodeData.targetOffset} toward parent at $parentPos, currentPostion ${graphNode.position}");
          if (nodeData.startOffset == nodeData.targetOffset) {
            nodeData.targetOffset = parentPos;
          } else if (prevNew != null && prevNew != parentPos) {
            // Just collapsed now → animate toward parent
            nodeData.startOffset = graphNode.position;
            nodeData.targetOffset = parentPos;
            needsAnimation = true;
          } else {
            // animation finished → lock to parent
            nodeData.startOffset = parentPos;
            nodeData.targetOffset = parentPos;
          }
        }
      }

      child = nodeData.nextSibling;
      position++;
    }

    if (enableAnimation &&
        needsAnimation &&
        _algorithm is! FruchtermanReingoldAlgorithm) {
      _nodeAnimationController.reset();
      _nodeAnimationController.forward();
      _nodeAnimationController.addListener(_onAnimationTick);
    }
  }

  Node? _findClosestVisibleAncestor(Node node) {
    final predecessors = graph.predecessorsOf(node);
    var current = predecessors.isNotEmpty ? predecessors.first : null;

    // Walk up until we find a visible ancestor
    while (current != null) {
      if (_isNodeVisible(current)) {
        return current; // Return the first (closest) visible ancestor
      }

      current = graph.predecessorsOf(current).firstOrNull;
    }

    return null;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Only allow hit testing on visible nodes
    var child = firstChild;
    var i = 0;

    while (child != null) {
      final nodeData = child.parentData as NodeBoxData;
      final graphNode = graph.getNodeAtPosition(i);

      if (_isNodeVisible(graphNode)) {
        final childParentData = child.parentData as BoxParentData;

        final isHit = result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            return child!.hitTest(result, position: transformed);
          },
        );
        if (isHit) return true;
      }

      child = nodeData.nextSibling;
      i++;
    }

    return false;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeBoxData) {
      child.parentData = NodeBoxData();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Graph>('graph', graph));
    properties.add(DiagnosticsProperty<Algorithm>('algorithm', algorithm));
    properties.add(DiagnosticsProperty<Paint>('paint', edgePaint));
  }
}

class NodeBoxData extends ContainerBoxParentData<RenderBox> {
  Offset? startOffset;
  Offset? targetOffset;
}

class _GraphViewAnimated extends StatefulWidget {
  final Graph graph;
  final Algorithm algorithm;
  final Paint? paint;
  final NodeWidgetBuilder builder;
  final stepMilis = 25;

  _GraphViewAnimated(
      {Key? key, required this.graph, required this.algorithm, this.paint, required this.builder}) {
  }

  @override
  _GraphViewAnimatedState createState() => _GraphViewAnimatedState();
}

class _GraphViewAnimatedState extends State<_GraphViewAnimated> {
  late Timer timer;
  late Graph graph;
  late Algorithm algorithm;

  @override
  void initState() {
    graph = widget.graph;

    algorithm = widget.algorithm;
    algorithm.init(graph);
    startTimer();

    super.initState();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(milliseconds: widget.stepMilis), (timer) {
      algorithm.step(graph);
      update();
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    algorithm.setDimensions(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: MediaQuery.of(context).size,
          painter: EdgeRender(algorithm, graph, Offset(20, 20)),
        ),
        ...List<Widget>.generate(graph.nodeCount(), (index) {
          return Positioned(
            child: GestureDetector(
              child: graph.nodes[index].data ?? widget.builder(graph.nodes[index]),
              onPanUpdate: (details) {
                graph.getNodeAtPosition(index).position += details.delta;
                update();
              },
            ),
            top: graph.getNodeAtPosition(index).position.dy,
            left: graph.getNodeAtPosition(index).position.dx,
          );
        }),
      ],
    );
  }

  Future<void> update() async {
    setState(() {});
  }
}

class EdgeRender extends CustomPainter {
  Algorithm algorithm;
  Graph graph;
  Offset offset;

  EdgeRender(this.algorithm, this.graph, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    var edgePaint = (Paint()
      ..color = Colors.black
      ..strokeWidth = 3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    algorithm.renderer!.render(canvas, graph, edgePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
