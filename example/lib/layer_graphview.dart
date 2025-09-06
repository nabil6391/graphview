import 'dart:math';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class LayeredGraphViewPage extends StatefulWidget {
  @override
  _LayeredGraphViewPageState createState() => _LayeredGraphViewPageState();
}

class _LayeredGraphViewPageState extends State<LayeredGraphViewPage> {
  GraphViewController _controller = GraphViewController();
  final Random r = Random();
  int nextNodeId = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
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
                      this.setState(() {});
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
                      this.setState(() {});
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
                      this.setState(() {});
                    },
                  ),
                ),
                Container(
                  width: 120,
                  child: Column(
                    children: [
                      Text('Alignment'),
                      DropdownButton<CoordinateAssignment>(
                        value: builder.coordinateAssignment,
                        items: CoordinateAssignment.values.map((coordinateAssignment) {
                          return DropdownMenuItem<CoordinateAssignment>(
                            value: coordinateAssignment,
                            child: Text(coordinateAssignment.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            builder.coordinateAssignment = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final node12 = Node.Id(r.nextInt(100));
                    var edge = graph.getNodeAtPosition(r.nextInt(graph.nodeCount()));
                    print(edge);
                    graph.addEdge(edge, node12);
                    setState(() {});
                  },
                  child: Text('Add'),
                ),
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
                graph: graph,
                algorithm: SugiyamaAlgorithm(builder),
                paint: Paint()
                  ..color = Colors.green
                  ..strokeWidth = 1
                  ..style = PaintingStyle.stroke,
                builder: (Node node) {
                  var a = node.key!.value as int?;
                  return rectangleWidget(a);
                },
              ),
            ),
          ],
        ));
  }

  Widget rectangleWidget(int? a) {
    return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.blue[100]!, spreadRadius: 1),
          ],
        ),
        child: Text('${a}'));
  }

  final Graph graph = Graph();
  SugiyamaConfiguration builder = SugiyamaConfiguration()
    ..bendPointShape = CurvedBendPointShape(curveLength: 20);

  void _navigateToRandomNode() {
    if (graph.nodes.isEmpty) return;

    final randomNode = graph.nodes.firstWhere(
          (node) => node.key != null && node.key!.value == nextNodeId,
      orElse: () => graph.nodes.first,
    );
    final nodeId = randomNode.key!;
    _controller.animateToNode(nodeId);

    setState(() {
      nextNodeId = r.nextInt(graph.nodes.length) + 1;
    });
  }

  @override
  void initState() {
    super.initState();
    final node0 = Node.Id(0);
    final node1 = Node.Id(1);
    final node2 = Node.Id(2);
    final node3 = Node.Id(3);
    final node4 = Node.Id(4);
    final node5 = Node.Id(5);
    final node6 = Node.Id(6);
    final node7 = Node.Id(7);
    final node8 = Node.Id(8);
    final node9 = Node.Id(9);
    final node10 = Node.Id(10);
    final node11 = Node.Id(11);
    final node12 = Node.Id(12);
    final node13 = Node.Id(13);
    final node14 = Node.Id(14);
    final node15 = Node.Id(15);
    final node16 = Node.Id(16);
    final node17 = Node.Id(17);
    final node18 = Node.Id(18);
    final node19 = Node.Id(19);
    final node20 = Node.Id(20);
    final node21 = Node.Id(21);

    // Adding edges based on parent-child relationships
    graph.addEdge(node8, node0);
    graph.addEdge(node2, node11);
    graph.addEdge(node11, node3);
    graph.addEdge(node12, node4);
    graph.addEdge(node4, node9);
    graph.addEdge(node18, node5);
    graph.addEdge(node9, node6);
    graph.addEdge(node15, node6);
    graph.addEdge(node17, node6);
    graph.addEdge(node3, node7);
    graph.addEdge(node17, node7);
    graph.addEdge(node20, node7);
    graph.addEdge(node21, node7);
    graph.addEdge(node0, node16);
    graph.addEdge(node21, node10);
    graph.addEdge(node16, node10);
    graph.addEdge(node21, node12);
    graph.addEdge(node4, node13);
    graph.addEdge(node12, node13);
    graph.addEdge(node1, node14);
    graph.addEdge(node8, node14);
    graph.addEdge(node9, node18);
    graph.addEdge(node19, node17);

    builder
      ..nodeSeparation = (15)
      ..levelSeparation = (15)
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

    // Set initial random node for navigation
    nextNodeId = r.nextInt(22); // 0-21 nodes exist
  }
}