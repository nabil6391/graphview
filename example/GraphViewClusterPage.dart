
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/ArrowEdgeRenderer.dart';
import 'package:graphview/FruchtermanReingoldAlgorithm.dart';
import 'package:graphview/Graph.dart';
import 'package:graphview/GraphView.dart';
import 'package:graphview/Layout.dart';

class GraphClusterViewPage extends StatefulWidget {
  @override
  _GraphClusterViewPageState createState() => _GraphClusterViewPageState();
}

class _GraphClusterViewPageState extends State<GraphClusterViewPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: Column(
        children: [
          RaisedButton(
            onPressed: () {
              final Node node12 = Node(getNodeText());
              graph.addEdge(graph.getNodeAtPosition(r.nextInt(graph.nodeCount())), node12);
              setState(() {});
            },
            child: Text("Add"),
          ),
          Expanded(
            child: InteractiveViewer(
                constrained: false,
                boundaryMargin: EdgeInsets.all(8),
                minScale: 0.01,
                maxScale: 5.6,
                child: GraphView(
                  graph: graph,
                  algorithm: builder,
                  renderer: ArrowEdgeRenderer(),
                )),
          ),
        ],
      )),
    );
  }

  int n = 1;
  Random r = Random();

  Widget getNodeText() {
    return Container(color: Colors.green, child: Text("Node ${n++}"));
  }

  final Graph graph = Graph();
  Layout builder;

  @override
  void initState() {
    final Node a = new Node(getNodeText());
    final Node b = new Node(getNodeText());
    final Node c = new Node(getNodeText());
    final Node d = new Node(getNodeText());
    final Node e = new Node(getNodeText());
    final Node f = new Node(getNodeText());
    final Node g = new Node(getNodeText());
    final Node h = new Node(getNodeText());

    graph.addEdge(a, b);
    graph.addEdge(a, c);
    graph.addEdge(a, d);
    graph.addEdge(c, e);
    graph.addEdge(d, f);
    graph.addEdge(f, c);
    graph.addEdge(g, c);
    graph.addEdge(h, g);

    builder = FruchtermanReingoldAlgorithm(1000);
  }
}
