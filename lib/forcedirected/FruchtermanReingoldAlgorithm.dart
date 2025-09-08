part of graphview;

class FruchtermanReingoldAlgorithm implements Algorithm {
  Map<Node, Offset> displacement = {};
  Random rand = Random();
  double graphHeight = 500; //default value, change ahead of time
  double graphWidth = 500;
  late double tick;

  FruchtermanReingoldConfiguration configuration;

  @override
  EdgeRenderer? renderer;

  FruchtermanReingoldAlgorithm(this.configuration,
      {this.renderer}) {
    this.configuration = configuration;
    this.renderer = renderer ?? ArrowEdgeRenderer();
  }

  @override
  void init(Graph? graph) {
    graph!.nodes.forEach((node) {
      displacement[node] = Offset.zero;

      if(configuration.shuffleNodes) {
        node.position = Offset(
            rand.nextDouble() * graphWidth, rand.nextDouble() * graphHeight);
      }
    });

  }

  void moveNodes(Graph graph) {
    final lerpFactor = configuration.lerpFactor;

    graph.nodes.forEach((node) {
      var target = node.position + displacement[node]!;
      var newPosition = Offset.lerp(node.position, target, lerpFactor)!;
      double newDX = min(graphWidth - node.size.width * 0.5, max(node.size.width * 0.5 , newPosition.dx));
      double newDY = min(graphHeight - node.size.height *0.5, max(node.size.height * 0.5, newPosition.dy));

      node.position = Offset(newDX, newDY);
    });
  }

  void cool(int currentIteration) {
    tick *= 1.0 - currentIteration / configuration.iterations;
  }

  void limitMaximumDisplacement(List<Node> nodes) {
    final epsilon = configuration.epsilon;

    nodes.forEach((node) {
      var dispLength = max(epsilon, displacement[node]!.distance);
      node.position += displacement[node]! / dispLength * min(dispLength, tick);
    });
  }

  void calculateAttraction(List<Edge> edges) {
    final attractionRate = configuration.attractionRate;
    final attractionPercentage = configuration.attractionPercentage;
    final epsilon = configuration.epsilon;

    edges.forEach((edge) {
      var source = edge.source;
      var destination = edge.destination;
      var delta = source.position - destination.position;
      var deltaDistance = max(epsilon, delta.distance);
      var maxAttractionDistance = min(graphWidth * attractionPercentage, graphHeight * attractionPercentage);
      var attractionForce = min(0, (maxAttractionDistance - deltaDistance)).abs() / (maxAttractionDistance * 2);
      var attractionVector = delta * attractionForce * attractionRate;

      displacement[source] = displacement[source]! - attractionVector;
      displacement[destination] = displacement[destination]! + attractionVector;
    });
  }

  void calculateRepulsion(List<Node> nodes) {
    final repulsionRate = configuration.repulsionRate;
    final repulsionPercentage = configuration.repulsionPercentage;
    final epsilon = configuration.epsilon;

    final nodeCount = nodes.length.toDouble();

    for (var i = 0; i < nodeCount; i++) {
      final nodeA = nodes[i];

      for (var j = i + 1; j < nodeCount; j++) {
        final nodeB = nodes[j];
        if (nodeA != nodeB) {
          var delta = nodeA.position - nodeB.position;
          var deltaDistance = max(epsilon, delta.distance); //protect for 0
          var maxRepulsionDistance = min(graphWidth * repulsionPercentage, graphHeight * repulsionPercentage);
          var repulsionForce = max(0, maxRepulsionDistance - deltaDistance) / maxRepulsionDistance; //value between 0-1
          var repulsionVector = delta * repulsionForce * repulsionRate;

          displacement[nodeA] = displacement[nodeA]! + repulsionVector;
        }
      }
    }

    nodes.forEach((nodeA) {
      displacement[nodeA] = displacement[nodeA]! / nodeCount;
    });
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
      final delta = displacement[node]!;
      if (delta.distance > configuration.movementThreshold) {
        moved = true;
      }
    }

    moveNodes(graph);
    return moved;
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    var size = findBiggestSize(graph!) * graph.nodeCount();
    graphWidth = size;
    graphHeight = size;

    var nodes = graph.nodes;
    var edges = graph.edges;

    tick = 0.1 * sqrt(graphWidth / 2 * graphHeight / 2);

    init(graph);

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

    return calculateGraphSize(graph);
  }

  void shiftCoordinates(Graph graph, double shiftX, double shiftY) {
    graph.nodes.forEach((node) {
      node.position = Offset(node.x + shiftX, node.y + shiftY);
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
      var xDiff = nextCluster.rect!.left - cluster.rect!.right - configuration.clusterPadding;
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

  void followEdges(Graph graph, NodeCluster cluster, Node node, List nodesVisited) {
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
    return tick < 1.0 / max(graphHeight, graphWidth);
  }

  void drawEdges(Canvas canvas, Graph graph, Paint linePaint) {}

  Size calculateGraphSize(Graph graph) {
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;

    graph.nodes.forEach((node) {
      left = min(left, node.x);
      top = min(top, node.y);
      right = max(right, node.x + node.width);
      bottom = max(bottom, node.y + node.height);
    });

    return Size(right - left, bottom - top);
  }

  @override
  void setDimensions(double width, double height) {
    graphWidth = width;
    graphHeight = height;
  }
}

class NodeCluster {
  List<Node>? nodes;
  Rect? rect;

  List<Node>? getNodes() {
    return nodes;
  }

  Rect? getRect() {
    return rect;
  }

  void setRect(Rect rect) {
    rect = rect;
  }

  void add(Node node) {
    nodes!.add(node);

    if (nodes!.length == 1) {
      rect = Rect.fromLTRB(node.x, node.y, node.x + node.width, node.y + node.height);
    } else {
      rect = Rect.fromLTRB(
          min(rect!.left, node.x),
          min(rect!.top, node.y),
          max(rect!.right, node.x + node.width),
          max(rect!.bottom, node.y + node.height));
    }
  }

  bool contains(Node node) {
    return nodes!.contains(node);
  }

  int size() {
    return nodes!.length;
  }

  void concat(NodeCluster cluster) {
    cluster.nodes!.forEach((node) {
      node.position = (Offset(rect!.right + FruchtermanReingoldConfiguration.DEFAULT_CLUSTER_PADDING, rect!.top));
      add(node);
    });
  }

  void offset(double xDiff, double yDiff) {
    nodes!.forEach((node) {
      node.position = (node.position + Offset(xDiff, yDiff));
    });

    rect = rect!.translate(xDiff, yDiff);
  }

  NodeCluster() {
    nodes = [];
    rect = Rect.zero;
  }
}