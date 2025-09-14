part of graphview;

class TidierTreeNodeData {
  int mod = 0;
  Node? thread;
  int shift = 0;
  Node? ancestor;
  int x = 0;
  int change = 0;
  int childCount = 0;

  TidierTreeNodeData();
}

class TidierTreeLayoutAlgorithm extends Algorithm {
  late BuchheimWalkerConfiguration config;
  final Map<Node, TidierTreeNodeData> vertexData = {};
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
    vertexData.clear();
    bounds = Rect.zero;
  }

  void _buildTree(Graph graph) {
    if (graph.nodes.length == 1) {
      final loner = graph.nodes.first;
      loner.position = Offset(200, 200);
      roots = [loner];
      return;
    }

    vertexData.clear();
    heights.clear();

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
    _secondWalk(virtualRoot, virtualRoot != null ? -_vertexData(virtualRoot).x : 0, 0, 0);

    _normalizePositions(graph);
  }

  List<Node> _findRoots(Graph graph) {
    final incomingCounts = <Node, int>{};
    for (final node in graph.nodes) {
      incomingCounts[node] = 0;
    }

    for (final edge in graph.edges) {
      incomingCounts[edge.destination] = (incomingCounts[edge.destination] ?? 0) + 1;
    }

    return graph.nodes.where((node) => incomingCounts[node] == 0).toList();
  }

  TidierTreeNodeData _vertexData(Node? v) {
    if (v == null) return TidierTreeNodeData();
    return vertexData.putIfAbsent(v, () => TidierTreeNodeData());
  }

  void _firstWalk(Node? v, Node? leftSibling) {
    if (_successors(v).isEmpty) {
      if (leftSibling != null) {
        _vertexData(v).x = _vertexData(leftSibling).x + _getDistance(v, leftSibling, true);
      }
    } else {
      final children = _successors(v);
      Node? defaultAncestor = children.isNotEmpty ? children.first : null;
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
        final midpoint = (_vertexData(firstChild).x + _vertexData(lastChild).x) ~/ 2;

        if (leftSibling != null) {
          _vertexData(v).x = _vertexData(leftSibling).x + _getDistance(v, leftSibling, true);
          _vertexData(v).mod = _vertexData(v).x - midpoint;
        } else {
          _vertexData(v).x = midpoint;
        }
      }
    }
  }

  void _secondWalk(Node? v, int m, int depth, int yOffset) {
    if (v == null) {
      // Handle multiple roots with subtree separation
      int rootOffset = 0;
      for (int i = 0; i < roots.length; i++) {
        _secondWalk(roots[i], m + rootOffset, depth, yOffset);
        if (i < roots.length - 1) {
          rootOffset += config.subtreeSeparation;
        }
      }
      return;
    }

    final levelHeight = depth < heights.length ? heights[depth] : config.levelSeparation;
    final x = _vertexData(v).x + m;
    final y = yOffset + levelHeight ~/ 2;

    v.position = Offset(x.toDouble(), y.toDouble());
    _updateBounds(v, x, y);

    final children = _successors(v);
    if (children.isNotEmpty) {
      final newYOffset = yOffset + levelHeight + config.levelSeparation;
      for (final child in children) {
        _secondWalk(child, m + _vertexData(v).mod, depth + 1, newYOffset);
      }
    }
  }

  void _updateBounds(Node vertex, int centerX, int centerY) {
    final width = vertex.width.toInt();
    final height = vertex.height.toInt();
    final left = centerX - width ~/ 2;
    final right = centerX + width ~/ 2;
    final top = centerY - height ~/ 2;
    final bottom = centerY + height ~/ 2;

    final nodeBounds = Rect.fromLTRB(left.toDouble(), top.toDouble(), right.toDouble(), bottom.toDouble());
    bounds = bounds == Rect.zero ? nodeBounds : bounds.expandToInclude(nodeBounds);
  }

  void _computeMaxHeights(Node? vertex, int depth) {
    if (vertex == null) {
      for (final root in roots) {
        _computeMaxHeights(root, depth);
      }
      return;
    }

    while (heights.length <= depth) {
      heights.add(0);
    }

    final nodeHeight = isVertical()
        ? max(vertex.height.toInt(), config.levelSeparation)
        : max(vertex.width.toInt(), config.levelSeparation);
    heights[depth] = max(heights[depth], nodeHeight);

    for (final child in _successors(vertex)) {
      _computeMaxHeights(child, depth + 1);
    }
  }

  List<Node> _successors(Node? v) {
    if (v == null) {
      return roots;
    }

    final successors = <Node>[];
    for (final edge in tree.edges) {
      if (edge.source == v) {
        successors.add(edge.destination);
      }
    }
    return successors;
  }

  List<Node> _predecessors(Node v) {
    if (roots.contains(v)) {
      return [];
    }

    final predecessors = <Node>[];
    for (final edge in tree.edges) {
      if (edge.destination == v) {
        predecessors.add(edge.source);
      }
    }
    return predecessors;
  }

  Node? _leftChild(Node? v) {
    final children = _successors(v);
    return children.isNotEmpty ? children.first : _vertexData(v).thread;
  }

  Node? _rightChild(Node? v) {
    final children = _successors(v);
    return children.isNotEmpty ? children.last : _vertexData(v).thread;
  }

  int _getDistance(Node? v, Node? w, bool isSibling) {
    if (v == null || w == null) return config.siblingSeparation;

    // Use appropriate separation based on relationship
    final separation = isSibling ? config.siblingSeparation : config.subtreeSeparation;

    // Consider node sizes in the calculation
    final vSize = isVertical() ? v.width.toInt() : v.height.toInt();
    final wSize = isVertical() ? w.width.toInt() : w.height.toInt();

    return (vSize + wSize) ~/ 2 + separation;
  }

  Node? _apportion(Node? v, Node? defaultAncestor, Node? leftSibling, Node? parentOfV) {
    if (leftSibling == null) return defaultAncestor;

    Node? vor = v;
    Node? vir = v;
    Node? vil = leftSibling;
    Node? vol = _successors(parentOfV).isNotEmpty ? _successors(parentOfV).first : null;

    int innerRight = _vertexData(vir).mod;
    int outerRight = _vertexData(vor).mod;
    int innerLeft = _vertexData(vil).mod;
    int outerLeft = _vertexData(vol).mod;

    Node? nextRightOfVil = _rightChild(vil);
    Node? nextLeftOfVir = _leftChild(vir);

    while (nextRightOfVil != null && nextLeftOfVir != null) {
      vil = nextRightOfVil;
      vir = nextLeftOfVir;
      vol = _leftChild(vol);
      vor = _rightChild(vor);

      if (vor != null) {
        _vertexData(vor).ancestor = v;
      }

      final shift = (_vertexData(vil).x + innerLeft) - (_vertexData(vir).x + innerRight) + _getDistance(vil, vir, true);

      if (shift > 0) {
        _moveSubtree(_ancestor(vil, parentOfV, defaultAncestor), v, parentOfV, shift);
        innerRight += shift;
        outerRight += shift;
      }

      innerLeft += _vertexData(vil).mod;
      innerRight += _vertexData(vir).mod;
      outerLeft += _vertexData(vol).mod;
      outerRight += _vertexData(vor).mod;

      nextRightOfVil = _rightChild(vil);
      nextLeftOfVir = _leftChild(vir);
    }

    if (nextRightOfVil != null && _rightChild(vor) == null) {
      _vertexData(vor).thread = nextRightOfVil;
      _vertexData(vor).mod += innerLeft - outerRight;
    }

    if (nextLeftOfVir != null && _leftChild(vol) == null) {
      _vertexData(vol).thread = nextLeftOfVir;
      _vertexData(vol).mod += innerRight - outerLeft;
      defaultAncestor = v;
    }

    return defaultAncestor;
  }

  Node? _ancestor(Node? vil, Node? parentOfV, Node? defaultAncestor) {
    final ancestor = _vertexData(vil).ancestor ?? vil;
    final predecessors = _predecessors(ancestor!);

    if (predecessors.contains(parentOfV)) {
      return ancestor;
    }
    return defaultAncestor;
  }

  void _moveSubtree(Node? leftVertex, Node? rightVertex, Node? parentVertex, int shift) {
    if (leftVertex == null || rightVertex == null) return;

    final subtreeCount = _childPosition(rightVertex, parentVertex) - _childPosition(leftVertex, parentVertex);

    if (subtreeCount > 0) {
      final rightData = _vertexData(rightVertex);
      final leftData = _vertexData(leftVertex);

      rightData.change -= shift ~/ subtreeCount;
      rightData.shift += shift;
      leftData.change += shift ~/ subtreeCount;
      rightData.x += shift;
      rightData.mod += shift;
    }
  }

  int _childPosition(Node? vertex, Node? parentNode) {
    if (parentNode == null) {
      return roots.indexOf(vertex!) + 1;
    }

    if (_vertexData(vertex).childCount != 0) {
      return _vertexData(vertex).childCount;
    }

    final children = _successors(parentNode);
    for (int i = 0; i < children.length; i++) {
      _vertexData(children[i]).childCount = i + 1;
    }

    return _vertexData(vertex).childCount;
  }

  void _shift(Node? v) {
    final children = _successors(v);

    int shift = 0;
    int change = 0;

    for (final child in children.reversed) {
      final childData = _vertexData(child);
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
    if (config.orientation == BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM) {
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
          } else if (edge.destination == current && !visited.contains(edge.source)) {
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

  @override
  void init(Graph? graph) {}

  @override
  void setDimensions(double width, double height) {}

  @override
  EdgeRenderer? renderer;
}