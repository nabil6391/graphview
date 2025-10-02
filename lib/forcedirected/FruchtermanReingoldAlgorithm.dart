part of graphview;

class FruchtermanReingoldAlgorithm implements Algorithm {
  static const double DEFAULT_TICK_FACTOR = 0.1;
  static const double CONVERGENCE_THRESHOLD = 1.0;

  Map<Node, Offset> displacement = {};
  Map<Node, Rect> nodeRects = {};
  Random rand = Random();
  double graphHeight = 500; //default value, change ahead of time
  double graphWidth = 500;
  late double tick;

  FruchtermanReingoldConfiguration configuration;

  @override
  EdgeRenderer? renderer;

  FruchtermanReingoldAlgorithm(this.configuration, {this.renderer}) {
    this.configuration = configuration;
    this.renderer = renderer ?? ArrowEdgeRenderer(noArrow: true);
  }

  @override
  void init(Graph? graph) {
    graph!.nodes.forEach((node) {
      displacement[node] = Offset.zero;
      nodeRects[node] = Rect.fromLTWH(node.x, node.y, node.width, node.height);

      if (configuration.shuffleNodes) {
        node.position = Offset(
            rand.nextDouble() * graphWidth, rand.nextDouble() * graphHeight);
        // Update cached rect after position change
        nodeRects[node] =
            Rect.fromLTWH(node.x, node.y, node.width, node.height);
      }
    });
  }

  void moveNodes(Graph graph) {
    final lerpFactor = configuration.lerpFactor;

    graph.nodes.forEach((node) {
      final nodeDisplacement = displacement[node]!;
      var target = node.position + nodeDisplacement;
      var newPosition = Offset.lerp(node.position, target, lerpFactor)!;
      double newDX = min(graphWidth - node.size.width * 0.5,
          max(node.size.width * 0.5, newPosition.dx));
      double newDY = min(graphHeight - node.size.height * 0.5,
          max(node.size.height * 0.5, newPosition.dy));

      node.position = Offset(newDX, newDY);
      // Update cached rect after position change
      nodeRects[node] = Rect.fromLTWH(node.x, node.y, node.width, node.height);
    });
  }

  void cool(int currentIteration) {
    // tick *= 1.0 - currentIteration / configuration.iterations;
    const alpha = 0.99; // tweakable decay factor (0.8–0.99 typical)
    tick *= alpha;
  }

  void limitMaximumDisplacement(List<Node> nodes) {
    final epsilon = configuration.epsilon;

    nodes.forEach((node) {
      final nodeDisplacement = displacement[node]!;
      var dispLength = max(epsilon, nodeDisplacement.distance);
      node.position += nodeDisplacement / dispLength * min(dispLength, tick);
      // Update cached rect after position change
      nodeRects[node] = Rect.fromLTWH(node.x, node.y, node.width, node.height);
    });
  }

  void calculateAttraction(List<Edge> edges) {
    final attractionRate = configuration.attractionRate;
    final epsilon = configuration.epsilon;

    // Optimal distance (k) based on area and node count
    final k = sqrt((graphWidth * graphHeight) / (edges.length + 1));

    for (var edge in edges) {
      var source = edge.source;
      var destination = edge.destination;
      var delta = source.position - destination.position;
      var deltaDistance = max(epsilon, delta.distance);

      // Standard FR attraction: proportional to distance² / k
      var attractionForce = (deltaDistance * deltaDistance) / k;
      var attractionVector =
          delta / deltaDistance * attractionForce * attractionRate;

      displacement[source] = displacement[source]! - attractionVector;
      displacement[destination] = displacement[destination]! + attractionVector;
    }
  }

  void calculateRepulsion(List<Node> nodes) {
    final repulsionRate = configuration.repulsionRate;
    final repulsionPercentage = configuration.repulsionPercentage;
    final epsilon = configuration.epsilon;
    final nodeCountDouble = nodes.length.toDouble();
    final maxRepulsionDistance = min(
        graphWidth * repulsionPercentage, graphHeight * repulsionPercentage);

    for (var i = 0; i < nodeCountDouble; i++) {
      final currentNode = nodes[i];

      for (var j = i + 1; j < nodeCountDouble; j++) {
        final otherNode = nodes[j];
        if (currentNode != otherNode) {
          // Calculate distance between node rectangles, not just centers
          var delta = _getNodeRectDistance(currentNode, otherNode);
          var deltaDistance = max(epsilon, delta.distance); //protect for 0
          var repulsionForce = max(0, maxRepulsionDistance - deltaDistance) /
              maxRepulsionDistance; //value between 0-1
          var repulsionVector = delta * repulsionForce * repulsionRate;

          displacement[currentNode] =
              displacement[currentNode]! + repulsionVector;
          displacement[otherNode] = displacement[otherNode]! - repulsionVector;
        }
      }
    }
  }

  // Calculate closest distance vector between two node rectangles using cached rects
  Offset _getNodeRectDistance(Node nodeA, Node nodeB) {
    final rectA = nodeRects[nodeA]!;
    final rectB = nodeRects[nodeB]!;

    final centerA = rectA.center;
    final centerB = rectB.center;

    if (rectA.overlaps(rectB)) {
      // Push overlapping nodes apart by at least half their combined size
      final dx =
          (centerA.dx - centerB.dx).sign * (rectA.width / 2 + rectB.width / 2);
      final dy = (centerA.dy - centerB.dy).sign *
          (rectA.height / 2 + rectB.height / 2);
      return Offset(dx, dy);
    }

    // Non-overlapping: distance along nearest edges
    final dx = (centerA.dx < rectB.left)
        ? (rectB.left - rectA.right)
        : (centerA.dx > rectB.right)
            ? (rectA.left - rectB.right)
            : 0.0;

    final dy = (centerA.dy < rectB.top)
        ? (rectB.top - rectA.bottom)
        : (centerA.dy > rectB.bottom)
            ? (rectA.top - rectB.bottom)
            : 0.0;

    return Offset(dx == 0 ? centerA.dx - centerB.dx : dx,
        dy == 0 ? centerA.dy - centerB.dy : dy);
  }

  bool step(Graph graph) {
    var moved = false;
    displacement = {};
    for (var node in graph.nodes) {
      displacement[node] = Offset.zero;
    }

    calculateRepulsion(graph.nodes);
    calculateAttraction(graph.edges);

    for (var node in graph.nodes) {
      final nodeDisplacement = displacement[node]!;
      if (nodeDisplacement.distance > configuration.movementThreshold) {
        moved = true;
      }
    }

    moveNodes(graph);
    return moved;
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null) {
      return Size.zero;
    }
    var size = findBiggestSize(graph) * graph.nodeCount();
    graphWidth = size;
    graphHeight = size;

    var nodes = graph.nodes;
    var edges = graph.edges;

    tick = DEFAULT_TICK_FACTOR * sqrt(graphWidth / 2 * graphHeight / 2);

    if (graph.nodes.any((node) => node.position == Offset.zero)) {
      init(graph);
    }

    for (var i = 0; i < configuration.iterations; i++) {
      calculateRepulsion(nodes);
      calculateAttraction(edges);
      limitMaximumDisplacement(nodes);

      cool(i);

      if (done()) {
        break;
      }
    }

    positionNodes(graph);

    shiftCoordinates(graph, shiftX, shiftY);

    return graph.calculateGraphSize();
  }

  void shiftCoordinates(Graph graph, double shiftX, double shiftY) {
    graph.nodes.forEach((node) {
      node.position = Offset(node.x + shiftX, node.y + shiftY);
      // Update cached rect after position change
      nodeRects[node] = Rect.fromLTWH(node.x, node.y, node.width, node.height);
    });
  }

  void positionNodes(Graph graph) {
    var offset = getOffset(graph);
    var x = offset.dx;
    var y = offset.dy;
    var nodesVisited = <Node>[];
    var nodeClusters = <NodeCluster>[];
    graph.nodes.forEach((node) {
      node.position = Offset(node.x - x, node.y - y);
      // Update cached rect after position change
      nodeRects[node] = Rect.fromLTWH(node.x, node.y, node.width, node.height);
    });

    graph.nodes.forEach((node) {
      if (!nodesVisited.contains(node)) {
        nodesVisited.add(node);
        var cluster = findClusterOf(nodeClusters, node);
        if (cluster == null) {
          cluster = NodeCluster();
          cluster.add(node);
          nodeClusters.add(cluster);
        }

        followEdges(graph, cluster, node, nodesVisited);
      }
    });

    positionCluster(nodeClusters);
  }

  void positionCluster(List<NodeCluster> nodeClusters) {
    combineSingleNodeCluster(nodeClusters);

    var cluster = nodeClusters[0];
    // move first cluster to 0,0
    cluster.offset(-cluster.rect!.left, -cluster.rect!.top);

    for (var i = 1; i < nodeClusters.length; i++) {
      var nextCluster = nodeClusters[i];
      var xDiff = nextCluster.rect!.left -
          cluster.rect!.right -
          configuration.clusterPadding;
      var yDiff = nextCluster.rect!.top - cluster.rect!.top;
      nextCluster.offset(-xDiff, -yDiff);
      cluster = nextCluster;
    }
  }

  void combineSingleNodeCluster(List<NodeCluster> nodeClusters) {
    NodeCluster? firstSingleNodeCluster;

    nodeClusters.forEach((cluster) {
      if (cluster.size() == 1) {
        if (firstSingleNodeCluster == null) {
          firstSingleNodeCluster = cluster;
        } else {
          firstSingleNodeCluster!.concat(cluster);
        }
      }
    });

    nodeClusters.removeWhere((element) => element.size() == 1);
  }

  void followEdges(
      Graph graph, NodeCluster cluster, Node node, List nodesVisited) {
    graph.successorsOf(node).forEach((successor) {
      if (!nodesVisited.contains(successor)) {
        nodesVisited.add(successor);
        cluster.add(successor);

        followEdges(graph, cluster, successor, nodesVisited);
      }
    });

    graph.predecessorsOf(node).forEach((predecessor) {
      if (!nodesVisited.contains(predecessor)) {
        nodesVisited.add(predecessor);
        cluster.add(predecessor);

        followEdges(graph, cluster, predecessor, nodesVisited);
      }
    });
  }

  NodeCluster? findClusterOf(List<NodeCluster> clusters, Node node) {
    return clusters.firstWhereOrNull((element) => element.contains(node));
  }

  double findBiggestSize(Graph graph) {
    return graph.nodes.map((it) => max(it.height, it.width)).reduce(max);
  }

  Offset getOffset(Graph graph) {
    var offsetX = double.infinity;
    var offsetY = double.infinity;

    graph.nodes.forEach((node) {
      offsetX = min(offsetX, node.x);
      offsetY = min(offsetY, node.y);
    });

    return Offset(offsetX, offsetY);
  }

  bool done() {
    return tick < CONVERGENCE_THRESHOLD / max(graphHeight, graphWidth);
  }

  void drawEdges(Canvas canvas, Graph graph, Paint linePaint) {}

  @override
  void setDimensions(double width, double height) {
    graphWidth = width;
    graphHeight = height;
  }
}

class NodeCluster {
  List<Node> nodes;
  Rect? rect;

  List<Node> getNodes() {
    return nodes;
  }

  Rect? getRect() {
    return rect;
  }

  void setRect(Rect newRect) {
    this.rect = newRect;
  }

  void add(Node node) {
    nodes.add(node);

    if (nodes.length == 1) {
      rect = Rect.fromLTRB(
          node.x, node.y, node.x + node.width, node.y + node.height);
    } else {
      rect = Rect.fromLTRB(
          min(rect!.left, node.x),
          min(rect!.top, node.y),
          max(rect!.right, node.x + node.width),
          max(rect!.bottom, node.y + node.height));
    }
  }

  bool contains(Node node) {
    return nodes.contains(node);
  }

  int size() {
    return nodes.length;
  }

  void concat(NodeCluster cluster) {
    cluster.nodes.forEach((node) {
      node.position = (Offset(
          rect!.right +
              FruchtermanReingoldConfiguration.DEFAULT_CLUSTER_PADDING,
          rect!.top));
      add(node);
    });
  }

  void offset(double xDiff, double yDiff) {
    nodes.forEach((node) {
      node.position = (node.position + Offset(xDiff, yDiff));
    });

    rect = rect!.translate(xDiff, yDiff);
  }

  NodeCluster()
      : nodes = <Node>[],
        rect = Rect.zero;
}
