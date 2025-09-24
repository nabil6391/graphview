part of graphview;

class CircleLayoutConfiguration {
  final double radius;
  final bool reduceEdgeCrossing;
  final int reduceEdgeCrossingMaxEdges;

  CircleLayoutConfiguration({
    this.radius = 0.0, // 0 means auto-calculate
    this.reduceEdgeCrossing = true,
    this.reduceEdgeCrossingMaxEdges = 200,
  });
}

class CircleLayoutAlgorithm extends Algorithm {
  final CircleLayoutConfiguration config;
  double _radius = 0.0;
  List<Node> nodeOrderedList = [];

  CircleLayoutAlgorithm(this.config, EdgeRenderer? renderer) {
    this.renderer = renderer ?? ArrowEdgeRenderer();
    _radius = config.radius;
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodes.isEmpty) {
      return Size.zero;
    }

    // Handle single node case
    if (graph.nodes.length == 1) {
      final node = graph.nodes.first;
      node.position = Offset(shiftX + 100, shiftY + 100);
      return Size(200, 200);
    }

    _computeNodeOrder(graph);
    final size = _layoutNodes(graph);
    _shiftCoordinates(graph, shiftX, shiftY);

    return size;
  }

  void _computeNodeOrder(Graph graph) {
    final shouldReduceCrossing = config.reduceEdgeCrossing &&
        graph.edges.length < config.reduceEdgeCrossingMaxEdges;

    if (shouldReduceCrossing) {
      nodeOrderedList = _reduceEdgeCrossing(graph);
    } else {
      nodeOrderedList = List.from(graph.nodes);
    }
  }

  List<Node> _reduceEdgeCrossing(Graph graph) {
    // Check if graph has multiple components
    final components = _findConnectedComponents(graph);
    final orderedList = <Node>[];

    if (components.length > 1) {
      // Handle each component separately
      for (final component in components) {
        final componentGraph = _createSubgraph(graph, component);
        final componentOrder = _optimizeNodeOrder(componentGraph);
        orderedList.addAll(componentOrder);
      }
    } else {
      // Single component
      orderedList.addAll(_optimizeNodeOrder(graph));
    }

    return orderedList;
  }

  List<Set<Node>> _findConnectedComponents(Graph graph) {
    final visited = <Node>{};
    final components = <Set<Node>>[];

    for (final node in graph.nodes) {
      if (!visited.contains(node)) {
        final component = <Node>{};
        _dfsComponent(graph, node, visited, component);
        components.add(component);
      }
    }

    return components;
  }

  void _dfsComponent(Graph graph, Node node, Set<Node> visited, Set<Node> component) {
    visited.add(node);
    component.add(node);

    for (final edge in graph.edges) {
      Node? neighbor;
      if (edge.source == node && !visited.contains(edge.destination)) {
        neighbor = edge.destination;
      } else if (edge.destination == node && !visited.contains(edge.source)) {
        neighbor = edge.source;
      }

      if (neighbor != null) {
        _dfsComponent(graph, neighbor, visited, component);
      }
    }
  }

  Graph _createSubgraph(Graph originalGraph, Set<Node> nodes) {
    final subgraph = Graph();

    // Add nodes
    for (final node in nodes) {
      subgraph.addNode(node);
    }

    // Add edges within the component
    for (final edge in originalGraph.edges) {
      if (nodes.contains(edge.source) && nodes.contains(edge.destination)) {
        subgraph.addEdgeS(edge);
      }
    }

    return subgraph;
  }

  List<Node> _optimizeNodeOrder(Graph graph) {
    if (graph.nodes.length <= 2) {
      return List.from(graph.nodes);
    }

    // Simple greedy optimization to reduce edge crossings
    var bestOrder = List<Node>.from(graph.nodes);
    var bestCrossings = _countCrossings(graph, bestOrder);

    // Try a few different starting arrangements
    final attempts = min(10, graph.nodes.length);

    for (var attempt = 0; attempt < attempts; attempt++) {
      var currentOrder = List<Node>.from(graph.nodes);

      // Shuffle starting order
      if (attempt > 0) {
        currentOrder.shuffle();
      }

      // Local optimization: try swapping adjacent nodes
      var improved = true;
      var iterations = 0;
      const maxIterations = 50;

      while (improved && iterations < maxIterations) {
        improved = false;
        iterations++;

        for (var i = 0; i < currentOrder.length - 1; i++) {
          // Try swapping positions i and i+1
          final temp = currentOrder[i];
          currentOrder[i] = currentOrder[i + 1];
          currentOrder[i + 1] = temp;

          final crossings = _countCrossings(graph, currentOrder);

          if (crossings < bestCrossings) {
            bestOrder = List.from(currentOrder);
            bestCrossings = crossings;
            improved = true;
          } else {
            // Swap back if no improvement
            currentOrder[i + 1] = currentOrder[i];
            currentOrder[i] = temp;
          }
        }
      }
    }

    return bestOrder;
  }

  int _countCrossings(Graph graph, List<Node> nodeOrder) {
    if (nodeOrder.length < 3) return 0;

    final nodePositions = <Node, int>{};
    for (var i = 0; i < nodeOrder.length; i++) {
      nodePositions[nodeOrder[i]] = i;
    }

    var crossings = 0;
    final edges = graph.edges;

    // Count crossings between all pairs of edges
    for (var i = 0; i < edges.length; i++) {
      final edge1 = edges[i];
      final pos1a = nodePositions[edge1.source]!;
      final pos1b = nodePositions[edge1.destination]!;

      for (var j = i + 1; j < edges.length; j++) {
        final edge2 = edges[j];
        final pos2a = nodePositions[edge2.source]!;
        final pos2b = nodePositions[edge2.destination]!;

        // Check if edges cross when nodes are arranged in a circle
        if (_edgesCross(pos1a, pos1b, pos2a, pos2b, nodeOrder.length)) {
          crossings++;
        }
      }
    }

    return crossings;
  }

  bool _edgesCross(int pos1a, int pos1b, int pos2a, int pos2b, int totalNodes) {
    // Normalize positions so smaller is first
    if (pos1a > pos1b) {
      final temp = pos1a;
      pos1a = pos1b;
      pos1b = temp;
    }
    if (pos2a > pos2b) {
      final temp = pos2a;
      pos2a = pos2b;
      pos2b = temp;
    }

    // Check if one edge's endpoints separate the other edge's endpoints on the circle
    return (pos1a < pos2a && pos2a < pos1b && pos1b < pos2b) ||
        (pos2a < pos1a && pos1a < pos2b && pos2b < pos1b);
  }

  Size _layoutNodes(Graph graph) {
    // Calculate bounds for auto-sizing
    var width = 400.0;
    var height = 400.0;

    if (_radius <= 0) {
      _radius = 0.35 * max(width, height);
    }

    final centerX = width / 2;
    final centerY = height / 2;

    // Position nodes in circle
    for (var i = 0; i < nodeOrderedList.length; i++) {
      final node = nodeOrderedList[i];
      final angle = (2 * pi * i) / nodeOrderedList.length;

      final posX = cos(angle) * _radius + centerX;
      final posY = sin(angle) * _radius + centerY;

      node.position = Offset(posX, posY);
    }

    // Calculate actual bounds based on positioned nodes
    final bounds = graph.calculateGraphBounds();
    return Size(bounds.width + 40, bounds.height + 40); // Add some padding
  }
  

  void _shiftCoordinates(Graph graph, double shiftX, double shiftY) {
    for (final node in graph.nodes) {
      node.position = Offset(node.x + shiftX, node.y + shiftY);
    }
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