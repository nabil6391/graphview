import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class MultipleForestTreeViewPage extends StatefulWidget {
  @override
  _TreeViewPageState createState() => _TreeViewPageState();
}

class _TreeViewPageState extends State<MultipleForestTreeViewPage> with TickerProviderStateMixin {

  GraphViewController _controller = GraphViewController();
  final Random r = Random();
  int nextNodeId = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Tree View'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Configuration controls
            Wrap(
              children: [
                Container(
                  width: 100,
                  child: TextFormField(
                    initialValue: builder.siblingSeparation.toString(),
                    decoration: InputDecoration(labelText: 'Sibling Separation'),
                    onChanged: (text) {
                      builder.siblingSeparation = int.tryParse(text) ?? 100;
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
                    initialValue: builder.subtreeSeparation.toString(),
                    decoration: InputDecoration(labelText: 'Subtree separation'),
                    onChanged: (text) {
                      builder.subtreeSeparation = int.tryParse(text) ?? 100;
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
                  onPressed: _navigateToRandomNode,
                  child: Text('Go to Node $nextNodeId'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _resetView,
                  child: Text('Reset View'),
                ),
                SizedBox(width: 8,),
                ElevatedButton(onPressed: (){
                  _controller.zoomToFit();
                }, child: Text('Zoom to fit'))
              ],
            ),

            Expanded(
              child: GraphView.builder(
                controller: _controller,
                graph: graph,
                algorithm: TidierTreeLayoutAlgorithm(builder, null),
                builder: (Node node) => Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(node.key?.value.toString() ?? ''),
                ),
              )
            ),
          ],
        ));
  }

  Widget rectangleWidget(int? a) {
    return InkWell(
      onTap: () {
        print('clicked node $a');
      },
      child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.blue[100]!, spreadRadius: 1),
            ],
          ),
          child: Text('Node ${a} ')),
    );
  }

  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

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

  void _resetView() {
    _controller.resetView();
  }

  @override
  void initState() {
    super.initState();

    var json = {
      'edges': [
        {'from': 1, 'to': 2},
        {'from': 9, 'to': 2},
        {'from': 10, 'to': 2},
        {'from': 2, 'to': 3},
        {'from': 2, 'to': 4},
        {'from': 2, 'to': 5},
        {'from': 5, 'to': 6},
        {'from': 5, 'to': 7},
        {'from': 6, 'to': 8},
        {'from': 12, 'to': 11},
      ]
    };

    var edges = json['edges']!;
    edges.forEach((element) {
      var fromNodeId = element['from'];
      var toNodeId = element['to'];
      graph.addEdge(Node.Id(fromNodeId), Node.Id(toNodeId));
    });

    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }

}