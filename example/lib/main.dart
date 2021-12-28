import 'package:example/decision_tree_screen.dart';
import 'package:example/layer_graphview.dart';
import 'package:example/tree_graphview_json.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'directed_graphview.dart';
import 'graph_cluster_animated.dart';
import 'layer_graphview_json.dart';
import 'tree_graphview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}

class Home extends StatelessWidget {
  const Home({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(children: [
            SizedBox(
              height: 20,
            ),
            MaterialButton(
                color: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreeViewPage(),
                      ),
                    ),
                child: Text(
                  'Tree View (BuchheimWalker)',
                  style: TextStyle(fontSize: 30),
                )),
            SizedBox(
              height: 20,
            ),
            MaterialButton(
                color: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GraphClusterViewPage(),
                      ),
                    ),
                child: Text(
                  'Graph Cluster View (FruchtermanReingold)',
                  style: TextStyle(fontSize: 30),
                )),
            SizedBox(
              height: 20,
            ),
            MaterialButton(
                color: Colors.greenAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LayeredGraphViewPage(),
                      ),
                    ),
                child: Text(
                  "Layered View (Sugiyama)",
                  style: TextStyle(fontSize: 30),
                )),
            SizedBox(
              height: 20,
            ),
            MaterialButton(
                color: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreeViewPageFromJson(),
                      ),
                    ),
                child: Text(
                  'Tree View From Json(BuchheimWalker)',
                  style: TextStyle(fontSize: 30),
                )),
            SizedBox(
              height: 20,
            ),
            MaterialButton(
                color: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LayerGraphPageFromJson(),
                  ),
                ),
                child: Text(
                  'Layer Graph From Json ',
                  style: TextStyle(fontSize: 30),
                )),
            SizedBox(
              height: 20,
            ),
            MaterialButton(
              onPressed: () {
                var graph = new Graph();

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
                var builder = FruchtermanReingoldAlgorithm();

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GraphScreen(graph, builder, null)),
                );
              },
              color: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'Square Grid (FruchtermanReingold)',
                style: TextStyle(fontSize: 30),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            MaterialButton(
              onPressed: () {
                var graph = new Graph();

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

                var builder = FruchtermanReingoldAlgorithm();

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GraphScreen(graph, builder, null)),
                );
              },
              color: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'Triangle Grid (FruchtermanReingold)',
                style: TextStyle(fontSize: 30),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            MaterialButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DecisionTreeScreen()),
                );
              },
              color: Colors.greenAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'Decision Tree (Sugiyama)',
                style: TextStyle(fontSize: 30),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget createNode(String nodeText) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red,
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          nodeText,
          style: TextStyle(fontSize: 10),
        ),
      ),
    );
  }
}
