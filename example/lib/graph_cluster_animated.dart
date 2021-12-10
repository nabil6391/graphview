import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class GraphScreen extends StatefulWidget {
  Graph graph;
  Algorithm algorithm;
  final Paint? paint;

  GraphScreen(this.graph, this.algorithm, this.paint);

  @override
  _GraphScreenState createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  bool animated = true;
  Random r = Random();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Graph Screen'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              setState(() {
                final node12 = Node.Id(r.nextInt(100).toString());
                var edge = widget.graph.getNodeAtPosition(r.nextInt(widget.graph.nodeCount()));
                print(edge);
                widget.graph.addEdge(edge, node12);
                setState(() {});
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.animation),
            onPressed: () async {
              setState(() {
                animated = !animated;
              });
            },
          )
        ],
      ),
      body: InteractiveViewer(
          constrained: false,
          boundaryMargin: EdgeInsets.all(100),
          minScale: 0.0001,
          maxScale: 10.6,
          child: GraphView(
            graph: widget.graph,
            algorithm: widget.algorithm,
            animated: animated,
            builder: (Node node) {
              // I can decide what widget should be shown here based on the id
              var a = node.key!.value as String;
              return rectangWidget(a);
            },
          )),
    );
  }

  Widget rectangWidget(String? i) {
    return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.blue, spreadRadius: 1),
          ],
        ),
        child: Center(child: Text('Node $i')));
  }

  Future<void> update() async {
    setState(() {});
  }
}
