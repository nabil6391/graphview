import 'dart:math';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class GraphScreen extends StatefulWidget {
  final Graph graph;
  final Algorithm algorithm;
  final Paint? paint;

  GraphScreen(this.graph, this.algorithm, this.paint);

  @override
  _GraphScreenState createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  GraphViewController _controller = GraphViewController();
  final Random r = Random();
  int nextNodeId = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Graph View'),
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
              });
            },
          )
        ],
      ),

      body: Column(
        children: [
          // Navigation controls
          Wrap(
            children: [
              ElevatedButton(
                onPressed: () => _navigateToRandomNode(),
                child: Text('Go to Node $nextNodeId'),
              ),
              ElevatedButton(
                onPressed: () => _controller.resetView(),
                child: Text('Reset View'),
              ),
              ElevatedButton(
                onPressed: () => _controller.zoomToFit(),
                child: Text("Zoom to fit"),
              ),
            ],
          ),
          Expanded(
            child: GraphView.builder(
              controller: _controller,
              graph: widget.graph,
              algorithm: widget.algorithm,
              paint: widget.paint,
              builder: (Node node) {
                var a = node.key?.value;
                return rectangleWidget(a);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget rectangleWidget(nodeText) {
    return InkWell(
      onTap: () => print('clicked $nodeText'),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red,
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            '$nodeText',
            style: TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
  }

  void _navigateToRandomNode() {
    if (widget.graph.nodes.isEmpty) return;

    final randomNode = widget.graph.nodes.firstWhere(
          (node) => node.key != null && node.key!.value == nextNodeId,
      orElse: () => widget.graph.nodes.first,
    );
    final nodeId = randomNode.key!;
    _controller.animateToNode(nodeId);

    setState(() {
      nextNodeId = r.nextInt(widget.graph.nodes.length) + 1;
    });
  }

}