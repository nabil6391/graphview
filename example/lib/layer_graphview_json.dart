import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class LayerGraphPageFromJson extends StatefulWidget {
  @override
  _LayerGraphPageFromJsonState createState() => _LayerGraphPageFromJsonState();
}

class _LayerGraphPageFromJsonState extends State<LayerGraphPageFromJson> {
  var  json =   {
    'edges': [
      {
        'from': '1',
        'to': '2'
      },
      {
        'from': '3',
        'to': '2'
      },
      {
        'from': '4',
        'to': '5'
      },
      {
        'from': '6',
        'to': '4'
      },
      {
        'from': '2',
        'to': '4'
      },
      {
        'from': '2',
        'to': '7'
      },
      {
        'from': '2',
        'to': '8'
      },
      {
        'from': '9',
        'to': '10'
      },
      {
        'from': '9',
        'to': '11'
      },
      {
        'from': '5',
        'to': '12'
      },
      {
        'from': '4',
        'to': '9'
      },
      {
        'from': '6',
        'to': '13'
      },
      {
        'from': '6',
        'to': '14'
      },
      {
        'from': '6',
        'to': '15'
      },
      {
        'from': '16',
        'to': '3'
      },
      {
        'from': '17',
        'to': '3'
      },
      {
        'from': '18',
        'to': '16'
      },
      {
        'from': '19',
        'to': '17'
      },
      {
        'from': '11',
        'to': '1'
      },

    ]
  };

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
                  width: 100,
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
                  onPressed: () => _navigateToRandomNode(),
                  child: Text('Go to Node $nextNodeId'),
                ),
                ElevatedButton(
                  onPressed: () => _controller.resetView(),
                  child: Text('Reset View'),
                ),
                ElevatedButton(
                  onPressed: () => _controller.zoomToFit(),
                  child: Text('Zoom to fit'),
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
                  // I can decide what widget should be shown here based on the id
                  var a = node.key!.value;
                  return rectangleWidget(a, node);
                },
              ),
            ),
          ],
        ));
  }

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


  Widget rectangleWidget(String? a, Node node) {
    return Container(
      color: Colors.amber,
      child: InkWell(
        onTap: () {
          print('clicked');
        },
        child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: Colors.blue[100]!, spreadRadius: 1),
              ],
            ),
            child: Text('${a}')),
      ),
    );
  }

  final Graph graph = Graph();
  @override
  void initState() {
    super.initState();
    var edges = json['edges']!;
    edges.forEach((element) {
      var fromNodeId = element['from'];
      var toNodeId = element['to'];
      graph.addEdge(Node.Id(fromNodeId), Node.Id(toNodeId));
    });

    builder
      ..nodeSeparation = (15)
      ..levelSeparation = (15)
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;
    }

  }

  var builder = SugiyamaConfiguration();

