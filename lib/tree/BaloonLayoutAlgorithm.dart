part of graphview;

// Polar coordinate representation
class PolarPoint {
  final double theta; // angle in radians
  final double radius;

  const PolarPoint(this.theta, this.radius);

  static const PolarPoint origin = PolarPoint(0, 0);

  // Convert polar coordinates to cartesian
  Offset toCartesian() {
    final x = radius * cos(theta);
    final y = radius * sin(theta);
    return Offset(x, y);
  }

  // Create polar point from angle and radius
  static PolarPoint of(double theta, double radius) {
    return PolarPoint(theta, radius);
  }

  @override
  String toString() => 'PolarPoint(theta: $theta, radius: $radius)';
}

class BalloonLayoutAlgorithm extends Algorithm {
  late BuchheimWalkerConfiguration config;
  final Map<Node, TreeLayoutNodeData> nodeData = {};
  final Map<Node, PolarPoint> polarLocations = {};
  final Map<Node, double> radii = {};

  BalloonLayoutAlgorithm(this.config, EdgeRenderer? renderer) {
    this.renderer = renderer ?? ArrowEdgeRenderer();
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodes.isEmpty) {
      return Size.zero;
    }

    nodeData.clear();
    polarLocations.clear();
    radii.clear();

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

    _setRootPolars(graph, roots);
    _shiftCoordinates(graph, shiftX, shiftY);
    return graph.calculateGraphSize();
  }

  void _initializeData(Graph graph) {
    // Initialize node data
    for (final node in graph.nodes) {
      nodeData[node] = TreeLayoutNodeData();
    }

    // Build tree structure from edges
    for (final edge in graph.edges) {
      final source = edge.source;
      final target = edge.destination;

      nodeData[source]!.successorNodes.add(target);
      nodeData[target]!.parent = source;
    }
  }

  List<Node> _findRoots(Graph graph) {
    return graph.nodes.where((node) {
      return nodeData[node]!.parent == null;
    }).toList();
  }

  void _setRootPolars(Graph graph, List<Node> roots) {
    final center = _getGraphCenter(graph);
    final width = graph.calculateGraphBounds().width;
    final defaultRadius = max(width / 2, 200.0);

    if (roots.length == 1) {
      // Single tree - place root at center
      final root = roots.first;
      _setRootPolar(root, center);
      final children = successorsOf(root);
      _setPolars(children, center, 0, defaultRadius, <Node>{});
    } else if (roots.length > 1) {
      // Multiple trees - arrange roots in circle
      _setPolars(roots, center, 0, defaultRadius, <Node>{});
    }
  }

  void _setRootPolar(Node root, Offset center) {
    polarLocations[root] = PolarPoint.origin;
    root.position = center;
  }

  void _setPolars(List<Node> nodes, Offset parentLocation, double angleToParent,
      double parentRadius, Set<Node> seen) {
    final childCount = nodes.length;
    if (childCount == 0) return;

    // Calculate child placement parameters
    final angle = max(0, pi / 2 * (1 - 2.0 / childCount));
    final childRadius = parentRadius * cos(angle) / (1 + cos(angle));
    final radius = parentRadius - childRadius;

    // Angle between children
    final angleBetweenKids = 2 * pi / childCount;
    final offset = angleBetweenKids / 2 - angleToParent;

    for (int i = 0; i < nodes.length; i++) {
      final child = nodes[i];
      if (seen.contains(child)) continue;

      // Calculate angle for this child
      final theta = i * angleBetweenKids + offset;

      // Store radius and polar coordinates
      radii[child] = childRadius;
      final polarPoint = PolarPoint.of(theta, radius);
      polarLocations[child] = polarPoint;

      // Convert to cartesian and position node
      final cartesian = polarPoint.toCartesian();
      final position = Offset(
        parentLocation.dx + cartesian.dx,
        parentLocation.dy + cartesian.dy,
      );
      child.position = position;

      final newAngleToParent = atan2(
        parentLocation.dy - position.dy,
        parentLocation.dx - position.dx,
      );

      final grandChildren = successorsOf(child)
          .where((node) => !seen.contains(node))
          .toList();

      if (grandChildren.isNotEmpty) {
        final newSeen = Set<Node>.from(seen);
        newSeen.add(child); // Add current child to prevent cycles
        _setPolars(grandChildren, position, newAngleToParent, childRadius, newSeen);
      }
    }
  }

  Offset _getGraphCenter(Graph graph) {
    final bounds = graph.calculateGraphBounds();
    return Offset(
      bounds.left + bounds.width / 2,
      bounds.top + bounds.height / 2,
    );
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
    polarLocations.clear();
    radii.clear();

    _initializeData(spanningTree);
    final roots = _findRoots(spanningTree);

    if (roots.isEmpty && spanningTree.nodes.isNotEmpty) {
      final fakeRoot = spanningTree.nodes.first;
      _setRootPolars(spanningTree, [fakeRoot]);
    } else {
      _setRootPolars(spanningTree, roots);
    }

    _shiftCoordinates(spanningTree, shiftX, shiftY);
    return spanningTree.calculateGraphSize();
  }

  List<Node> successorsOf(Node? node) {
    return nodeData[node]!.successorNodes;
  }

  PolarPoint? getPolarLocation(Node node) {
    return polarLocations[node];
  }

  double? getRadius(Node node) {
    return radii[node];
  }

  Map<Node, double> getRadii() {
    return Map.from(radii);
  }

  Map<Node, PolarPoint> getPolarLocations() {
    return Map.from(polarLocations);
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