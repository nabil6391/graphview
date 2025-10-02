import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class TreeViewPage extends StatefulWidget {
  @override
  _TreeViewPageState createState() => _TreeViewPageState();
}

class _TreeViewPageState extends State<TreeViewPage> with TickerProviderStateMixin {

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
                initialNode: ValueKey(1),
                panAnimationDuration: Duration(milliseconds: 600),
                toggleAnimationDuration: Duration(milliseconds: 600),
                centerGraph: true,
                builder: (Node node) => GestureDetector(
                  onTap: () => _toggleCollapse(node),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: Colors.blue[100]!, spreadRadius: 1)],
                    ),
                    child: Text(
                      'Node ${node.key?.value}',
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



// Create all nodes
    final root = Node.Id(1);  // Central topic

// Left side - Technology branch (will be large)
    final tech = Node.Id(2);
    final ai = Node.Id(3);
    final web = Node.Id(4);
    final mobile = Node.Id(5);
    final aiSubtopics = [
      Node.Id(6),   // Machine Learning
      Node.Id(7),   // Deep Learning
      Node.Id(8),   // NLP
      Node.Id(9),   // Computer Vision
    ];
    final webSubtopics = [
      Node.Id(10),  // Frontend
      Node.Id(11),  // Backend
      Node.Id(12),  // DevOps
    ];
    final frontendDetails = [
      Node.Id(13),  // React
      Node.Id(14),  // Vue
      Node.Id(15),  // Angular
    ];
    final backendDetails = [
      Node.Id(16),  // Node.js
      Node.Id(17),  // Python
      Node.Id(18),  // Java
      Node.Id(19),  // Go
    ];

// Right side - Business branch (will be smaller to test balancing)
    final business = Node.Id(20);
    final marketing = Node.Id(21);
    final sales = Node.Id(22);
    final finance = Node.Id(23);
    final marketingDetails = [
      Node.Id(24),  // Digital Marketing
      Node.Id(25),  // Content Strategy
    ];
    final salesDetails = [
      Node.Id(26),  // B2B Sales
      Node.Id(27),  // Customer Success
    ];

// Additional right side - Personal branch
    final personal = Node.Id(28);
    final health = Node.Id(29);
    final hobbies = Node.Id(30);
    final healthDetails = [
      Node.Id(31),  // Exercise
      Node.Id(32),  // Nutrition
      Node.Id(33),  // Mental Health
    ];
    final exerciseDetails = [
      Node.Id(34),  // Cardio
      Node.Id(35),  // Strength Training
      Node.Id(36),  // Yoga
    ];

    // Build the graph structure
    graph.addEdge(root, tech);
    graph.addEdge(root, business, paint: Paint()..color = Colors.blue);
    graph.addEdge(root, personal, paint: Paint()..color = Colors.green);

// // Technology branch (left side - large subtree)
    graph.addEdge(tech, ai);
    graph.addEdge(tech, web);
    graph.addEdge(tech, mobile);

// AI subtree
    for (final aiNode in aiSubtopics) {
      graph.addEdge(ai, aiNode, paint: Paint()..color = Colors.purple);
    }

// Web subtree with deep nesting
    for (final webNode in webSubtopics) {
      graph.addEdge(web, webNode, paint: Paint()..color = Colors.orange);
    }

// Frontend details (3rd level)
    for (final frontendNode in frontendDetails) {
      graph.addEdge(webSubtopics[0], frontendNode, paint: Paint()..color = Colors.cyan);
    }

// Backend details (3rd level) - even deeper
    for (final backendNode in backendDetails) {
      graph.addEdge(webSubtopics[1], backendNode, paint: Paint()..color = Colors.teal);
    }

// Business branch (right side - smaller subtree)
    graph.addEdge(business, marketing);
    graph.addEdge(business, sales);
    graph.addEdge(business, finance);

// Marketing details
    for (final marketingNode in marketingDetails) {
      graph.addEdge(marketing, marketingNode, paint: Paint()..color = Colors.red);
    }

// Sales details
    for (final salesNode in salesDetails) {
      graph.addEdge(sales, salesNode, paint: Paint()..color = Colors.indigo);
    }

// Personal branch (right side - medium subtree)
    graph.addEdge(personal, health);
    graph.addEdge(personal, hobbies);

// Health details
    for (final healthNode in healthDetails) {
      graph.addEdge(health, healthNode, paint: Paint()..color = Colors.lightGreen);
    }

// Exercise details (3rd level)
    for (final exerciseNode in exerciseDetails) {
      graph.addEdge(healthDetails[0], exerciseNode, paint: Paint()..color = Colors.amber);
    }
    _controller.setInitiallyCollapsedNodes(graph, [tech, business, personal]);

    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..useCurvedConnections = true
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }

}