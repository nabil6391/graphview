import 'package:example/decision_tree_screen.dart';
import 'package:example/layer_graphview.dart';
import 'package:example/tree_graphview_json.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'directed_graphview.dart';
import 'tree_graphview.dart';
import 'graph_cluster_animated.dart';

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
                          builder: (context) => TreeViewPage(),),
                    ),
                child: Text(
                  "Tree View (BuchheimWalker)",
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
                  "Graph Cluster View (FruchtermanReingold)",
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
                          builder: (context) =>  LayeredGraphViewPage(),),
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
                          builder: (context) =>  TreeViewPageFromJson(),),
                    ),
                child: Text(
                  "Tree View From Json(BuchheimWalker)",
                  style: TextStyle(fontSize: 30),
                )),
            // SizedBox(
            //   height: 20,
            // ),
            // MaterialButton(
            //   onPressed: () {
            //     var graph = new Graph();
            //
            //     Node node1 = Node.Id("One");
            //     Node node2 = Node.Id("Two");
            //     Node node3 = Node.Id("Three");
            //     Node node4 = Node.Id("Four");
            //     Node node5 = Node.Id("Five");
            //     Node node6 = Node.Id("Six");
            //     Node node7 = Node.Id("Seven");
            //     Node node8 = Node.Id("Eight");
            //     Node node9 = Node.Id("Nine");
            //     Node node10 = Node.Id("Ten");
            //     Node node11 = Node.Id("Eleven");
            //     Node node12 = Node.Id("Twelve");
            //     Node node13 = Node.Id("Thirteen");
            //
            //     graph.addEdge(node1, node2);
            //     graph.addEdge(node1, node3, paint: Paint()..color = Colors.red);
            //     graph.addEdge(node1, node4, paint: Paint()..color = Colors.blue);
            //     graph.addEdge(node2, node5);
            //     graph.addEdge(node2, node6);
            //     graph.addEdge(node6, node7, paint: Paint()..color = Colors.red);
            //     graph.addEdge(node6, node8, paint: Paint()..color = Colors.red);
            //     graph.addEdge(node4, node9);
            //     graph.addEdge(node4, node10, paint: Paint()..color = Colors.black);
            //     graph.addEdge(node4, node11, paint: Paint()..color = Colors.red);
            //     graph.addEdge(node11, node12);
            //
            //     BuchheimWalkerConfiguration builder1 = BuchheimWalkerConfiguration();
            //     builder1
            //       ..siblingSeparation = (100)
            //       ..levelSeparation = (150)
            //       ..subtreeSeparation = (150)
            //       ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
            //
            //     var builder = BuchheimWalkerAlgorithm(builder1, TreeEdgeRenderer(builder1));
            //
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => GraphScreen(graph, builder, null)),
            //     );
            //   },
            //   color: Colors.redAccent,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(30),
            //   ),
            //   child: Text(
            //     "Tree Graph",
            //     style: TextStyle(fontSize: 30),
            //   ),
            // ),
            SizedBox(
              height: 20,
            ),
            MaterialButton(
              onPressed: () {
                var graph = new Graph();

                Node node1 = Node.Id("One");
                Node node2 = Node.Id("Two");
                Node node3 = Node.Id("Three");
                Node node4 = Node.Id("Four");
                Node node5 = Node.Id("Five");
                Node node6 = Node.Id("Six");
                Node node7 = Node.Id("Seven");
                Node node8 = Node.Id("Eight");
                Node node9 = Node.Id("Nine");
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
                "Square Grid (FruchtermanReingold)",
                style: TextStyle(fontSize: 30),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            MaterialButton(
              onPressed: () {
                var graph = new Graph();

                Node node1 = Node.Id("One");
                Node node2 = Node.Id("Two");
                Node node3 = Node.Id("Three");
                Node node4 = Node.Id("Four");
                Node node5 = Node.Id("Five");
                Node node6 = Node.Id("Six");
                Node node7 = Node.Id("Seven");
                Node node8 = Node.Id("Eight");
                Node node9 = Node.Id("Nine");
                Node node10 = Node.Id("Ten");

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
                "Triangle Grid (FruchtermanReingold)",
                style: TextStyle(fontSize: 30),
              ),
            ),
            // SizedBox(
            //   height: 20,
            // ),
            // MaterialButton(
            //   onPressed: () {
            //     var graph = new Graph();
            //
            //     final a = Node.Id(1.toString());
            //     final b = Node.Id(2.toString());
            //     final c = Node.Id(3.toString());
            //     final d = Node.Id(4.toString());
            //     final e = Node.Id(5.toString());
            //     final f = Node.Id(6.toString());
            //     final g = Node.Id(7.toString());
            //     final h = Node.Id(8.toString());
            //
            //     graph.addEdge(a, b, paint: Paint()..color = Colors.red);
            //     graph.addEdge(a, c);
            //     graph.addEdge(a, d);
            //     graph.addEdge(c, e);
            //     graph.addEdge(d, f);
            //     graph.addEdge(f, c);
            //     graph.addEdge(g, c);
            //     graph.addEdge(h, g);
            //
            //     var builder = FruchtermanReingoldAlgorithm();
            //
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => GraphScreen(graph, builder, null)),
            //     );
            //   },
            //   color: Colors.green,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(30),
            //   ),
            //   child: Text(
            //     "Cluster",
            //     style: TextStyle(fontSize: 30),
            //   ),
            // ),
            // SizedBox(
            //   height: 20,
            // ),
            // MaterialButton(
            //   onPressed: () {
            //     var graph = new Graph();
            //
            //     Node node1 = Node.Id("One");
            //     Node node2 = Node.Id("Two");
            //     Node node3 = Node.Id("Three");
            //     Node node4 = Node.Id("Four");
            //     Node node5 = Node.Id("Five");
            //     Node node6 = Node.Id("Six");
            //     Node node7 = Node.Id("Seven");
            //     Node node8 = Node.Id("Eight");
            //     Node node9 = Node.Id("Nine");
            //     Node node10 = Node.Id("Ten");
            //     Node node11 = Node.Id("Ten0");
            //
            //     final Node node12 = Node.Id("Ten1");
            //     final Node node13 = Node.Id("Ten2");
            //     final Node node14 = Node.Id("Ten3");
            //     final Node node15 = Node.Id("Ten4");
            //     final Node node16 = Node.Id("Ten5");
            //     final Node node17 = Node.Id("Ten6");
            //     final Node node18 = Node.Id("Ten7");
            //     final Node node19 = Node.Id("Ten8");
            //     final Node node20 = Node.Id("Ten9");
            //     final Node node21 = Node.Id("Ten11");
            //     final Node node22 = Node.Id("Ten12");
            //     final Node node23 = Node.Id("Ten10");
            //
            //     graph.addEdge(node1, node13, paint: Paint()..color = Colors.red);
            //     graph.addEdge(node1, node21);
            //     graph.addEdge(node1, node4);
            //     graph.addEdge(node1, node3);
            //     graph.addEdge(node2, node3);
            //     graph.addEdge(node2, node20);
            //     graph.addEdge(node3, node4);
            //     graph.addEdge(node3, node5);
            //     graph.addEdge(node3, node23);
            //     graph.addEdge(node4, node6);
            //     graph.addEdge(node5, node7);
            //     graph.addEdge(node6, node8);
            //     graph.addEdge(node6, node16);
            //     graph.addEdge(node6, node23);
            //     graph.addEdge(node7, node9);
            //     graph.addEdge(node8, node10);
            //     graph.addEdge(node8, node11);
            //     graph.addEdge(node9, node12);
            //     graph.addEdge(node10, node13);
            //     graph.addEdge(node10, node14);
            //     graph.addEdge(node10, node15);
            //     graph.addEdge(node11, node15);
            //     graph.addEdge(node11, node16);
            //     graph.addEdge(node12, node20);
            //     graph.addEdge(node13, node17);
            //     graph.addEdge(node14, node17);
            //     graph.addEdge(node14, node18);
            //     graph.addEdge(node16, node18);
            //     graph.addEdge(node16, node19);
            //     graph.addEdge(node16, node20);
            //     graph.addEdge(node18, node21);
            //     graph.addEdge(node19, node22);
            //     graph.addEdge(node21, node23);
            //     graph.addEdge(node22, node23);
            //
            //     SugiyamaConfiguration builder1 = SugiyamaConfiguration();
            //     builder1
            //       ..nodeSeparation = (30)
            //       ..levelSeparation = (50)
            //       ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;
            //
            //     var builder = SugiyamaAlgorithm(builder1);
            //
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => GraphScreen(graph, builder, null)),
            //     );
            //   },
            //   color: Colors.green,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(30),
            //   ),
            //   child: Text(
            //     "Sugiyama",
            //     style: TextStyle(fontSize: 30),
            //   ),
            // ),
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
                "Decision Tree (Sugiyama)",
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
