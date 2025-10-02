import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class LargeTreeViewPage extends StatefulWidget {
  @override
  _LargeTreeViewPageState createState() => _LargeTreeViewPageState();
}

class _LargeTreeViewPageState extends State<LargeTreeViewPage> with TickerProviderStateMixin {

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
                algorithm: algorithm,
                centerGraph: true,
                initialNode: ValueKey(1),
                panAnimationDuration: Duration(milliseconds: 750),
                toggleAnimationDuration: Duration(milliseconds: 750),
                // edgeBuilder: (Edge edge, EdgeGeometry geometry) {
                //   return InteractiveEdge(
                //     edge: edge,
                //     geometry: geometry,
                //     onTap: () => print('Edge tapped: ${edge.key}'),
                //     color: Colors.red,
                //     strokeWidth: 3.0,
                //   );
                // },
                builder: (Node node) => InkWell(
                  onTap: () => _toggleCollapse(node),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.blue[100]!, spreadRadius: 1)],
                    ),
                    child: Text(
                      '${node.key?.value}',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  late final algorithm = BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder));

  void _toggleCollapse(Node node) {
    _controller.toggleNodeExpanded(graph, node, animate: true);
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
      // nextNodeId = r.nextInt(graph.nodes.length) + 1;
    });
  }

  void _resetView() {
    _controller.animateToNode(ValueKey(1));
  }

  @override
  void initState() {
    super.initState();

    var n = 1000;
    final nodes = List.generate(n, (i) => Node.Id(i + 1));

// Generate tree edges using a queue-based approach
    int currentChild = 1; // Start from node 1 (node 0 is root)

    for (var i = 0; i < n && currentChild < n; i++) {
      final children = (i < n ~/ 3) ? 3 : 2;

      for (var j = 0; j < children && currentChild < n; j++) {
        graph.addEdge(nodes[i], nodes[currentChild]);
        currentChild++;
      }
    }

    builder
      ..siblingSeparation = (10)
      ..levelSeparation = (100)
      ..subtreeSeparation = (10)
      ..useCurvedConnections = true
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT);
  }

}