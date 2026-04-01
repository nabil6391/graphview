// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:graphview/algorithm.dart';
import 'package:graphview/edge_renderer/arrow_edge_renderer.dart';
import 'package:graphview/graph.dart';

typedef NodeWidgetBuilder = Widget Function(Node node);

class GraphViewController {
  _GraphViewState? _state;
  final TransformationController? transformationController;

  /// Callback triggered when an edge is tapped
  void Function(Edge edge)? onEdgeTap;

  /// Callback triggered when an anchor (connection dot) is tapped.
  /// The [targetNode] is the node on the OTHER side of the edge.
  void Function(Node targetNode)? onAnchorTap;

  /// Notifier tracking if the controller is attached to a GraphView widget
  final ValueNotifier<bool> isAttached = ValueNotifier(false);

  /// Notifier tracking if the graph layout has been computed and applied
  final ValueNotifier<bool> isLayoutFinished = ValueNotifier(false);

  /// Standard awaitable future for attachment
  Future<void> get attachedWait async {
    if (isAttached.value) return;
    await _waitFor(isAttached);
  }

  /// Standard awaitable future for layout completion
  Future<void> get offsetWait async {
    if (isLayoutFinished.value) return;
    await _waitFor(isLayoutFinished);
  }

  Future<void> _waitFor(ValueNotifier<bool> notifier) {
    final completer = Completer<void>();
    void listener() {
      if (notifier.value) {
        notifier.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      }
    }

    notifier.addListener(listener);
    return completer.future;
  }

  void notifyLayoutStarted() {
    isLayoutFinished.value = false;
  }

  void notifyLayoutFinished() {
    isLayoutFinished.value = true;
  }

  final Map<Node, bool> collapsedNodes = {};
  final Map<Node, bool> expandingNodes = {};
  final Set<String> _hiddenNodeIds = {};

  Node? collapsedNode;
  Node? focusedNode;

  GraphViewController({
    this.transformationController,
  });

  void _attach(_GraphViewState? state) {
    _state = state;
    isAttached.value = state != null;
  }

  void dispose() {
    isAttached.dispose();
    isLayoutFinished.dispose();
    transformationController?.dispose();
  }

  void reset() {
    collapsedNodes.clear();
    expandingNodes.clear();
    _hiddenNodeIds.clear();
    collapsedNode = null;
    focusedNode = null;
    notifyLayoutStarted();
  }

  void animateToNode(ValueKey key, {Offset centeringOffset = Offset.zero}) =>
      _state?.jumpToNodeUsingKey(key, true, centeringOffset: centeringOffset);

  void panAndZoomToNode(ValueKey key,
      {double scale = 1.5, Offset centeringOffset = Offset.zero}) {
    _state?.jumpToNodeWithScale(key, true, scale,
        centeringOffset: centeringOffset);
  }

  void panAndZoomToNodeId(String id,
      {double scale = 1.5, Offset centeringOffset = Offset.zero}) {
    final node = _state?.widget.graph.nodes.firstWhereOrNull(
      (n) => n.key?.value.toString() == id,
    );

    if (node != null && node.key is ValueKey) {
      _state?.jumpToNodeWithScale(node.key!, true, scale,
          centeringOffset: centeringOffset);
    } else {
      zoomToFit();
    }
  }

  void jumpToNode(ValueKey key) => _state?.jumpToNodeUsingKey(key, false);

  void animateToMatrix(Matrix4 target) => _state?.animateToMatrix(target);

  void resetView() => _state?.resetView();

  void zoomToFit() => _state?.zoomToFit();

  void adjustZoom(double factor) => _state?.adjustZoom(factor);

  void forceRecalculation() => _state?.forceRecalculation();

  // Visibility management methods
  bool isNodeCollapsed(dynamic nodeOrId) {
    if (nodeOrId is Node) {
      return collapsedNodes.containsKey(nodeOrId);
    }
    final nodeId = nodeOrId.toString();
    return collapsedNodes.keys.any((n) => n.key?.value.toString() == nodeId);
  }

  void setHiddenNodes(Set<String> nodeIds) {
    _hiddenNodeIds.clear();
    _hiddenNodeIds.addAll(nodeIds);
    _state?.update();
  }

  bool isNodeHidden(dynamic nodeOrId) {
    if (nodeOrId is Node) {
      return _hiddenNodeIds.contains(nodeOrId.key?.value.toString());
    }
    return _hiddenNodeIds.contains(nodeOrId.toString());
  }

  Set<String> getCollapsedNodeIds() =>
      collapsedNodes.keys.map((n) => n.key!.value.toString()).toSet();

  Set<String> getHiddenNodeIds() => _hiddenNodeIds.toSet();

  bool isNodeVisible(Graph graph, Node node) {
    return !isNodeHidden(node);
  }

  bool isNodeExpanding(Node node) => expandingNodes.containsKey(node);

  void toggleNodeExpanded(Graph graph, Node node, {bool animate = true}) {
    if (collapsedNodes.containsKey(node)) {
      collapsedNodes.remove(node);
      expandingNodes[node] = true;
      _state?.update();

      if (animate) {
        Timer(const Duration(milliseconds: 100), () {
          expandingNodes.remove(node);
          _state?.update();
        });
      }
    } else {
      collapsedNodes[node] = true;
      _state?.update();
    }
  }

  void setNodeFocused(Node? node) {
    focusedNode = node;
    _state?.update();
  }

  void handleTapAt(Offset localOffset) {
    final renderObject = _state?.renderObject;
    if (renderObject == null) return;

    // 1. Check for Anchor Tap
    final renderer = renderObject.algorithm.renderer;
    if (renderer is ArrowEdgeRenderer) {
      for (final entry in renderer.anchorLookup.entries) {
        final anchorPos = entry.key;
        final edge = entry.value.edge;
        final isSourceAnchor = entry.value.isSource;

        if ((localOffset - anchorPos).distance <= 15.0) {
          // Large hit area for dots
          final targetNode = isSourceAnchor ? edge.destination : edge.source;
          if (onAnchorTap != null) {
            onAnchorTap!(targetNode);
          }
          return;
        }
      }

      // 2. Check for Edge Tap (fallback)
      for (final entry in renderer.renderedPaths.entries) {
        if (entry.value.contains(localOffset)) {
          if (onEdgeTap != null) {
            onEdgeTap!(entry.key);
          }
          return;
        }
      }
    }
  }
}

class NodeBoxData extends ContainerBoxParentData<RenderBox> {
  Node? node;
}

class GraphNodeData extends ParentDataWidget<NodeBoxData> {
  const GraphNodeData({
    required this.node,
    required super.child,
    super.key,
  });

  final Node node;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData as NodeBoxData;
    if (parentData.node != node) {
      parentData.node = node;
      final targetParent = renderObject.parent;
      if (targetParent is RenderCustomLayoutBox) {
        targetParent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _GraphViewInternal;
}

class GraphView extends StatefulWidget {
  final Graph graph;
  final Algorithm algorithm;
  final Paint? paint;
  final NodeWidgetBuilder builder;
  final bool animated;
  final GraphViewController? controller;
  final bool trackpadScrollCausesScale;

  final Duration? panAnimationDuration;
  final Duration? toggleAnimationDuration;
  final ValueKey? initialNode;
  final bool autoZoomToFit;
  final bool centerGraph;
  final Listenable? edgeAnimation;

  const GraphView({
    super.key,
    required this.graph,
    required this.algorithm,
    required this.builder,
    this.paint,
    this.animated = true,
    this.controller,
    this.toggleAnimationDuration,
    this.centerGraph = false,
    this.initialNode,
    this.panAnimationDuration,
    this.autoZoomToFit = false,
    this.edgeAnimation,
    this.trackpadScrollCausesScale = false,
  });

  const GraphView.builder({
    super.key,
    required this.graph,
    required this.algorithm,
    required this.builder,
    this.paint,
    this.animated = true,
    this.controller,
    this.toggleAnimationDuration,
    this.centerGraph = false,
    this.initialNode,
    this.panAnimationDuration,
    this.autoZoomToFit = false,
    this.edgeAnimation,
    this.trackpadScrollCausesScale = true,
  });

  @override
  _GraphViewState createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> with TickerProviderStateMixin {
  Size _viewportSize = Size.zero;
  late AnimationController _animationController;
  Map<Node, Offset> animatedPositions = {};

  RenderCustomLayoutBox? get renderObject {
    RenderCustomLayoutBox? result;
    void visitor(Element element) {
      if (element.renderObject is RenderCustomLayoutBox) {
        result = element.renderObject as RenderCustomLayoutBox;
      } else {
        element.visitChildren(visitor);
      }
    }

    context.visitChildElements(visitor);
    return result;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration:
          widget.panAnimationDuration ?? const Duration(milliseconds: 300),
    );
    widget.controller?._attach(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialNode != null) {
        jumpToNodeUsingKey(widget.initialNode!, false);
      } else if (widget.autoZoomToFit) {
        zoomToFit();
      }
    });
  }

  @override
  void didUpdateWidget(GraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._attach(null);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._attach(null);
    _animationController.dispose();
    super.dispose();
  }

  void update() {
    if (mounted) {
      setState(() {});
    }
  }

  void forceRecalculation() {
    update();
  }

  void jumpToNodeUsingKey(ValueKey key, bool animated,
      {Offset centeringOffset = Offset.zero}) {
    // Determine current scale from the transformation controller
    final currentMatrix = widget.controller?.transformationController?.value;
    final currentScale = currentMatrix?.getMaxScaleOnAxis() ?? 1.0;

    jumpToNodeWithScale(key, animated, currentScale,
        centeringOffset: centeringOffset);
  }

  void jumpToNodeWithScale(ValueKey key, bool animated, double scale,
      {Offset centeringOffset = Offset.zero}) {
    final node = widget.graph.nodes.firstWhereOrNull((n) => n.key == key);
    if (node == null || _viewportSize == Size.zero) return;

    final nodeCenter = Offset(
      node.x + node.width / 2,
      node.y + node.height / 2,
    );

    final tx = ((_viewportSize.width + centeringOffset.dx) / 2) -
        (nodeCenter.dx * scale);
    final ty = ((_viewportSize.height + centeringOffset.dy) / 2) -
        (nodeCenter.dy * scale);

    final target = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);

    if (animated) {
      animateToMatrix(target);
    } else {
      final transform = widget.controller?.transformationController;
      if (transform != null) {
        transform.value = target;
      }
    }
  }

  void animateToMatrix(Matrix4 target) {
    if (widget.controller?.transformationController == null) return;

    final animation = Matrix4Tween(
      begin: widget.controller!.transformationController!.value,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    animation.addListener(() {
      widget.controller?.transformationController?.value = animation.value;
    });

    _animationController.forward(from: 0);
  }

  void resetView() => animateToMatrix(Matrix4.identity());

  void zoomToFit() {
    if (_viewportSize == Size.zero || widget.graph.nodes.isEmpty) return;

    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    final hiddenNodes = widget.controller?.getHiddenNodeIds() ?? <String>{};

    for (final node in widget.graph.nodes) {
      if (hiddenNodes.contains(node.key?.value.toString() ?? '')) continue;
      
      minX = min(minX, node.x);
      minY = min(minY, node.y);
      maxX = max(maxX, node.x + node.width);
      maxY = max(maxY, node.y + node.height);
    }

    final graphWidth = maxX - minX;
    final graphHeight = maxY - minY;

    if (graphWidth <= 0 || graphHeight <= 0) return;

    const padding = 40.0;
    final scaleX = (_viewportSize.width - padding * 2) / graphWidth;
    final scaleY = (_viewportSize.height - padding * 2) / graphHeight;
    final scale = min(scaleX, scaleY).clamp(0.01, 2.0);

    final tx = (_viewportSize.width - graphWidth * scale) / 2 - minX * scale;
    final ty = (_viewportSize.height - graphHeight * scale) / 2 - minY * scale;

    final target = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);

    animateToMatrix(target);
  }

  void adjustZoom(double factor) {
    if (widget.controller?.transformationController == null) return;
    final currentScale =
        widget.controller!.transformationController!.value.getMaxScaleOnAxis();
    final newScale = currentScale + factor;
    if (newScale <= 0) return;

    widget.controller!.transformationController!.value =
        widget.controller!.transformationController!.value.clone()
          ..scale(newScale / currentScale);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        return InteractiveViewer(
          transformationController: widget.controller?.transformationController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: false,
          trackpadScrollCausesScale: widget.trackpadScrollCausesScale,
          minScale: 0.001,
          maxScale: 10.0,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) {
              widget.controller?.handleTapAt(details.localPosition);
            },
            child: ListenableBuilder(
              listenable: Listenable.merge([
                if (widget.edgeAnimation != null) widget.edgeAnimation!,
              ]),
              builder: (context, child) {
                return _GraphViewInternal(
                  graph: widget.graph,
                  algorithm: widget.algorithm,
                  paint: widget.paint ??
                      (Paint()
                        ..color = Colors.black
                        ..strokeWidth = 1.0
                        ..style = PaintingStyle.stroke),
                  builder: widget.builder,
                  controller: widget.controller,
                  centerGraph: widget.centerGraph,
                  animatedPositions: animatedPositions,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _GraphViewInternal extends MultiChildRenderObjectWidget {
  _GraphViewInternal({
    required this.graph,
    required this.algorithm,
    required this.paint,
    required this.builder,
    this.controller,
    this.centerGraph = false,
    required this.animatedPositions,
  }) : super(
          children: graph.nodes.map((node) {
            final isHidden = controller?.isNodeHidden(node) ?? false;
            return GraphNodeData(
              key: node.key,
              node: node,
              child: Visibility(
                visible: !isHidden,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: builder(node),
              ),
            );
          }).toList(),
        );

  final Graph graph;
  final Algorithm algorithm;
  final Paint paint;
  final NodeWidgetBuilder builder;
  final GraphViewController? controller;
  final bool centerGraph;
  final Map<Node, Offset> animatedPositions;

  @override
  RenderCustomLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomLayoutBox(
      graph: graph,
      algorithm: algorithm,
      edgePaint: paint,
      controller: controller,
      centerGraph: centerGraph,
      animatedPositions: animatedPositions,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderCustomLayoutBox renderObject) {
    renderObject
      ..graph = graph
      ..algorithm = algorithm
      ..edgePaint = paint
      ..controller = controller
      ..centerGraph = centerGraph
      ..animatedPositions = animatedPositions;
  }
}

class RenderCustomLayoutBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeBoxData> {
  RenderCustomLayoutBox({
    required Graph graph,
    required Algorithm algorithm,
    required Paint edgePaint,
    GraphViewController? controller,
    bool centerGraph = false,
    required this.animatedPositions,
  })  : _graph = graph,
        _algorithm = algorithm,
        _edgePaint = edgePaint,
        _controller = controller,
        _centerGraph = centerGraph;

  Graph _graph;
  Graph get graph => _graph;
  set graph(Graph value) {
    if (_graph == value) return;
    _graph = value;
    markNeedsLayout();
  }

  Algorithm _algorithm;
  Algorithm get algorithm => _algorithm;
  set algorithm(Algorithm value) {
    if (_algorithm == value) return;
    _algorithm = value;
    markNeedsLayout();
  }

  Paint _edgePaint;
  Paint get edgePaint => _edgePaint;
  set edgePaint(Paint value) {
    if (_edgePaint == value) return;
    _edgePaint = value;
    markNeedsPaint();
  }

  GraphViewController? _controller;
  GraphViewController? get controller => _controller;
  set controller(GraphViewController? value) {
    if (_controller == value) return;
    _controller = value;
    markNeedsLayout();
  }

  bool _centerGraph;
  bool get centerGraph => _centerGraph;
  set centerGraph(bool value) {
    if (_centerGraph == value) return;
    _centerGraph = value;
    markNeedsLayout();
  }

  Map<Node, Offset> animatedPositions;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeBoxData) {
      child.parentData = NodeBoxData();
    }
  }

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.smallest;
      return;
    }

    var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as NodeBoxData;
      final node = childParentData.node;

      child.layout(BoxConstraints.loose(const Size(1000, 1000)),
          parentUsesSize: true);
      if (node != null) {
        node.size = child.size;
      }
      child = childParentData.nextSibling;
    }

    final graphSize = algorithm.run(graph, 0, 0);

    const logicalCanvasSize = 200000.0;
    final desiredWidth = max(graphSize.width, constraints.maxWidth);
    final desiredHeight = max(graphSize.height, constraints.maxHeight);

    size = constraints.constrain(Size(
      desiredWidth.isFinite ? desiredWidth : logicalCanvasSize,
      desiredHeight.isFinite ? desiredHeight : logicalCanvasSize,
    ));

    if (centerGraph) {
      final shiftX = (size.width - graphSize.width) / 2;
      final shiftY = (size.height - graphSize.height) / 2;
      algorithm.run(graph, shiftX, shiftY);
    }

    _controller?.notifyLayoutFinished();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);

    if (algorithm.renderer != null) {
      algorithm.renderer!.setHiddenNodes(_controller?.getHiddenNodeIds() ?? {});
      algorithm.renderer!.setAnimatedPositions(animatedPositions);
      algorithm.renderer!.render(context.canvas, graph, edgePaint);
    } else {
      for (final edge in graph.edges) {
        if ((_controller?.isNodeHidden(edge.source) ?? false) ||
            (_controller?.isNodeHidden(edge.destination) ?? false)) {
          continue;
        }
        final srcPos = animatedPositions[edge.source] ?? edge.source.position;
        final dstPos =
            animatedPositions[edge.destination] ?? edge.destination.position;
        context.canvas.drawLine(
          Offset(srcPos.dx + edge.source.width / 2,
              srcPos.dy + edge.source.height / 2),
          Offset(dstPos.dx + edge.destination.width / 2,
              dstPos.dy + edge.destination.height / 2),
          edge.paint ?? edgePaint,
        );
      }
    }

    context.canvas.restore();

    var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as NodeBoxData;
      final node = childParentData.node;
      if (node != null) {
        final pos = animatedPositions[node] ?? node.position;
        context.paintChild(child, pos + offset);
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final childParentData = child.parentData as NodeBoxData;
      final node = childParentData.node;
      if (node != null) {
        final pos = animatedPositions[node] ?? node.position;
        final isHit = result.addWithPaintOffset(
          offset: pos,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            return child!.hitTest(result, position: transformed);
          },
        );
        if (isHit) return true;
      }
      child = childParentData.previousSibling;
    }
    return false;
  }
}

class GraphChildDelegate {
  final Graph graph;
  final Algorithm algorithm;
  final NodeWidgetBuilder builder;
  final GraphViewController? controller;

  GraphChildDelegate({
    required this.graph,
    required this.algorithm,
    required this.builder,
    this.controller,
  });
}
