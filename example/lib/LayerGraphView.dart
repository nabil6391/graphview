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
                decoration: InputDecoration(labelText: "Node Separation"),
                onChanged: (text) {
                  builder.nodeSeparation = int.tryParse(text) ?? 100;
                  this.setState(() {});
                },
              ),
            ),
            Container(
              width: 100,
              child: TextFormField(
                initialValue: builder.levelSeparation.toString(),
                decoration: InputDecoration(labelText: "Level Separation"),
                onChanged: (text) {
                  builder.levelSeparation = int.tryParse(text) ?? 100;
                  this.setState(() {});
                },
              ),
            ),
            RaisedButton(
              onPressed: () {
                final Node node12 = Node(getNodeText());
                var edge = graph.getNodeAtPosition(r.nextInt(graph.nodeCount()));
                print(edge);
                graph.addEdge(edge, node12);
                setState(() {});
              },
              child: Text("Add"),
            )
          ],
        ),
        Expanded(
          child: InteractiveViewer(
              constrained: false,
              boundaryMargin: EdgeInsets.all(100),
              minScale: 0.01,
              maxScale: 5.6,
              child: GraphView(
                graph: graph,
                algorithm: SugiyamaAlgorithm(builder),
                paint: Paint()..color = Colors.green..strokeWidth = 1..style = PaintingStyle.stroke,
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
        child: Text("Node ${n++}"));
  }

  final Graph graph = Graph();

  SugiyamaConfiguration builder = SugiyamaConfiguration();

  @override
  void initState() {
    final Node node1 = Node(getNodeText());
    final Node node2 = Node(getNodeText());
    final Node node3 = Node(getNodeText());
    final Node node4 = Node(getNodeText());
    final Node node5 = Node(getNodeText());
    final Node node6 = Node(getNodeText());
    final Node node8 = Node(getNodeText());
    final Node node7 = Node(getNodeText());
    final Node node9 = Node(getNodeText());
    final Node node10 = Node(getNodeText());
    final Node node11 = Node(getNodeText());
    final Node node12 = Node(getNodeText());
    final Node node13 = Node(getNodeText());
    final Node node14 = Node(getNodeText());
    final Node node15 = Node(getNodeText());
    final Node node16 = Node(getNodeText());
    final Node node17 = Node(getNodeText());
    final Node node18 = Node(getNodeText());
    final Node node19 = Node(getNodeText());
    final Node node20 = Node(getNodeText());
    final Node node21 = Node(getNodeText());
    final Node node22 = Node(getNodeText());
    final Node node23 = Node(getNodeText());

    graph.addEdge(node1, node13);
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
      ..levelSeparation = (15);
  }
}
