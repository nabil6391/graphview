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

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    nodeData.clear();
    baseBounds.clear();


    if (graph ==null || graph.nodes.isEmpty) {
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
      // If no roots found, create a spanning tree
      final spanningTree = _createSpanningTree(graph);
      return _layoutSpanningTree(spanningTree, shiftX, shiftY);
    }

    _calculateSubtreeDimensions(roots);
    _positionNodes(roots);

      _correctVerticalEdgeOverlaps(graph);

      // _expandToFill(graph);

    _shiftCoordinates(graph, shiftX, shiftY);
    return graph.calculateGraphSize();
  }

  void _initializeData(Graph graph) {
    // Initialize node data and build parent-child relationships
    for (final node in graph.nodes) {
      nodeData[node] = TreeLayoutNodeData();
    }

    // Build tree structure from edges
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
      final width = max(node.width.toInt(), config.siblingSeparation);
      baseBounds[node] = Size(width.toDouble(), 0);
      return width;
    }

    int totalWidth = 0;
    for (int i = 0; i < children.length; i++) {
      totalWidth += _calculateWidth(children[i], visited);
      if (i < children.length - 1) {
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
      final height = max(node.height.toInt(), config.levelSeparation);
      final current = baseBounds[node]!;
      baseBounds[node] = Size(current.width, height.toDouble());
      return height;
    }

    int maxChildHeight = 0;
    for (final child in children) {
      maxChildHeight = max(maxChildHeight, _calculateHeight(child, visited));
    }

    final totalHeight = maxChildHeight + config.levelSeparation;
    final current = baseBounds[node]!;
    baseBounds[node] = Size(current.width, totalHeight.toDouble());
    return totalHeight;
  }

  void _positionNodes(List<Node> roots) {
    double currentX = config.siblingSeparation.toDouble();

    for (final root in roots) {
      final rootWidth = baseBounds[root]!.width;
      currentX += rootWidth / 2;

      _buildTree(root, currentX, config.levelSeparation.toDouble(), <Node>{});

      currentX += rootWidth / 2 + config.siblingSeparation;
    }
  }

  void _buildTree(Node node, double x, double y, Set<Node> visited) {
    if (!visited.add(node)) return;

    node.position = Offset(x, y);

    final children = nodeData[node]!.children;
    if (children.isEmpty) return;

    final nextY = y + config.levelSeparation;
    final totalWidth = baseBounds[node]!.width;
    double childX = x - totalWidth / 2;

    for (final child in children) {
      final childWidth = baseBounds[child]!.width;
      childX += childWidth / 2;

      _buildTree(child, childX, nextY, visited);

      childX += childWidth / 2 + config.siblingSeparation;
    }
  }

  void _correctVerticalEdgeOverlaps(Graph graph) {
    // Simple overlap correction - move nodes that overlap vertical edges
    final verticalEdges = <double, List<Edge>>{};

    for (final edge in graph.edges) {
      final sourceX = edge.source.x;
      final targetX = edge.destination.x;

      if ((sourceX - targetX).abs() < 1.0) { // Vertical edge
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
            // Move node to avoid overlap
            node.position = Offset(nodeX + config.siblingSeparation / 4, nodeY);
          }
        }
      }
    }
  }

  void _expandToFill(Graph graph) {
    final bounds = graph.calculateGraphBounds();
    if (bounds.width <= 0 || bounds.height <= 0) return;

    // Add padding
    final paddedWidth = bounds.width + 2 * config.siblingSeparation;
    final paddedHeight = bounds.height + 2 * config.levelSeparation;

    final maxDimension = max(paddedWidth, paddedHeight);
    final scale = maxDimension / max(bounds.width, bounds.height);

    if (scale > 1.0) {
      final centerX = bounds.left + bounds.width / 2;
      final centerY = bounds.top + bounds.height / 2;

      for (final node in graph.nodes) {
        final offsetX = (node.x - centerX) * scale;
        final offsetY = (node.y - centerY) * scale;
        node.position = Offset(centerX + offsetX, centerY + offsetY);
      }
    }
  }

  void _shiftCoordinates(Graph graph, double shiftX, double shiftY) {
    for (final node in graph.nodes) {
      node.position = Offset(node.x + shiftX, node.y + shiftY);
    }
  }

  // Simplified spanning tree creation using BFS
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
            spanningEdges.add(Edge(current, edge.source)); // Maintain direction
          }

          if (neighbor != null && !visited.contains(neighbor)) {
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }
    }

    return Graph()
      ..addEdges(spanningEdges);
  }

  Size _layoutSpanningTree(Graph spanningTree, double shiftX, double shiftY) {
    // Reinitialize with spanning tree and run layout
    nodeData.clear();
    baseBounds.clear();
    _initializeData(spanningTree);

    final roots = _findRoots(spanningTree);
    if (roots.isEmpty && spanningTree.nodes.isNotEmpty) {
      // If still no roots, pick the first node as root
      final fakeRoot = spanningTree.nodes.first;
      _calculateSubtreeDimensions([fakeRoot]);
      _positionNodes([fakeRoot]);
    } else {
      _calculateSubtreeDimensions(roots);
      _positionNodes(roots);
    }

    _shiftCoordinates(spanningTree, shiftX, shiftY);
    return spanningTree.calculateGraphSize();
  }

  @override
  void init(Graph? graph) {
    // TODO: implement init
  }

  @override
  void setDimensions(double width, double height) {
    // TODO: implement setDimensions
  }

}
