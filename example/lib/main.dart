import 'package:example/LayerGraphView.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'GraphViewClusterPage.dart';
import 'TreeViewPage.dart';
import 'graph_screen_cluster.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:  Home()
    );
  }
}

class Home extends StatelessWidget {
  const Home({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child:Scaffold(
      body: Center(
        child: Column(children: [
          FlatButton(
              onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Scaffold(
                              appBar: AppBar(),
                              body: TreeViewPage(),
                            )),
                  ),
              child: Text(
                "Tree View (BuchheimWalker)",
                style: TextStyle(color: Theme.of(context).primaryColor),
              )),
          FlatButton(
              onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Scaffold(
                              appBar: AppBar(),
                              body: GraphClusterViewPage(),
                            )),
                  ),
              child: Text(
                "Graph Cluster View (FruchtermanReingold)",
                style: TextStyle(color: Theme.of(context).primaryColor),
              )),
          FlatButton(
              onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Scaffold(
                              appBar: AppBar(),
                              body: LayeredGraphViewPage(),
                            )),
                  ),
              child: Text(
                "Layered View (Sugiyama)",
                style: TextStyle(color: Theme.of(context).primaryColor),
              )),
          Center(
            child: MaterialButton(
              onPressed: () {
                  var graph = new Graph();
                  Node node1 = Node(createNode("One"));
                  Node node2 = Node(createNode("Two"));
                  Node node3 = Node(createNode("Three"));
                  Node node4 = Node(createNode("Four"));
                  Node node5 = Node(createNode("Five"));
                  Node node6 = Node(createNode("Six"));
                  Node node7 = Node(createNode("Seven"));
                  Node node8 = Node(createNode("Eight"));
                  Node node9 = Node(createNode("Nine"));
                  Node node10 = Node(createNode("Ten"));
                  Node node11 = Node(createNode("Eleven"));
                  Node node12 = Node(createNode("Twelve"));
                  Node node13 = Node(createNode("Thirteen"));

                  graph.addEdge(node1, node2);
                  graph.addEdge(node1, node3, paint: Paint()..color = Colors.red);
                  graph.addEdge(node1, node4, paint: Paint()..color = Colors.blue);
                  graph.addEdge(node2, node5);
                  graph.addEdge(node2, node6);
                  graph.addEdge(node6, node7, paint: Paint()..color = Colors.red);
                  graph.addEdge(node6, node8, paint: Paint()..color = Colors.red);
                  graph.addEdge(node4, node9);
                  graph.addEdge(node4, node10, paint: Paint()..color = Colors.black);
                  graph.addEdge(node4, node11, paint: Paint()..color = Colors.red);
                  graph.addEdge(node11, node12);

                  BuchheimWalkerConfiguration builder1 = BuchheimWalkerConfiguration();
                  builder1
                    ..siblingSeparation = (100)
                    ..levelSeparation = (150)
                    ..subtreeSeparation = (150)
                    ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

                  var builder = BuchheimWalkerAlgorithm(builder1,TreeEdgeRenderer(builder1));

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GraphScreenCluster(graph, builder)),
                  );
                },
                color: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Tree Graph",
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Center(
              child: MaterialButton(
                onPressed: () {
                  var graph = new Graph();

                  Node node1 = Node(createNode("One"));
                  Node node2 = Node(createNode("Two"));
                  Node node3 = Node(createNode("Three"));
                  Node node4 = Node(createNode("Four"));
                  Node node5 = Node(createNode("Five"));
                  Node node6 = Node(createNode("Six"));
                  Node node7 = Node(createNode("Seven"));
                  Node node8 = Node(createNode("Eight"));
                  Node node9 = Node(createNode("Nine"));
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
                    MaterialPageRoute(builder: (context) => GraphScreenCluster(graph, builder)),
                  );
                },
                color: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Square Grid",
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Center(
              child: MaterialButton(
                onPressed: () {
                  var graph = new Graph();

                  Node node1 = Node(createNode("One"));
                  Node node2 = Node(createNode("Two"));
                  Node node3 = Node(createNode("Three"));
                  Node node4 = Node(createNode("Four"));
                  Node node5 = Node(createNode("Five"));
                  Node node6 = Node(createNode("Six"));
                  Node node7 = Node(createNode("Seven"));
                  Node node8 = Node(createNode("Eight"));
                  Node node9 = Node(createNode("Nine"));
                  Node node10 = Node(createNode("Ten"));

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
                    MaterialPageRoute(builder: (context) => GraphScreenCluster(graph, builder)),
                  );
                },
                color: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Triangle Grid",
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Center(
              child: MaterialButton(
                onPressed: () {
                  var graph = new Graph();

                  final a = Node(createNode(1.toString()));
                  final b = Node(createNode(2.toString()));
                  final c = Node(createNode(3.toString()));
                  final d = Node(createNode(4.toString()));
                  final e = Node(createNode(5.toString()));
                  final f = Node(createNode(6.toString()));
                  final g = Node(createNode(7.toString()));
                  final h = Node(createNode(8.toString()));

                  graph.addEdge(a, b, paint: Paint()..color = Colors.red);
                  graph.addEdge(a, c);
                  graph.addEdge(a, d);
                  graph.addEdge(c, e);
                  graph.addEdge(d, f);
                  graph.addEdge(f, c);
                  graph.addEdge(g, c);
                  graph.addEdge(h, g);

                  var builder = FruchtermanReingoldAlgorithm();

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GraphScreenCluster(graph, builder)),
                  );
                },
                color: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Cluster",
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
          SizedBox(
            height: 50,
          ),
          Center(
            child: MaterialButton(
              onPressed: () {
                var graph = new Graph();

                Node node1 = Node(createNode("One"));
                Node node2 = Node(createNode("Two"));
                Node node3 = Node(createNode("Three"));
                Node node4 = Node(createNode("Four"));
                Node node5 = Node(createNode("Five"));
                Node node6 = Node(createNode("Six"));
                Node node7 = Node(createNode("Seven"));
                Node node8 = Node(createNode("Eight"));
                Node node9 = Node(createNode("Nine"));
                Node node10 = Node(createNode("Ten"));
                Node node11 = Node(createNode("Ten0"));

                final Node node12 = Node(createNode("Ten1"));
                final Node node13 = Node(createNode("Ten2"));
                final Node node14 = Node(createNode("Ten3"));
                final Node node15 = Node(createNode("Ten4"));
                final Node node16 = Node(createNode("Ten5"));
                final Node node17 = Node(createNode("Ten6"));
                final Node node18 = Node(createNode("Ten7"));
                final Node node19 = Node(createNode("Ten8"));
                final Node node20 = Node(createNode("Ten9"));
                final Node node21 = Node(createNode("Ten11"));
                final Node node22 = Node(createNode("Ten12"));
                final Node node23 = Node(createNode("Ten10"));

                graph.addEdge(node1, node13, paint: Paint()..color = Colors.red);
                graph.addEdge(node1, node21);
                graph.addEdge(node1, node4);
                graph.addEdge(node1, node3);
                graph.addEdge(node2, node3);
                graph.addEdge(node2, node20);
                graph.addEdge(node3, node4);
                graph.addEdge(node3, node5);
                graph.addEdge(node3, node23);
                graph.addEdge(node4, node6);
                graph.addEdge(node5, node7);
                graph.addEdge(node6, node8);
                graph.addEdge(node6, node16);
                graph.addEdge(node6, node23);
                graph.addEdge(node7, node9);
                graph.addEdge(node8, node10);
                graph.addEdge(node8, node11);
                graph.addEdge(node9, node12);
                graph.addEdge(node10, node13);
                graph.addEdge(node10, node14);
                graph.addEdge(node10, node15);
                graph.addEdge(node11, node15);
                graph.addEdge(node11, node16);
                graph.addEdge(node12, node20);
                graph.addEdge(node13, node17);
                graph.addEdge(node14, node17);
                graph.addEdge(node14, node18);
                graph.addEdge(node16, node18);
                graph.addEdge(node16, node19);
                graph.addEdge(node16, node20);
                graph.addEdge(node18, node21);
                graph.addEdge(node19, node22);
                graph.addEdge(node21, node23);
                graph.addEdge(node22, node23);

                SugiyamaConfiguration builder1 = SugiyamaConfiguration();
                builder1
                  ..nodeSeparation = (55)
                  ..levelSeparation = (55)
                  ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

                var builder = SugiyamaAlgorithm(builder1);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GraphScreenCluster(graph, builder)),
                );
              },
              color: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "Sugiyama",
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
          ]),
        ),
      ),
    );
  }

  Widget createNode(String nodeText) {
    return GestureDetector(
      child: Container(
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
      ),
      onLongPress: () {
        print(nodeText);
      },
    );
  }
}
