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

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodes.isEmpty) {
      return Size.zero;
    }

    _clearMetadata();

    // Handle single node case
    if (graph.nodes.length == 1) {
      final node = graph.nodes.first;
      node.position = Offset(shiftX + 100, shiftY + 100);
      return Size(200, 200);
    }

    _buildTree(graph);
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

    // Find roots
    roots = _findRoots(graph);

    if (roots.isEmpty) {
      final spanningTree = _createSpanningTree(graph);
      _buildTree(spanningTree);
      return;
    }

    tree = graph;

    // For forest (multiple roots), use null as the virtual parent
    final virtualRoot = roots.length > 1 ? null : roots.first;

    _firstWalk(virtualRoot, null);
    _computeMaxHeights(virtualRoot, 0);
    _secondWalk(virtualRoot, virtualRoot != null ? -_vertexData(virtualRoot).x : 0, 0, 0);

    // Normalize and position nodes
    _normalizePositions(graph);
  }

  List<Node> _findRoots(Graph graph) {
    final nodeData = <Node, List<Node>>{};

    // Initialize parent-child relationships
    for (final node in graph.nodes) {
      nodeData[node] = [];
    }

    for (final edge in graph.edges) {
      nodeData[edge.source]!.add(edge.destination);
    }

    // Find nodes with no incoming edges
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
      // Leaf node
      if (leftSibling != null) {
        _vertexData(v).x = _vertexData(leftSibling).x + _getDistance(v, leftSibling);
      }
    } else {
      // Internal node
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
          _vertexData(v).x = _vertexData(leftSibling).x + _getDistance(v, leftSibling);
          _vertexData(v).mod = _vertexData(v).x - midpoint;
        } else {
          _vertexData(v).x = midpoint;
        }
      }
    }
  }

  void _secondWalk(Node? v, int m, int depth, int yOffset) {
    if (v == null) {
      // Handle forest case - process all roots
      int rootOffset = 0;
      for (final root in roots) {
        _secondWalk(root, m, depth, yOffset);
        rootOffset += _getDistance(root, null);
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
      // Handle forest case
      for (final root in roots) {
        _computeMaxHeights(root, depth);
      }
      return;
    }

    // Ensure heights list is large enough
    while (heights.length <= depth) {
      heights.add(0);
    }

    final nodeHeight = max(vertex.height.toInt(), config.levelSeparation);
    heights[depth] = max(heights[depth], nodeHeight);

    for (final child in _successors(vertex)) {
      _computeMaxHeights(child, depth + 1);
    }
  }

  List<Node> _successors(Node? v) {
    if (v == null) {
      // Virtual root's children are the actual roots
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
      return []; // Roots have no predecessors
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

  int _getDistance(Node? v, Node? w) {
    if (v == null || w == null) return config.siblingSeparation;

    final sizeOfNodes = v.width.toInt() + w.width.toInt();
    return sizeOfNodes ~/ 2 + config.siblingSeparation;
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

      final shift = (_vertexData(vil).x + innerLeft) - (_vertexData(vir).x + innerRight) + _getDistance(vil, vir);

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
    children.reversed;

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
    final xOffset = config.siblingSeparation - graphBounds.left;
    final yOffset = config.levelSeparation - graphBounds.top;

    for (final node in graph.nodes) {
      node.position = Offset(
        node.x + xOffset,
        node.y + yOffset,
      );
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
  void init(Graph? graph) {
    // Implementation can be added if needed
  }

  @override
  void setDimensions(double width, double height) {
    // Implementation can be added if needed
  }

 
  @override
  EdgeRenderer? renderer;
}