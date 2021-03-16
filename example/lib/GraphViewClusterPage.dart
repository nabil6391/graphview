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
        Expanded(
          child: InteractiveViewer(
              constrained: false,
              boundaryMargin: EdgeInsets.all(8),
              minScale: 0.001,
              maxScale: 100,
              child: GraphView(
                graph: graph,
                algorithm: builder,
                paint: Paint()
                  ..color = Colors.green
                  ..strokeWidth = 1
                  ..style = PaintingStyle.fill,
              )),
        ),
      ],
    ));
  }

  int n = 8;
  Random r = Random();

  Widget getNodeText(int i) {
    return GestureDetector(
      onLongPressStart: (details) {
        var x = details.globalPosition.dx;
        var y = details.globalPosition.dy;
        Offset(x, y);
      },
      onPanStart: (details) {
        var x = details.globalPosition.dx;
        var y = details.globalPosition.dy;
        setState(() {
          builder.setFocusedNode(graph.getNodeAtPosition(i - 1));
          graph.getNodeAtPosition(i - 1).position = Offset(x, y);
        });
      },
      onPanUpdate: (details) {
        var x = details.globalPosition.dx;
        var y = details.globalPosition.dy;
        setState(() {
          builder.setFocusedNode(graph.getNodeAtPosition(i - 1));
          graph.getNodeAtPosition(i - 1).position = Offset(x, y);
        });
      },
      onPanEnd: (details) {
        builder.setFocusedNode(null);
      },
      child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.blue[100], spreadRadius: 1),
            ],
          ),
          child: Text('Node $i')),
    );
  }

  final Graph graph = Graph();
  Layout builder;

  @override
  void initState() {
    final a = Node(getNodeText(1));
    final b = Node(getNodeText(2));
    final c = Node(getNodeText(3));
    final d = Node(getNodeText(4));
    final e = Node(getNodeText(5));
    final f = Node(getNodeText(6));
    final g = Node(getNodeText(7));
    final h = Node(getNodeText(8));

    graph.addEdge(a, b, paint: Paint()..color = Colors.red);
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
