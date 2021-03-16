import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class TreeViewPage extends StatefulWidget {
  @override
  _TreeViewPageState createState() => _TreeViewPageState();
}

class _TreeViewPageState extends State<TreeViewPage> {
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
                initialValue: builder.siblingSeparation.toString(),
                decoration: InputDecoration(labelText: 'Sibling Separation'),
                onChanged: (text) {
                  builder.siblingSeparation = int.tryParse(text) ?? 100;
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
                initialValue: builder.subtreeSeparation.toString(),
                decoration: InputDecoration(labelText: 'Subtree separation'),
                onChanged: (text) {
                  builder.subtreeSeparation = int.tryParse(text) ?? 100;
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
                var edge = graph.getNodeAtPosition(r.nextInt(graph.nodeCount()));
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
              minScale: 0.01,
              maxScale: 5.6,
              child: GraphView(
                graph: graph,
                algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
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
    return InkWell(
      onTap: () {
        print('clicked');
      },
      child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.blue[100], spreadRadius: 1),
            ],
          ),
          child: Text('Node ${n++}')),
    );
  }

  final Graph graph = Graph();
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

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

    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3, paint: Paint()..color = Colors.red);
    graph.addEdge(node1, node4, paint: Paint()..color = Colors.blue);
    graph.addEdge(node2, node5);
    graph.addEdge(node2, node6);
    graph.addEdge(node6, node7, paint: Paint()..color = Colors.red);
    graph.addEdge(node6, node8, paint: Paint()..color = Colors.red);
    graph.addEdge(node4, node9);
    graph.addEdge(node4, node10, paint: Paint()..color = Colors.black);
    graph.addEdge(node4, node11, paint: Paint()..color = Colors.red);
    graph.addEdge(node11, node12);

    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }
}
