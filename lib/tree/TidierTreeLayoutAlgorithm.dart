part of graphview;

class TidierTreeNodeData {
  int mod = 0;
  Node? thread;
  int shift = 0;
  Node? ancestor;
  int x = 0;
  int change = 0;
  int childCount = 0;
  List<Node> successorNodes = [];
  List<Node> predecessorNodes = [];

  TidierTreeNodeData();
}

class TidierTreeLayoutAlgorithm extends Algorithm {
  late BuchheimWalkerConfiguration config;
  final Map<Node, TidierTreeNodeData> nodeData = {};
  final Map<Node, Size> baseBounds = {};
  final List<int> heights = [];
  late List<Node> roots;
  Rect bounds = Rect.zero;
  late Graph tree;

  TidierTreeLayoutAlgorithm(this.config, EdgeRenderer? renderer) {
    this.renderer = renderer ?? TreeEdgeRenderer(config);
  }

  bool isVertical() {
    var orientation = config.orientation;
    return orientation == BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM ||
        orientation == BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP;
  }

  bool needReverseOrder() {
    var orientation = config.orientation;
    return orientation == BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP ||
        orientation == BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT;
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodes.isEmpty) {
      return Size.zero;
    }

    _clearMetadata();

    if (graph.nodes.length == 1) {
      final node = graph.nodes.first;
      node.position = Offset(shiftX + 100, shiftY + 100);
      return Size(200, 200);
    }

    _buildTree(graph);
    _applyOrientation(graph);
    _shiftCoordinates(graph, shiftX, shiftY);

    final size = graph.calculateGraphSize();
    _clearMetadata();
    return size;
  }

  void _clearMetadata() {
    heights.clear();
    baseBounds.clear();
    bounds = Rect.zero;
  }

  void _buildTree(Graph graph) {
    nodeData.clear();
    heights.clear();

    _initializeData(graph);
    roots = _findRoots(graph);

    if (roots.isEmpty) {
      final spanningTree = _createSpanningTree(graph);
      _buildTree(spanningTree);
      return;
    }

    tree = graph;

    final virtualRoot = roots.length > 1 ? null : roots.first;

    _firstWalk(virtualRoot, null);
    _computeMaxHeights(virtualRoot, 0);
    _secondWalk(
        virtualRoot, virtualRoot != null ? -_nodeData(virtualRoot).x : 0, 0, 0);

    _normalizePositions(graph);
  }

  void _initializeData(Graph graph) {
    // Initialize node data
    for (final node in graph.nodes) {
      nodeData[node] = TidierTreeNodeData();
    }

    // Build tree structure from edges
    for (final edge in graph.edges) {
      final source = edge.source;
      final target = edge.destination;

      nodeData[source]?.successorNodes.add(target);
      nodeData[target]?.predecessorNodes.add(source);
    }
  }

  List<Node> _findRoots(Graph graph) {
    final incomingCounts = <Node, int>{};
    for (final node in graph.nodes) {
      incomingCounts[node] = 0;
    }

    for (final edge in graph.edges) {
      incomingCounts[edge.destination] =
          (incomingCounts[edge.destination] ?? 0) + 1;
    }

    return graph.nodes.where((node) => incomingCounts[node] == 0).toList();
  }

  TidierTreeNodeData _nodeData(Node? v) {
    if (v == null) return TidierTreeNodeData();
    return nodeData.putIfAbsent(v, () => TidierTreeNodeData());
  }

  void _firstWalk(Node? v, Node? leftSibling) {
    if (successorsOf(v).isEmpty) {
      if (leftSibling != null) {
        _nodeData(v).x =
            _nodeData(leftSibling).x + _getDistance(v, leftSibling, true);
      }
    } else {
      final children = successorsOf(v);
      var defaultAncestor = children.isNotEmpty ? children.first : null;
      Node? previousChild;

      for (final child in children) {
        _firstWalk(child, previousChild);
        defaultAncestor = _apportion(child, defaultAncestor, previousChild, v);
        previousChild = child;
      }

      _shift(v);

      final firstChild = children.isNotEmpty ? children.first : null;
      final lastChild = children.isNotEmpty ? children.last : null;

      if (firstChild != null && lastChild != null) {
        final midpoint =
            (_nodeData(firstChild).x + _nodeData(lastChild).x) ~/ 2;

        if (leftSibling != null) {
          _nodeData(v).x =
              _nodeData(leftSibling).x + _getDistance(v, leftSibling, true);
          _nodeData(v).mod = _nodeData(v).x - midpoint;
        } else {
          _nodeData(v).x = midpoint;
        }
      }
    }
  }

  void _secondWalk(Node? v, int m, int depth, int yOffset) {
    if (v == null) {
      // Handle multiple roots with subtree separation
      var rootOffset = 0;
      for (var i = 0; i < roots.length; i++) {
        _secondWalk(roots[i], m + rootOffset, depth, yOffset);
        if (i < roots.length - 1) {
          rootOffset += config.subtreeSeparation;
        }
      }
      return;
    }

    final levelHeight =
        depth < heights.length ? heights[depth] : config.levelSeparation;
    final x = _nodeData(v).x + m;
    final y = yOffset + levelHeight ~/ 2;

    v.position = Offset(x.toDouble(), y.toDouble());
    _updateBounds(v, x, y);

    final children = successorsOf(v);
    if (children.isNotEmpty) {
      final newYOffset = yOffset + levelHeight + config.levelSeparation;
      for (final child in children) {
        _secondWalk(child, m + _nodeData(v).mod, depth + 1, newYOffset);
      }
    }
  }

  void _updateBounds(Node node, int centerX, int centerY) {
    final width = node.width.toInt();
    final height = node.height.toInt();
    final left = centerX - width ~/ 2;
    final right = centerX + width ~/ 2;
    final top = centerY - height ~/ 2;
    final bottom = centerY + height ~/ 2;

    final nodeBounds = Rect.fromLTRB(
        left.toDouble(), top.toDouble(), right.toDouble(), bottom.toDouble());
    bounds =
        bounds == Rect.zero ? nodeBounds : bounds.expandToInclude(nodeBounds);
  }

  void _computeMaxHeights(Node? node, int depth) {
    if (node == null) {
      for (final root in roots) {
        _computeMaxHeights(root, depth);
      }
      return;
    }

    while (heights.length <= depth) {
      heights.add(0);
    }

    final nodeHeight = isVertical()
        ? max(node.height.toInt(), config.levelSeparation)
        : max(node.width.toInt(), config.levelSeparation);
    heights[depth] = max(heights[depth], nodeHeight);

    for (final child in successorsOf(node)) {
      _computeMaxHeights(child, depth + 1);
    }
  }

  Node? _leftChild(Node? v) {
    final children = successorsOf(v);
    return children.isNotEmpty ? children.first : _nodeData(v).thread;
  }

  Node? _rightChild(Node? v) {
    final children = successorsOf(v);
    return children.isNotEmpty ? children.last : _nodeData(v).thread;
  }

  int _getDistance(Node? v, Node? w, bool isSibling) {
    if (v == null || w == null) return config.siblingSeparation;

    // Use appropriate separation based on relationship
    final separation =
        isSibling ? config.siblingSeparation : config.subtreeSeparation;

    // Consider node sizes in the calculation
    final vSize = isVertical() ? v.width.toInt() : v.height.toInt();
    final wSize = isVertical() ? w.width.toInt() : w.height.toInt();

    return (vSize + wSize) ~/ 2 + separation;
  }

  Node? _apportion(
      Node? v, Node? defaultAncestor, Node? leftSibling, Node? parentOfV) {
    if (leftSibling == null) return defaultAncestor;

    var vor = v;
    var vir = v;
    Node? vil = leftSibling;
    var vol = successorsOf(parentOfV).isNotEmpty
        ? successorsOf(parentOfV).first
        : null;

    var innerRight = _nodeData(vir).mod;
    var outerRight = _nodeData(vor).mod;
    var innerLeft = _nodeData(vil).mod;
    var outerLeft = _nodeData(vol).mod;

    var nextRightOfVil = _rightChild(vil);
    var nextLeftOfVir = _leftChild(vir);

    while (nextRightOfVil != null && nextLeftOfVir != null) {
      vil = nextRightOfVil;
      vir = nextLeftOfVir;
      vol = _leftChild(vol);
      vor = _rightChild(vor);

      if (vor != null) {
        _nodeData(vor).ancestor = v;
      }

      final shift = (_nodeData(vil).x + innerLeft) -
          (_nodeData(vir).x + innerRight) +
          _getDistance(vil, vir, true);

      if (shift > 0) {
        _moveSubtree(
            _ancestor(vil, parentOfV, defaultAncestor), v, parentOfV, shift);
        innerRight += shift;
        outerRight += shift;
      }

      innerLeft += _nodeData(vil).mod;
      innerRight += _nodeData(vir).mod;
      outerLeft += _nodeData(vol).mod;
      outerRight += _nodeData(vor).mod;

      nextRightOfVil = _rightChild(vil);
      nextLeftOfVir = _leftChild(vir);
    }

    if (nextRightOfVil != null && _rightChild(vor) == null) {
      _nodeData(vor).thread = nextRightOfVil;
      _nodeData(vor).mod += innerLeft - outerRight;
    }

    if (nextLeftOfVir != null && _leftChild(vol) == null) {
      _nodeData(vol).thread = nextLeftOfVir;
      _nodeData(vol).mod += innerRight - outerLeft;
      defaultAncestor = v;
    }

    return defaultAncestor;
  }

  Node? _ancestor(Node? vil, Node? parentOfV, Node? defaultAncestor) {
    final ancestor = _nodeData(vil).ancestor ?? vil;
    final predecessors = predecessorsOf(ancestor!);

    if (predecessors.contains(parentOfV)) {
      return ancestor;
    }
    return defaultAncestor;
  }

  void _moveSubtree(
      Node? leftNode, Node? rightNode, Node? parentNode, int shift) {
    if (leftNode == null || rightNode == null) return;

    final subtreeCount = _childPosition(rightNode, parentNode) -
        _childPosition(leftNode, parentNode);

    if (subtreeCount > 0) {
      final rightData = _nodeData(rightNode);
      final leftData = _nodeData(leftNode);

      rightData.change -= shift ~/ subtreeCount;
      rightData.shift += shift;
      leftData.change += shift ~/ subtreeCount;
      rightData.x += shift;
      rightData.mod += shift;
    }
  }

  int _childPosition(Node? node, Node? parentNode) {
    if (parentNode == null) {
      return roots.indexOf(node!) + 1;
    }

    if (_nodeData(node).childCount != 0) {
      return _nodeData(node).childCount;
    }

    final children = successorsOf(parentNode);
    for (var i = 0; i < children.length; i++) {
      _nodeData(children[i]).childCount = i + 1;
    }

    return _nodeData(node).childCount;
  }

  void _shift(Node? v) {
    final children = successorsOf(v);

    var shift = 0;
    var change = 0;

    for (final child in children.reversed) {
      final childData = _nodeData(child);
      childData.x += shift;
      childData.mod += shift;
      change += childData.change;
      shift += childData.shift + change;
    }
  }

  void _normalizePositions(Graph graph) {
    final graphBounds = graph.calculateGraphBounds();
    final xOffset = config.subtreeSeparation - graphBounds.left;
    final yOffset = config.levelSeparation - graphBounds.top;

    for (final node in graph.nodes) {
      node.position = Offset(
        node.x + xOffset,
        node.y + yOffset,
      );
    }
  }

  void _applyOrientation(Graph graph) {
    if (config.orientation ==
        BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM) {
      return;
    }

    final bounds = graph.calculateGraphBounds();
    final centerX = bounds.left + bounds.width / 2;
    final centerY = bounds.top + bounds.height / 2;

    for (final node in graph.nodes) {
      final x = node.x - centerX;
      final y = node.y - centerY;
      Offset newPosition;

      switch (config.orientation) {
        case BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP:
          newPosition = Offset(x + centerX, centerY - y);
          break;
        case BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT:
          newPosition = Offset(-y + centerX, x + centerY);
          break;
        case BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT:
          newPosition = Offset(y + centerX, -x + centerY);
          break;
        default:
          newPosition = node.position;
          break;
      }

      node.position = newPosition;
    }
  }

  void _shiftCoordinates(Graph graph, double shiftX, double shiftY) {
    for (final node in graph.nodes) {
      node.position = Offset(node.x + shiftX, node.y + shiftY);
    }
  }

  Graph _createSpanningTree(Graph graph) {
    final visited = <Node>{};
    final spanningEdges = <Edge>[];

    if (graph.nodes.isNotEmpty) {
      final startNode = graph.nodes.first;
      final queue = <Node>[startNode];
      visited.add(startNode);

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);

        for (final edge in graph.edges) {
          Node? neighbor;
          if (edge.source == current && !visited.contains(edge.destination)) {
            neighbor = edge.destination;
            spanningEdges.add(edge);
          } else if (edge.destination == current &&
              !visited.contains(edge.source)) {
            neighbor = edge.source;
            spanningEdges.add(Edge(current, edge.source));
          }

          if (neighbor != null && !visited.contains(neighbor)) {
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }
    }

    return Graph()..addEdges(spanningEdges);
  }

  List<Node> successorsOf(Node? v) {
    if (v == null) return roots;
    var nodes = nodeData[v]!.successorNodes;
    return nodes;
  }

  List<Node> predecessorsOf(Node v) {
    if (roots.contains(v)) return [];

    return nodeData[v]!.predecessorNodes;
  }

  @override
  void init(Graph? graph) {}

  @override
  void setDimensions(double width, double height) {}

  @override
  EdgeRenderer? renderer;
}
