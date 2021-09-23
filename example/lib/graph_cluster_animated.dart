import 'dart:async';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class GraphScreen extends StatefulWidget {
  Graph graph;
  Algorithm algorithm;
  final Paint paint;
  GraphScreen(this.graph, this.algorithm, this.paint);

  @override
  _GraphScreenState createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  bool animated = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text("Graph Screen"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
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
          )),
    );
  }

  Future<void> update() async {
    setState(() {});
  }
}
