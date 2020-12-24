import 'dart:math';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class GraphChangeNotifier extends ChangeNotifier {
  Graph graph = Graph();
  String graphType = "tree";
  Map<Node, Offset> displacement = {};
  double repulsionRate = .5;
  double attractionRate = .05;
  double repulsionPercentage = 0.4;
  double attractionPercentage = 0.15;
  double edgePadding = 50;
  double graphHeight = 500; //default value, change ahead of time
  double graphWidth = 500;

  void setupGraph() {
    graph = new Graph();
    if (graphType == "tree") {
      Node node1 = Node(createNode("One"));
      Node node2 = Node(createNode("Two"));
      Node node3 = Node(createNode("Three"));
      Node node4 = Node(createNode("Four"));
      Node node5 = Node(createNode("Five"));
      Node node6 = Node(createNode("Six"));
      Node node7 = Node(createNode("Seven"));
      Node node8 = Node(createNode("Eight"));
      Node node9 = Node(createNode("Nine"));
      Node node10 = Node(createNode("Ten"));
      Node node11 = Node(createNode("Eleven"));
      Node node12 = Node(createNode("Twelve"));
      Node node13 = Node(createNode("Thirteen"));

      graph.addEdge(node1, node2);
      graph.addEdge(node1, node3);
      graph.addEdge(node1, node4);
      graph.addEdge(node2, node5);
      graph.addEdge(node2, node6);
      graph.addEdge(node2, node7);
      graph.addEdge(node3, node8);
      graph.addEdge(node3, node9);
      graph.addEdge(node3, node10);
      graph.addEdge(node4, node11);
      graph.addEdge(node4, node12);
      graph.addEdge(node4, node13);
    } else if (graphType == "square") {
      Node node1 = Node(createNode("One"));
      Node node2 = Node(createNode("Two"));
      Node node3 = Node(createNode("Three"));
      Node node4 = Node(createNode("Four"));
      Node node5 = Node(createNode("Five"));
      Node node6 = Node(createNode("Six"));
      Node node7 = Node(createNode("Seven"));
      Node node8 = Node(createNode("Eight"));
      Node node9 = Node(createNode("Nine"));
      graph.addEdge(node1, node2);
      graph.addEdge(node1, node4);
      graph.addEdge(node2, node3);
      graph.addEdge(node2, node5);
      graph.addEdge(node3, node6);
      graph.addEdge(node4, node5);
      graph.addEdge(node4, node7);
      graph.addEdge(node5, node6);
      graph.addEdge(node5, node8);
      graph.addEdge(node6, node9);
      graph.addEdge(node7, node8);
      graph.addEdge(node8, node9);
    } else if (graphType == "triangle") {
      Node node1 = Node(createNode("One"));
      Node node2 = Node(createNode("Two"));
      Node node3 = Node(createNode("Three"));
      Node node4 = Node(createNode("Four"));
      Node node5 = Node(createNode("Five"));
      Node node6 = Node(createNode("Six"));
      Node node7 = Node(createNode("Seven"));
      Node node8 = Node(createNode("Eight"));
      Node node9 = Node(createNode("Nine"));
      Node node10 = Node(createNode("Ten"));

      graph.addEdge(node1, node2);
      graph.addEdge(node1, node3);
      graph.addEdge(node2, node4);
      graph.addEdge(node2, node5);
      graph.addEdge(node2, node3);
      graph.addEdge(node3, node5);
      graph.addEdge(node3, node6);
      graph.addEdge(node4, node7);
      graph.addEdge(node4, node8);
      graph.addEdge(node4, node5);
      graph.addEdge(node5, node8);
      graph.addEdge(node5, node9);
      graph.addEdge(node5, node6);
      graph.addEdge(node9, node6);
      graph.addEdge(node10, node6);
      graph.addEdge(node7, node8);
      graph.addEdge(node8, node9);
      graph.addEdge(node9, node10);
    }

    setNodeInitialPositions();
  }

  void setNodeInitialPositions() {
    for (Node node in graph.nodes) {
      node.position = Offset(Random().nextDouble() * graphWidth,
          Random().nextDouble() * graphHeight);
    }
    for (Node node in graph.nodes) {
      displacement[node] = Offset.zero;
    }
    moveNodes();
  }

  void step() {
    displacement = {};
    for (Node node in graph.nodes) {
      displacement[node] = Offset.zero;
    }
    calculateRepulsion();
    calculateAttraction();
    moveNodes();
  }

  void calculateRepulsion() {
    //every node repels each other node
    for (Node nodeA in graph.nodes) {
      for (Node nodeB in graph.nodes) {
        if (nodeA != nodeB) {
          Offset delta = nodeA.position - nodeB.position;
          double deltaDistance = max(EPSILON, delta.distance); //protect for 0
          double maxRepulsionDistance = min(graphWidth * repulsionPercentage,
              graphHeight * repulsionPercentage);
          double repulsionForce = max(0, maxRepulsionDistance - deltaDistance) /
              maxRepulsionDistance; //value between 0-1
          Offset repulsionVector = (delta * (repulsionForce * repulsionRate));
          displacement[nodeA] += repulsionVector;
        }
      }
    }
    for (Node node in graph.nodes) {
      displacement[node] = displacement[node] / graph.nodeCount().toDouble();
    }
  }

  void calculateAttraction() {
    //connected nodes attract one another
    for (Edge edge in graph.edges) {
      Node nodeA = edge.source;
      Node nodeB = edge.destination;
      Offset delta = nodeA.position - nodeB.position;
      double deltaDistance = max(EPSILON, delta.distance); //protect for 0
      double maxAttractionDistance = min(graphWidth * attractionPercentage,
          graphHeight * attractionPercentage);
      double attractionForce =
          min(0, (maxAttractionDistance - deltaDistance)).abs() /
              (maxAttractionDistance * 2);
      Offset attractionVector = (delta * (attractionForce * attractionRate));
      displacement[nodeA] -= attractionVector;
      displacement[nodeB] += attractionVector;
    }
  }

  void moveNodes() {
    for (Node node in graph.nodes) {
      Offset newPosition = node.position += displacement[node];
      double newDX = newPosition.dx;
      double newDY = newPosition.dy;
      newDX = max(0, newDX);
      newDY = max(0, newDY);
      newDX = min(graphWidth - 40, newDX);
      newDY = min(graphHeight - 40 - AppBar().preferredSize.height, newDY);
      node.position = Offset(newDX, newDY);
    }
  }

  Future<void> update() async {
    notifyListeners();
  }

  Widget createNode(String nodeText) {
    return GestureDetector(
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red,
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            nodeText,
            style: TextStyle(fontSize: 10),
          ),
        ),
      ),
      onLongPress: () {
        print(nodeText);
      },
    );
  }
}
