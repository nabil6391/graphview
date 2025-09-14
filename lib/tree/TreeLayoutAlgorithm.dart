part of graphview;

class TreeLayoutNodeData {
  Rectangle? bounds;
  int depth = 0;
  bool visited = false;
  List<Node> children = [];
  Node? parent;

  TreeLayoutNodeData();
}

class TreeLayoutAlgorithm extends Algorithm {
  late BuchheimWalkerConfiguration config;
  final Map<Node, TreeLayoutNodeData> nodeData = {};
  final Map<Node, Size> baseBounds = {};

  TreeLayoutAlgorithm(this.config, EdgeRenderer? renderer) {
    this.renderer = renderer ?? TreeEdgeRenderer(BuchheimWalkerConfiguration());
  }

  // Helper methods for orientation support
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
    nodeData.clear();
    baseBounds.clear();

    if (graph == null || graph.nodes.isEmpty) {
      return Size.zero;
    }

    // Handle single node case
    if (graph.nodes.length == 1) {
      final node = graph.nodes.first;
      node.position = Offset(shiftX + 100, shiftY + 100);
      return Size(200, 200);
    }

    _initializeData(graph);
    final roots = _findRoots(graph);

    if (roots.isEmpty) {
      final spanningTree = _createSpanningTree(graph);
      return _layoutSpanningTree(spanningTree, shiftX, shiftY);
    }

    _calculateSubtreeDimensions(roots);
    _positionNodes(roots);
    _correctVerticalEdgeOverlaps(graph);
    _applyOrientation(graph);
    _shiftCoordinates(graph, shiftX, shiftY);
    return graph.calculateGraphSize();
  }

  void _initializeData(Graph graph) {
    for (final node in graph.nodes) {
      nodeData[node] = TreeLayoutNodeData();
    }

    for (final edge in graph.edges) {
      final source = edge.source;
      final target = edge.destination;

      nodeData[source]!.children.add(target);
      nodeData[target]!.parent = source;
    }
  }

  List<Node> _findRoots(Graph graph) {
    return graph.nodes.where((node) {
      return nodeData[node]!.parent == null && nodeData[node]!.children.isNotEmpty;
    }).toList();
  }

  void _calculateSubtreeDimensions(List<Node> roots) {
    final visited = <Node>{};

    for (final root in roots) {
      _calculateWidth(root, visited);
    }

    visited.clear();
    for (final root in roots) {
      _calculateHeight(root, visited);
    }
  }

  int _calculateWidth(Node node, Set<Node> visited) {
    if (!visited.add(node)) return 0;

    final children = nodeData[node]!.children;
    if (children.isEmpty) {
      // For leaf nodes, use node width plus minimum spacing
      final nodeWidth = isVertical() ? node.width.toInt() : node.height.toInt();
      final width = max(nodeWidth, config.siblingSeparation);
      baseBounds[node] = Size(width.toDouble(), 0);
      return width;
    }

    var totalWidth = 0;
    for (var i = 0; i < children.length; i++) {
      totalWidth += _calculateWidth(children[i], visited);
      if (i < children.length - 1) {
        // Use sibling separation between children
        totalWidth += config.siblingSeparation;
      }
    }

    baseBounds[node] = Size(totalWidth.toDouble(), 0);
    return totalWidth;
  }

  int _calculateHeight(Node node, Set<Node> visited) {
    if (!visited.add(node)) return 0;

    final children = nodeData[node]!.children;
    if (children.isEmpty) {
      final nodeHeight = isVertical() ? node.height.toInt() : node.width.toInt();
      final height = max(nodeHeight, config.levelSeparation);
      final current = baseBounds[node]!;
      baseBounds[node] = Size(current.width, height.toDouble());
      return height;
    }

    var maxChildHeight = 0;
    for (final child in children) {
      maxChildHeight = max(maxChildHeight, _calculateHeight(child, visited));
    }

    // Use level separation for vertical spacing
    final totalHeight = maxChildHeight + config.levelSeparation;
    final current = baseBounds[node]!;
    baseBounds[node] = Size(current.width, totalHeight.toDouble());
    return totalHeight;
  }

  void _positionNodes(List<Node> roots) {
    // Use subtree separation between different root trees
    var currentX = config.subtreeSeparation.toDouble();

    for (var i = 0; i < roots.length; i++) {
      final root = roots[i];
      final rootWidth = baseBounds[root]!.width;
      currentX += rootWidth / 2;

      _buildTree(root, currentX, config.levelSeparation.toDouble(), <Node>{});

      currentX += rootWidth / 2;

      // Add subtree separation between roots, except for the last one
      if (i < roots.length - 1) {
        currentX += config.subtreeSeparation;
      }
    }
  }

  void _buildTree(Node node, double x, double y, Set<Node> visited) {
    if (!visited.add(node)) return;

    node.position = Offset(x, y);

    final children = nodeData[node]!.children;
    if (children.isEmpty) return;

    // Use level separation for vertical spacing
    final nextY = y + config.levelSeparation;
    final totalWidth = baseBounds[node]!.width;
    var childX = x - totalWidth / 2;

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final childWidth = baseBounds[child]!.width;
      childX += childWidth / 2;

      _buildTree(child, childX, nextY, visited);

      childX += childWidth / 2;

      // Use sibling separation between children, except for the last one
      if (i < children.length - 1) {
        childX += config.siblingSeparation;
      }
    }
  }

  void _correctVerticalEdgeOverlaps(Graph graph) {
    final verticalEdges = <double, List<Edge>>{};

    for (final edge in graph.edges) {
      final sourceX = edge.source.x;
      final targetX = edge.destination.x;

      if ((sourceX - targetX).abs() < 1.0) {
        verticalEdges.putIfAbsent(sourceX, () => []).add(edge);
      }
    }

    for (final node in graph.nodes) {
      final nodeX = node.x;
      final nodeY = node.y;

      for (final edges in verticalEdges.values) {
        for (final edge in edges) {
          if (edge.source == node || edge.destination == node) continue;

          final edgeX = edge.source.x;
          final minY = min(edge.source.y, edge.destination.y);
          final maxY = max(edge.source.y, edge.destination.y);

          if ((nodeX - edgeX).abs() < 1.0 && nodeY >= minY && nodeY <= maxY) {
            node.position = Offset(nodeX + config.siblingSeparation / 4, nodeY);
          }
        }
      }
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

  Size _layoutSpanningTree(Graph spanningTree, double shiftX, double shiftY) {
    nodeData.clear();
    baseBounds.clear();
    _initializeData(spanningTree);

    final roots = _findRoots(spanningTree);
    if (roots.isEmpty && spanningTree.nodes.isNotEmpty) {
      final fakeRoot = spanningTree.nodes.first;
      _calculateSubtreeDimensions([fakeRoot]);
      _positionNodes([fakeRoot]);
    } else {
      _calculateSubtreeDimensions(roots);
      _positionNodes(roots);
    }

    _applyOrientation(spanningTree);
    _shiftCoordinates(spanningTree, shiftX, shiftY);
    return spanningTree.calculateGraphSize();
  }

  @override
  void init(Graph? graph) {}

  @override
  void setDimensions(double width, double height) {}
}