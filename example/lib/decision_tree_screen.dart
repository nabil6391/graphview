import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class DecisionTreeScreen extends StatefulWidget {
  @override
  _DecisionTreeScreenState createState() => _DecisionTreeScreenState();
}

class _DecisionTreeScreenState extends State<DecisionTreeScreen> {
  final _graph = Graph()..isTree = true;

  final _configuration = SugiyamaConfiguration()
    ..orientation = 1
    ..nodeSeparation = 40
    ..levelSeparation = 50;

  @override
  void initState() {
    super.initState();

    _graph.addEdge(Node.Id(1), Node.Id(2));
    _graph.addEdge(Node.Id(2), Node.Id(3));
    _graph.addEdge(Node.Id(2), Node.Id(11));
    _graph.addEdge(Node.Id(3), Node.Id(4));
    _graph.addEdge(Node.Id(4), Node.Id(5));

    _graph.addEdge(Node.Id(1), Node.Id(6));
    _graph.addEdge(Node.Id(6), Node.Id(7));
    _graph.addEdge(Node.Id(7), Node.Id(3));

    _graph.addEdge(Node.Id(1), Node.Id(10));
    _graph.addEdge(Node.Id(10), Node.Id(11));
    _graph.addEdge(Node.Id(11), Node.Id(7));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: InteractiveViewer(
        minScale: 0.1,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(64),
        child: GraphView(
          graph: _graph,
          algorithm: SugiyamaAlgorithm(_configuration),
          builder: (node) {
            final id = node.key!.value as int;

            final text = List.generate(id == 1 || id == 4 ? 500 : 10, (index) => 'X').join(' ');

            return Container(
              width: 180,
              decoration: BoxDecoration(
                color: Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
                border: Border.all(width: 2),
              ),
              padding: const EdgeInsets.all(16),
              child: Text('$id $text'),
            );
          },
        ),
      ),
    );
  }
}
