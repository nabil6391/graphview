import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class GraphClusterViewPage extends StatefulWidget {
  @override
  _GraphClusterViewPageState createState() => _GraphClusterViewPageState();
}

class _GraphClusterViewPageState extends State<GraphClusterViewPage> {
  late Timer timer;
  final stepMilis = 25;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Column(
          children: [
            Expanded(
              child: GraphView.builder(
                  graph: graph,
                  algorithm: builder,
                  paint: Paint()
                    ..color = Colors.green
                    ..strokeWidth = 1
                    ..style = PaintingStyle.fill,
                  builder: (Node node) {
                    // I can decide what widget should be shown here based on the id
                    var a = node.key!.value as int?;
                    if (a == 2) {
                      return rectangWidget(a);
                    }
                    return rectangWidget(a);
                  }),
            ),
          ],
        ));
  }

  int n = 8;
  Random r = Random();

  Widget rectangWidget(int? i) {
    return GestureDetector(
      onPanUpdate: (details) {
        // Find the node and update its position
        final node = graph.nodes.firstWhere((n) => (n.key?.value as int?) == i);
        setState(() {
          node.position = Offset(
            node.position.dx + details.delta.dx,
            node.position.dy + details.delta.dy,
          );
          startAnimation();
        });
      },
      child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.blue, spreadRadius: 1),
            ],
          ),
          child: Text('Node $i')),
    );
  }

  final Graph graph = Graph();
  late FruchtermanReingoldAlgorithm builder;

  @override
  void initState() {
    super.initState();

    final a = Node.Id(1);
    final b = Node.Id(2);
    final c = Node.Id(3);
    final d = Node.Id(4);
    final e = Node.Id(5);
    final f = Node.Id(6);
    final g = Node.Id(7);
    final h = Node.Id(8);

    graph.addEdge(a, b, paint: Paint()..color = Colors.red);
    graph.addEdge(a, c);
    graph.addEdge(a, d);
    graph.addEdge(c, e);
    graph.addEdge(d, f);
    graph.addEdge(f, c);
    graph.addEdge(g, c);
    graph.addEdge(h, g);

    var config = FruchtermanReingoldConfiguration()
      ..iterations = 1000;
    builder = FruchtermanReingoldAlgorithm(config);

    // Initialize and start the animation timer
    builder.init(graph);
    startAnimation();
  }

  bool isAnimating = false;

  void startAnimation() {
    if (isAnimating) return; // already running
    isAnimating = true;

    timer = Timer.periodic(Duration(milliseconds: stepMilis), (t) {
      final moved = builder.step(graph);
      if (!moved) {
        t.cancel();
        isAnimating = false;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}
