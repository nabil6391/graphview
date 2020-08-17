
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class GraphClusterViewPage extends StatefulWidget {
  @override
  _GraphClusterViewPageState createState() => _GraphClusterViewPageState();
}

class _GraphClusterViewPageState extends State<GraphClusterViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: [
            RaisedButton(
              onPressed: () {
                final node12 = Node(getNodeText());
                graph.addEdge(graph.getNodeAtPosition(r.nextInt(graph.nodeCount())), node12);
                setState(() {});
              },
              child: Text('Add'),
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
                  )),
            ),
          ],
        ));
  }

  int n = 1;
  Random r = Random();

  Widget getNodeText() {
    return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.blue[100], spreadRadius: 1),
          ],
        ),
        child: Text("Node ${n++}"));
  }

  final Graph graph = Graph();
  Layout builder;

  @override
  void initState() {
    final a =  Node(getNodeText());
    final b =  Node(getNodeText());
    final c =  Node(getNodeText());
    final d =  Node(getNodeText());
    final e =  Node(getNodeText());
    final f =  Node(getNodeText());
    final g =  Node(getNodeText());
    final h =  Node(getNodeText());

    graph.addEdge(a, b);
    graph.addEdge(a, c);
    graph.addEdge(a, d);
    graph.addEdge(c, e);
    graph.addEdge(d, f);
    graph.addEdge(f, c);
    graph.addEdge(g, c);
    graph.addEdge(h, g);

    builder = FruchtermanReingoldAlgorithm(iterations: 1000);
  }
}
