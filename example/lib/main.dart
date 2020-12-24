import 'package:example/LayerGraphView.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'GraphViewClusterPage.dart';
import 'TreeViewPage.dart';
import 'graph_change_notifier.dart';
import 'graph_screen.dart';

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
    return Scaffold(
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider<GraphChangeNotifier>(
                          create: (_) => GraphChangeNotifier(),
                          builder: (context, child) {
                            Provider.of<GraphChangeNotifier>(context, listen: false).graphType = 'tree';
                            return GraphScreen();
                          }),
                    ));
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider<GraphChangeNotifier>(
                          create: (_) => GraphChangeNotifier(),
                          builder: (context, child) {
                            Provider.of<GraphChangeNotifier>(context, listen: false).graphType = 'square';

                            return GraphScreen();
                          }),
                    ));
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider<GraphChangeNotifier>(
                          create: (_) => GraphChangeNotifier(),
                          builder: (context, child) {
                            Provider.of<GraphChangeNotifier>(context, listen: false).graphType = 'triangle';
                            return GraphScreen();
                          }),
                    ));
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
        ]),
      ),
    );
  }
}
