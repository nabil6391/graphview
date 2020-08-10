library graphview;

import 'dart:math';
import 'dart:ui';

import 'Graph.dart';
import 'Layout.dart';

const int DEFAULT_ITERATIONS = 1000;
const int SEED = 401678;
const int CLUSTER_PADDING = 100;
const double EPSILON = 4.94065645841247E-324;

class FruchtermanReingoldAlgorithm extends Layout {
  Map<Node, Offset> disps = Map();
  Random rand = Random();
  double width;
  double height;
  double k;
  double t;
  double attraction_k;
  double repulsion_k;
  int iterations;

  FruchtermanReingoldAlgorithm([this.iterations = DEFAULT_ITERATIONS]);

  void randomize(List<Node> nodes) {
    nodes.forEach((node) {
      disps[node] = Offset.zero;
      node.position = Offset(randInt(rand, 0, width / 2), randInt(rand, 0, height / 2));
    });
  }

  void cool(int currentIteration) {
    this.t *= 1.0 - currentIteration / this.iterations;
  }

  void limitMaximumDisplacement(List<Node> nodes) {
    nodes.forEach((node) {
      var dispLength = max(EPSILON, getDisp(node).distance.toDouble());
      node.position = (node.position + (getDisp(node) / dispLength) * (min(dispLength, t)));
    });
  }

  void calculateAttraction(List<Edge> edges) {
    edges.forEach((edge) {
      Node v = edge.source;
      Node u = edge.destination;
      Offset delta = v.position - (u.position);
      var deltaLength = max(EPSILON, delta.distance.toDouble());
      setDisp(v, getDisp(v) - (delta / (deltaLength) * (forceAttraction(deltaLength))));
      setDisp(u, getDisp(u) + (delta / (deltaLength) * (forceAttraction(deltaLength))));
    });
  }

  void calculateRepulsion(List<Node> nodes) {
    nodes.forEach((v) {
      nodes.forEach((u) {
        if (u != v) {
          Offset delta = v.position - (u.position);
          var deltaLength = max(EPSILON, delta.distance.toDouble());
          setDisp(v, getDisp(v) + (delta / (deltaLength) * (forceRepulsion(deltaLength))));
        }
      });
    });
  }

  double forceAttraction(double x) {
    return x * x / this.attraction_k;
  }

  double forceRepulsion(double x) {
    return repulsion_k * this.repulsion_k / x;
  }

  Offset getDisp(Node node) {
    return disps[node];
  }

  void setDisp(Node node, Offset disp) {
    this.disps[node] = disp;
  }

  Size run(Graph graph, double shiftX, double shiftY) {
    var size = findBiggestSize(graph) * graph.nodeCount();
    width = size;
    height = size;

    var nodes = graph.nodes;
    var edges = graph.edges;

    t = (0.1 * sqrt((width / 2 * height / 2).toDouble()));
    k = (0.75 * sqrt((width * height / nodes.length).toDouble()));

    attraction_k = 0.75 * k;
    repulsion_k = 0.75 * k;

    randomize(nodes);

    for (int i = 0; i < iterations; i++) {
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
    List<Node> nodesVisited = [];
    List<NodeCluster> nodeClusters = [];
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

    NodeCluster cluster = nodeClusters[0];
// move first cluster to 0,0
    cluster.offset(-cluster.rect.left, -cluster.rect.top);

    for (int i = 1; i < nodeClusters.length; i++) {
      var nextCluster = nodeClusters[i];
      var xDiff = nextCluster.rect.left - cluster.rect.right - CLUSTER_PADDING;
      var yDiff = nextCluster.rect.top - cluster.rect.top;
      nextCluster.offset(-xDiff, -yDiff);
      cluster = nextCluster;
    }
  }

  void combineSingleNodeCluster(List<NodeCluster> nodeClusters) {
    NodeCluster firstSingleNodeCluster;

    nodeClusters.forEach((cluster) {
      if (cluster.size() == 1) {
        if (firstSingleNodeCluster == null) {
          firstSingleNodeCluster = cluster;
        } else {
          firstSingleNodeCluster.concat(cluster);
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

  NodeCluster findClusterOf(List<NodeCluster> clusters, Node node) {
    return clusters.firstWhere((element) => element.contains(node), orElse: () => null);
  }

  double findBiggestSize(Graph graph) {
    return graph.nodes.map((it) => max(it.height, it.width)).reduce(max) ?? 0;
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
    return t < 1.0 / max(height, width);
  }

  void drawEdges(Canvas canvas, Graph graph, Paint linePaint) {}

  Size calculateGraphSize(Graph graph) {
    var left = double.infinity;
    var top = double.infinity;
    var right = -double.infinity;
    var bottom = -double.infinity;

    graph.nodes.forEach((node) {
      left = min(left, node.x);
      top = min(top, node.y);
      right = max(right, node.x + node.width);
      bottom = max(bottom, node.y + node.height);
    });

    return Size(right - left, bottom - top);
  }

  @override
  get configuration => throw UnimplementedError();
}

class NodeCluster {
  List<Node> nodes;

  Rect rect;

  List<Node> getNodes() {
    return this.nodes;
  }

  Rect getRect() {
    return this.rect;
  }

  void setRect(Rect var1) {
    this.rect = var1;
  }

  void add(Node node) {
    nodes.add(node);

    if (nodes.length == 1) {
      rect = Rect.fromLTRB(node.x, node.y, node.x + node.width, node.y + node.height);
    } else {
      rect = Rect.fromLTRB(min(rect.left, node.x), min(rect.top, node.y), max(rect.right, node.x + node.width),
          max(rect.bottom, node.y + node.height));
    }
  }

  bool contains(Node node) {
    return this.nodes.contains(node);
  }

  int size() {
    return this.nodes.length;
  }

  void concat(NodeCluster cluster) {
    cluster.nodes.forEach((node) {
      node.position = (Offset(rect.right + CLUSTER_PADDING, rect.top));
      add(node);
    });
  }

  void offset(double xDiff, double yDiff) {
    nodes.forEach((node) {
      node.position = (node.position + Offset(xDiff, yDiff));
    });

    rect.translate(xDiff, yDiff);
  }

  NodeCluster() {
    this.nodes = [];
    this.rect = Rect.zero;
  }
}

double randInt(Random rand, int min, num max) {
  return (rand.nextInt(max.toInt() - min + 1).toDouble() + min).toDouble();
}
