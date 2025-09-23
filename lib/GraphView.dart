library graphview;

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
  _GraphViewState? _state;
  final TransformationController? transformationController;

  GraphViewController({this.transformationController});

  void _attach(_GraphViewState? state) => _state = state;

  void _detach() => _state = null;

  void animateToNode(ValueKey key) => _state?.jumpToNode(key, true);

  void jumpToNode(ValueKey key) => _state?.jumpToNode(key, false);

  void animateToMatrix(Matrix4 target) => _state?.animateToMatrix(target);

  void resetView() => _state?.resetView();

  void zoomToFit() => _state?.zoomToFit();

  void forceRecalculation() => _state?.forceRecalculation();

  bool isNodeCollapsed(Node node) => node.collapse;

  Node? _lastCollapsedNode;

  void expandNode(Node node) {
    node.collapse = false;
    // Clear the last collapsed node since we're expanding
    _lastCollapsedNode = null;
    forceRecalculation();
  }

  void collapseNode(Graph graph, Node node) {
    if (graph.hasSuccessor(node)) {
      node.collapse = true;
      // Set this as the last collapsed node
      _lastCollapsedNode = node;
      forceRecalculation();
    }
  }

  void toggleNodeExpanded(Graph graph, Node node) {
    if (node.collapse) {
      expandNode(node);
    } else {
      collapseNode(graph, node);
    }
  }
}

class GraphChildDelegate {
  final Graph graph;
  final Algorithm algorithm;
  final NodeWidgetBuilder builder;
  final bool addRepaintBoundaries;
  GraphViewController? controller;

  Graph? _cachedVisibleGraph;
  bool _needsRecalculation = true;

  GraphChildDelegate({
    required this.graph,
    required this.algorithm,
    required this.builder,
    required this.controller,
    this.addRepaintBoundaries = true,
  });

  Graph getVisibleGraph() {
    if (_cachedVisibleGraph != null && !_needsRecalculation) {
      return _cachedVisibleGraph!;
    }

    final visibleGraph = Graph();
    for (final edge in graph.edges) {
      if (isNodeVisible(edge.source) &&
          (isNodeVisible(edge.destination) || isCollapsing(edge.destination))) {
        visibleGraph.addEdgeS(edge);
      }
    }

    if (visibleGraph.nodes.isEmpty && graph.nodes.isNotEmpty) {
      visibleGraph.addNode(graph.nodes.first);
    }

    _cachedVisibleGraph = visibleGraph;
    _needsRecalculation = false;
    return visibleGraph;
  }

  Graph getVisibleGraphOnly() {
    final visibleGraph = Graph();
    for (final edge in graph.edges) {
      if (isNodeVisible(edge.source) && isNodeVisible(edge.destination)) {
        visibleGraph.addEdgeS(edge);
      }
    }

    if (visibleGraph.nodes.isEmpty && graph.nodes.isNotEmpty) {
      visibleGraph.addNode(graph.nodes.first);
    }
    return visibleGraph;
  }

  Widget? build(Node node) {
    var child = node.data ?? builder(node);
    if (addRepaintBoundaries) {
      child = RepaintBoundary(child: child);
    }
    return KeyedSubtree(key: node.key, child: child);
  }

  bool shouldRebuild(GraphChildDelegate oldDelegate) {
    final result = graph != oldDelegate.graph ||
        algorithm != oldDelegate.algorithm ||
        addRepaintBoundaries != oldDelegate.addRepaintBoundaries;
    if (result) _needsRecalculation = true;
    return result;
  }

  Size runAlgorithm() {
    final visibleGraph = getVisibleGraphOnly();
    final cachedSize = algorithm.run(visibleGraph, 0, 0);

    var visibleIndex = 0;
    for (final originalNode in graph.nodes) {
      if (isNodeVisible(originalNode)) {
        originalNode.position =
            visibleGraph.getNodeAtPosition(visibleIndex).position;
        visibleIndex++;
      }
    }
    return cachedSize;
  }

  bool isNodeVisible(Node node) {
    return graph.isNodeVisible(node);
  }

  Node? findClosestVisibleAncestor(Node node) {
    return graph.findClosestVisibleAncestor(node);
  }

  bool isCollapsing(Node node) {
    // Node is collapsing if:
    // 1. It's not visible
    // 2. It's not the node that was collapsed (that one stays in place)
    // 3. It has the last collapsed node as an ancestor

    if (isNodeVisible(node)) return false;

    var _lastCollapsedNode = controller?._lastCollapsedNode;
    if (node == _lastCollapsedNode) return false;

    // Check if _lastCollapsedNode is an ancestor of this node
    if (_lastCollapsedNode != null) {
      Node? current = node;
      while (current != null) {
        final parent = graph.predecessorsOf(current).firstOrNull;
        if (parent == _lastCollapsedNode) {
          return true;
        }
        current = parent;
      }
    }

    return false;
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
  late GraphChildDelegate delegate;

  GraphView({
    Key? key,
    required this.graph,
    required this.algorithm,
    this.paint,
    required this.builder,
    this.animated = true,
  })  : controller = null,
        _isBuilder = false,
        delegate = GraphChildDelegate(
            graph: graph,
            algorithm: algorithm,
            builder: builder,
            controller: null),
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
        delegate = GraphChildDelegate(
            graph: graph,
            algorithm: algorithm,
            builder: builder,
            controller: controller),
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

  @override
  void initState() {
    super.initState();

    _transformationController = widget.controller?.transformationController ??
        TransformationController();

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
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = GraphViewWidget(
      paint: widget.paint,
      nodeAnimationController: _nodeController,
      enableAnimation: true,
      delegate: widget.delegate,
    );

    if (widget._isBuilder) {
      return InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        boundaryMargin: EdgeInsets.all(double.infinity),
        minScale: 0.01,
        maxScale: 10,
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
    final scale = (vp.shortestSide * 0.95 / bounds.longestSide);
    final centerOffset = Offset(vp.width * 0.5 - bounds.center.dx * scale,
        vp.height * 0.5 - bounds.center.dy * scale);

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

abstract class GraphChildManager {
  void startLayout();

  void buildChild(Node node);

  void reuseChild(Node node);

  void endLayout();
}

class GraphViewWidget extends RenderObjectWidget {
  final GraphChildDelegate delegate;
  final Paint? paint;
  final AnimationController nodeAnimationController;
  final bool enableAnimation;

  const GraphViewWidget({
    Key? key,
    required this.delegate,
    this.paint,
    required this.nodeAnimationController,
    required this.enableAnimation,
  }) : super(key: key);

  @override
  GraphViewElement createElement() => GraphViewElement(this);

  @override
  RenderCustomLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomLayoutBox(
      delegate,
      paint,
      enableAnimation,
      nodeAnimationController: nodeAnimationController,
      childManager: context as GraphChildManager,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderCustomLayoutBox renderObject) {
    renderObject
      ..delegate = delegate
      ..edgePaint = paint
      ..nodeAnimationController = nodeAnimationController
      ..enableAnimation = enableAnimation;
  }
}

class GraphViewElement extends RenderObjectElement
    implements GraphChildManager {
  GraphViewElement(GraphViewWidget super.widget);

  @override
  GraphViewWidget get widget => super.widget as GraphViewWidget;

  @override
  RenderCustomLayoutBox get renderObject =>
      super.renderObject as RenderCustomLayoutBox;

  // Contains all children, including those that are keyed
  Map<Node, Element> _nodeToElement = <Node, Element>{};
  Map<Key, Element> _keyToElement = <Key, Element>{};

  // Used between startLayout() & endLayout() to compute the new values
  Map<Node, Element>? _newNodeToElement;
  Map<Key, Element>? _newKeyToElement;

  bool get _debugIsDoingLayout =>
      _newNodeToElement != null && _newKeyToElement != null;

  @override
  void performRebuild() {
    super.performRebuild();
    // Children list is updated during layout since we only know during layout
    // which children will be visible
    renderObject.markNeedsLayout();
  }

  @override
  void forgetChild(Element child) {
    assert(!_debugIsDoingLayout);
    super.forgetChild(child);
    _nodeToElement.remove(child.slot as Node);
    if (child.widget.key != null) {
      _keyToElement.remove(child.widget.key);
    }
  }

  @override
  void insertRenderObjectChild(RenderBox child, Node slot) {
    renderObject._insertChild(child, slot);
  }

  @override
  void moveRenderObjectChild(RenderBox child, Node oldSlot, Node newSlot) {
    renderObject._moveChild(child, from: oldSlot, to: newSlot);
  }

  @override
  void removeRenderObjectChild(RenderBox child, Node slot) {
    renderObject._removeChild(child, slot);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    _nodeToElement.values.forEach(visitor);
  }

  // ---- GraphChildManager implementation ----

  @override
  void startLayout() {
    assert(!_debugIsDoingLayout);
    _newNodeToElement = <Node, Element>{};
    _newKeyToElement = <Key, Element>{};
  }

  @override
  void buildChild(Node node) {
    assert(_debugIsDoingLayout);
    owner!.buildScope(this, () {
      final newWidget = widget.delegate.build(node);
      if (newWidget == null) {
        return;
      }

      final oldElement = _retrieveOldElement(newWidget, node);
      final newChild = updateChild(oldElement, newWidget, node);

      if (newChild != null) {
        // Ensure we are not overwriting an existing child
        assert(_newNodeToElement![node] == null);
        _newNodeToElement![node] = newChild;
        if (newWidget.key != null) {
          // Ensure we are not overwriting an existing key
          assert(_newKeyToElement![newWidget.key!] == null);
          _newKeyToElement![newWidget.key!] = newChild;
        }
      }
    });
  }

  @override
  void reuseChild(Node node) {
    assert(_debugIsDoingLayout);
    final elementToReuse = _nodeToElement.remove(node);
    assert(
      elementToReuse != null,
      'Expected to re-use an element at $node, but none was found.',
    );
    _newNodeToElement![node] = elementToReuse!;
    if (elementToReuse.widget.key != null) {
      assert(_keyToElement.containsKey(elementToReuse.widget.key));
      assert(_keyToElement[elementToReuse.widget.key] == elementToReuse);
      _newKeyToElement![elementToReuse.widget.key!] =
          _keyToElement.remove(elementToReuse.widget.key)!;
    }
  }

  Element? _retrieveOldElement(Widget newWidget, Node node) {
    if (newWidget.key != null) {
      final result = _keyToElement.remove(newWidget.key);
      if (result != null) {
        _nodeToElement.remove(result.slot as Node);
      }
      return result;
    }

    final potentialOldElement = _nodeToElement[node];
    if (potentialOldElement != null && potentialOldElement.widget.key == null) {
      return _nodeToElement.remove(node);
    }
    return null;
  }

  @override
  void endLayout() {
    assert(_debugIsDoingLayout);

    // Unmount all elements that have not been reused in the layout cycle
    for (final element in _nodeToElement.values) {
      if (element.widget.key == null) {
        // If it has a key, we handle it below
        updateChild(element, null, null);
      } else {
        assert(_keyToElement.containsValue(element));
      }
    }
    for (final element in _keyToElement.values) {
      assert(element.widget.key != null);
      updateChild(element, null, null);
    }

    _nodeToElement = _newNodeToElement!;
    _keyToElement = _newKeyToElement!;
    _newNodeToElement = null;
    _newKeyToElement = null;
    assert(!_debugIsDoingLayout);
  }
}

class RenderCustomLayoutBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeBoxData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeBoxData> {
  late Paint _paint;
  late AnimationController _nodeAnimationController;
  late GraphChildDelegate _delegate;
  GraphChildManager? childManager;

  Size? _cachedSize;
  bool _isInitialized = false;
  bool _needsFullRecalculation = false;
  final animatedPositions = <Node, Offset>{};
  late bool enableAnimation;

  final Map<Node, RenderBox> _children = <Node, RenderBox>{};
  final Map<Node, RenderBox> _activeChildrenForLayoutPass = <Node, RenderBox>{};

  RenderCustomLayoutBox(
    GraphChildDelegate delegate,
    Paint? paint,
    bool enableAnimation, {
    required AnimationController nodeAnimationController,
    this.childManager,
  }) {
    _nodeAnimationController = nodeAnimationController;
    _delegate = delegate;
    edgePaint = paint;
    this.enableAnimation = enableAnimation;
  }

  RenderBox? buildOrObtainChildFor(Node node) {
    assert(debugDoingThisLayout);

    if (_needsFullRecalculation || !_children.containsKey(node)) {
      invokeLayoutCallback<BoxConstraints>((BoxConstraints _) {
        childManager!.buildChild(node);
      });
    } else {
      childManager!.reuseChild(node);
    }

    if (!_children.containsKey(node)) {
      // There is no child for this node, the delegate may not provide one
      return null;
    }

    assert(_children.containsKey(node));
    final child = _children[node]!;
    _activeChildrenForLayoutPass[node] = child;
    return child;
  }

  GraphChildDelegate get delegate => _delegate;

  Graph get graph => _delegate.getVisibleGraph();

  Algorithm get algorithm => _delegate.algorithm;

  set delegate(GraphChildDelegate value) {
    if (value != _delegate) {
      _needsFullRecalculation = true;
      _isInitialized = false;
      _delegate = value;
      markNeedsLayout();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _nodeAnimationController.addListener(_onAnimationTick);
    for (final child in _children.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    _nodeAnimationController.removeListener(_onAnimationTick);
    super.detach();
    for (final child in _children.values) {
      child.detach();
    }
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

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_children.isEmpty) {
      return;
    }

    if (enableAnimation) {
      final t = _nodeAnimationController.value;
      animatedPositions.clear();

      for (final entry in _children.entries) {
        final node = entry.key;
        final child = entry.value;
        final nodeData = child.parentData as NodeBoxData;
        final pos =
            Offset.lerp(nodeData.startOffset, nodeData.targetOffset, t)!;
        animatedPositions[node] = pos;
      }

      context.canvas.save();
      context.canvas.translate(offset.dx, offset.dy);
      algorithm.renderer?.setAnimatedPositions(animatedPositions);
      algorithm.renderer?.render(context.canvas, graph, edgePaint);
      context.canvas.restore();

      _paintNodes(context, offset, t);
    } else {
      context.canvas.save();
      context.canvas.translate(offset.dx, offset.dy);
      algorithm.renderer?.render(context.canvas, graph, edgePaint);
      context.canvas.restore();

      for (final entry in _children.entries) {
        final node = entry.key;
        final child = entry.value;

        if (_delegate.isNodeVisible(node)) {
          context.paintChild(child, offset + node.position);
        }
      }
    }
  }

  @override
  void performLayout() {
    _activeChildrenForLayoutPass.clear();
    childManager!.startLayout();

    final looseConstraints = BoxConstraints.loose(constraints.biggest);

    if (_needsFullRecalculation || !_isInitialized) {
      _layoutNodesLazily(looseConstraints);
      _cachedSize = _delegate.runAlgorithm();
      _isInitialized = true;
      _needsFullRecalculation = false;
    }

    size = _cachedSize ?? Size.zero;

    invokeLayoutCallback<BoxConstraints>((BoxConstraints _) {
      childManager!.endLayout();
    });

    if (enableAnimation) {
      _updateAnimationStates();
    } else {
      _updateNodePositions();
    }
  }

  void _paintNodes(PaintingContext context, Offset offset, double t) {
    for (final entry in _children.entries) {
      final node = entry.key;
      final child = entry.value;
      final nodeData = child.parentData as NodeBoxData;
      final pos = animatedPositions[node]!;

      final isVisible = _delegate.isNodeVisible(node);
      if (isVisible) {
        context.paintChild(child, offset + pos);
      } else {
        if (_nodeAnimationController.isAnimating &&
            nodeData.startOffset != nodeData.targetOffset) {
          _paintCollapsingNode(context, child, offset, pos, t);
        } else if (_nodeAnimationController.isCompleted) {
          nodeData.startOffset = nodeData.targetOffset;
        }
      }

      if (_nodeAnimationController.isCompleted) {
        nodeData.offset = node.position;
      }
    }
  }

  void _paintCollapsingNode(PaintingContext context, RenderBox child,
      Offset offset, Offset pos, double t) {
    final progress = (1.0 - t).clamp(0.0, 1.0);
    final center =
        pos + offset + Offset(child.size.width * 0.5, child.size.height * 0.5);

    context.canvas.save();
    context.canvas.translate(center.dx, center.dy);
    context.canvas.scale(progress, progress);
    context.canvas.translate(-center.dx, -center.dy);
    context.paintChild(child, offset + pos);
    context.canvas.restore();
  }

  void _updateNodePositions() {
    for (final entry in _children.entries) {
      final node = entry.key;
      final child = entry.value;
      final nodeData = child.parentData as NodeBoxData;

      if (_delegate.isNodeVisible(node)) {
        nodeData.offset = node.position;
      } else {
        final parent = delegate.findClosestVisibleAncestor(node);
        nodeData.offset = parent?.position ?? node.position;
      }
    }
  }

  void _layoutNodesLazily(BoxConstraints constraints) {
    // Build children lazily through buildOrObtainChildFor
    for (final node in graph.nodes) {
      final child = buildOrObtainChildFor(node);
      if (child != null) {
        child.layout(constraints, parentUsesSize: true);
        node.size = Size(child.size.width.ceilToDouble(), child.size.height);
      }
    }
  }

  void _updateAnimationStates() {
    for (final entry in _children.entries) {
      final node = entry.key;
      final child = entry.value;
      final nodeData = child.parentData as NodeBoxData;
      final isVisible = _delegate.isNodeVisible(node);

      if (isVisible) {
        _updateVisibleNodeAnimation(nodeData, node);
      } else {
        _updateCollapsedNodeAnimation(nodeData, node);
      }
    }

    if (enableAnimation && algorithm is! FruchtermanReingoldAlgorithm) {
      _nodeAnimationController.reset();
      _nodeAnimationController.forward();
    }
  }

  bool _updateVisibleNodeAnimation(NodeBoxData nodeData, Node graphNode) {
    final prevTarget = nodeData.targetOffset;
    var newPos = graphNode.position;

    if (prevTarget == null) {
      final parent = graph.predecessorsOf(graphNode).firstOrNull;
      nodeData.startOffset = parent?.position ?? newPos;
      nodeData.targetOffset = newPos;
      return true;
    } else if ((prevTarget - newPos).distance >= 0.1) {
      nodeData.startOffset = prevTarget;
      nodeData.targetOffset = newPos;
      return true;
    } else {
      nodeData.startOffset = newPos;
      nodeData.targetOffset = newPos;
      return false;
    }
  }

  void _updateCollapsedNodeAnimation(NodeBoxData nodeData, Node graphNode) {
    final parent = delegate.findClosestVisibleAncestor(graphNode);
    final parentPos = parent?.position ?? Offset.zero;

    final prevTarget = nodeData.targetOffset;

    if (nodeData.startOffset == nodeData.targetOffset) {
      nodeData.targetOffset = parentPos;
    } else if (prevTarget != null && prevTarget != parentPos) {
      // Just collapsed now → animate toward parent
      nodeData.startOffset = graphNode.position;
      nodeData.targetOffset = parentPos;
    } else {
      // animation finished → lock to parent
      nodeData.startOffset = parentPos;
      nodeData.targetOffset = parentPos;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final entry in _children.entries) {
      final node = entry.key;

      if (delegate.isNodeVisible(node)) {
        final child = entry.value;

        final childParentData = child.parentData as BoxParentData;

        final isHit = result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            return child.hitTest(result, position: transformed);
          },
        );
        if (isHit) return true;
      }
    }

    return false;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeBoxData) {
      child.parentData = NodeBoxData();
    }
  }

  // ---- Called from GraphViewElement ----
  void _insertChild(RenderBox child, Node slot) {
    _children[slot] = child;
    adoptChild(child);
  }

  void _moveChild(RenderBox child, {required Node from, required Node to}) {
    if (_children[from] == child) {
      _children.remove(from);
    }
    _children[to] = child;
  }

  void _removeChild(RenderBox child, Node slot) {
    if (_children[slot] == child) {
      _children.remove(slot);
    }
    dropChild(child);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    for (final child in _children.values) {
      visitor(child);
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
