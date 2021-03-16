import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class LayeredGraphViewPage extends StatefulWidget {
  @override
  _LayeredGraphViewPageState createState() => _LayeredGraphViewPageState();
}

class _LayeredGraphViewPageState extends State<LayeredGraphViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Wrap(
          children: [
            Container(
              width: 100,
              child: TextFormField(
                initialValue: builder.nodeSeparation.toString(),
                decoration: InputDecoration(labelText: 'Node Separation'),
                onChanged: (text) {
                  builder.nodeSeparation = int.tryParse(text) ?? 100;
                  setState(() {});
                },
              ),
            ),
            Container(
              width: 100,
              child: TextFormField(
                initialValue: builder.levelSeparation.toString(),
                decoration: InputDecoration(labelText: 'Level Separation'),
                onChanged: (text) {
                  builder.levelSeparation = int.tryParse(text) ?? 100;
                  setState(() {});
                },
              ),
            ),
            Container(
              width: 100,
              child: TextFormField(
                initialValue: builder.orientation.toString(),
                decoration: InputDecoration(labelText: 'Orientation'),
                onChanged: (text) {
                  builder.orientation = int.tryParse(text) ?? 100;
                  setState(() {});
                },
              ),
            ),
            RaisedButton(
              onPressed: () {
                final node12 = Node(getNodeText());
                var edge =
                    graph.getNodeAtPosition(r.nextInt(graph.nodeCount()));
                print(edge);
                graph.addEdge(edge, node12);
                setState(() {});
              },
              child: Text('Add'),
            )
          ],
        ),
        Expanded(
          child: InteractiveViewer(
              constrained: false,
              boundaryMargin: EdgeInsets.all(100),
              minScale: 0.0001,
              maxScale: 10.6,
              child: GraphView(
                graph: graph,
                algorithm: SugiyamaAlgorithm(builder),
                paint: Paint()
                  ..color = Colors.green
                  ..strokeWidth = 1
                  ..style = PaintingStyle.stroke,
              )),
        ),
      ],
    ));
  }

  Random r = Random();

  int n = 1;

  Widget getNodeText() {
    return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.blue[100], spreadRadius: 1),
          ],
        ),
        child: Text('Node ${n++}'));
  }

  final Graph graph = Graph();

  SugiyamaConfiguration builder = SugiyamaConfiguration();

  @override
  void initState() {
    final node1 = Node(getNodeText());
    final node2 = Node(getNodeText());
    final node3 = Node(getNodeText());
    final node4 = Node(getNodeText());
    final node5 = Node(getNodeText());
    final node6 = Node(getNodeText());
    final node8 = Node(getNodeText());
    final node7 = Node(getNodeText());
    final node9 = Node(getNodeText());
    final node10 = Node(getNodeText());
    final node11 = Node(getNodeText());
    final node12 = Node(getNodeText());
    final node13 = Node(getNodeText());
    final node14 = Node(getNodeText());
    final node15 = Node(getNodeText());
    final node16 = Node(getNodeText());
    final node17 = Node(getNodeText());
    final node18 = Node(getNodeText());
    final node19 = Node(getNodeText());
    final node20 = Node(getNodeText());
    final node21 = Node(getNodeText());
    final node22 = Node(getNodeText());
    final node23 = Node(getNodeText());

    graph.addEdge(node1, node13, paint: Paint()..color = Colors.red);
    graph.addEdge(node1, node21);
    graph.addEdge(node1, node4);
    graph.addEdge(node1, node3);
    graph.addEdge(node2, node3);
    graph.addEdge(node2, node20);
    graph.addEdge(node3, node4);
    graph.addEdge(node3, node5);
    graph.addEdge(node3, node23);
    graph.addEdge(node4, node6);
    graph.addEdge(node5, node7);
    graph.addEdge(node6, node8);
    graph.addEdge(node6, node16);
    graph.addEdge(node6, node23);
    graph.addEdge(node7, node9);
    graph.addEdge(node8, node10);
    graph.addEdge(node8, node11);
    graph.addEdge(node9, node12);
    graph.addEdge(node10, node13);
    graph.addEdge(node10, node14);
    graph.addEdge(node10, node15);
    graph.addEdge(node11, node15);
    graph.addEdge(node11, node16);
    graph.addEdge(node12, node20);
    graph.addEdge(node13, node17);
    graph.addEdge(node14, node17);
    graph.addEdge(node14, node18);
    graph.addEdge(node16, node18);
    graph.addEdge(node16, node19);
    graph.addEdge(node16, node20);
    graph.addEdge(node18, node21);
    graph.addEdge(node19, node22);
    graph.addEdge(node21, node23);
    graph.addEdge(node22, node23);

    builder
      ..nodeSeparation = (15)
      ..levelSeparation = (15)
      ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;
  }
}
