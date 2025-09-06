import 'package:example/decision_tree_screen.dart';
import 'package:example/layer_graphview.dart';
import 'package:example/tree_graphview_json.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'force_directed_graphview.dart';
import 'graph_cluster_animated.dart';
import 'layer_graphview_json.dart';
import 'tree_graphview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GraphView Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Home(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildScrollableContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSection('Tree Algorithms', [
            _buildButton(
              'Tree View',
              'BuchheimWalker Algorithm',
              Icons.account_tree,
              Colors.deepPurple,
                  () => TreeViewPage(),
            ),
            _buildButton(
              'Tree from JSON',
              'Dynamic tree generation',
              Icons.data_object,
              Colors.indigo,
                  () => TreeViewPageFromJson(),
            ),
          ]),

          _buildSection('Layered Algorithms', [
            _buildButton(
              'Layered View',
              'Sugiyama Algorithm',
              Icons.layers,
              Colors.teal,
                  () => LayeredGraphViewPage(),
            ),
            _buildButton(
              'Layer from JSON',
              'JSON-based layered graphs',
              Icons.timeline,
              Colors.cyan,
                  () => LayerGraphPageFromJson(),
            ),
            _buildButton(
              'Decision Tree',
              'Decision-making visualization',
              Icons.device_hub,
              Colors.green,
                  () => DecisionTreeScreen(),
            ),
          ]),

          _buildSection('Cluster Algorithms', [
            _buildButton(
              'Graph Cluster',
              'FruchtermanReingold Algorithm',
              Icons.bubble_chart,
              Colors.orange,
                  () => GraphClusterViewPage(),
            ),
            _buildCustomGraphButton(
              'Square Grid',
              'Structured 3x3 layout',
              Icons.grid_3x3,
              Colors.pink,
              _createSquareGraph,
            ),
            _buildCustomGraphButton(
              'Triangle Grid',
              'Complex network topology',
              Icons.change_history,
              Colors.deepOrange,
              _createTriangleGraph,
            ),
          ]),


        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> buttons) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          ...buttons.map((button) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: button,
          )),
        ],
      ),
    );
  }

  Widget _buildButton(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      Widget Function() pageBuilder,
      ) {
    return Builder(
      builder: (context) => Container(
        height: 80,
        child: Material(
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => pageBuilder()),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    color.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomGraphButton(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      Graph Function() graphBuilder,
      ) {
    return Builder(
      builder: (context) => Container(
        height: 80,
        child: Material(
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              var graph = graphBuilder();
              var builder = FruchtermanReingoldAlgorithm();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GraphScreen(graph, builder, null),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    color.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Graph _createSquareGraph() {
    var graph = Graph();
    Node node1 = Node.Id('One');
    Node node2 = Node.Id('Two');
    Node node3 = Node.Id('Three');
    Node node4 = Node.Id('Four');
    Node node5 = Node.Id('Five');
    Node node6 = Node.Id('Six');
    Node node7 = Node.Id('Seven');
    Node node8 = Node.Id('Eight');
    Node node9 = Node.Id('Nine');

    graph.addEdge(node1, node2);
    graph.addEdge(node1, node4);
    graph.addEdge(node2, node3);
    graph.addEdge(node2, node5);
    graph.addEdge(node3, node6);
    graph.addEdge(node4, node5);
    graph.addEdge(node4, node7);
    graph.addEdge(node5, node6);
    graph.addEdge(node5, node8);
    graph.addEdge(node6, node9);
    graph.addEdge(node7, node8);
    graph.addEdge(node8, node9);

    return graph;
  }

  Graph _createTriangleGraph() {
    var graph = Graph();
    Node node1 = Node.Id('One');
    Node node2 = Node.Id('Two');
    Node node3 = Node.Id('Three');
    Node node4 = Node.Id('Four');
    Node node5 = Node.Id('Five');
    Node node6 = Node.Id('Six');
    Node node7 = Node.Id('Seven');
    Node node8 = Node.Id('Eight');
    Node node9 = Node.Id('Nine');
    Node node10 = Node.Id('Ten');

    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
    graph.addEdge(node2, node4);
    graph.addEdge(node2, node5);
    graph.addEdge(node2, node3);
    graph.addEdge(node3, node5);
    graph.addEdge(node3, node6);
    graph.addEdge(node4, node7);
    graph.addEdge(node4, node8);
    graph.addEdge(node4, node5);
    graph.addEdge(node5, node8);
    graph.addEdge(node5, node9);
    graph.addEdge(node5, node6);
    graph.addEdge(node9, node6);
    graph.addEdge(node10, node6);
    graph.addEdge(node7, node8);
    graph.addEdge(node8, node9);
    graph.addEdge(node9, node10);

    return graph;
  }
}