import 'package:flutter/material.dart';

import 'GraphViewClusterPage.dart';
import 'TreeViewPage.dart';


void main() {
  runApp(MyApp());
}

List<String> text = [
  "Tree View (BuchheimWalker)",
  "Graph Cluster View (FruchtermanReingold)",
];

List<Widget> widgets = [
  GraphViewPage(),
  GraphClusterViewPage(),
];

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(children: [
              ...mapIndexed(
                  text,
                      (index, item) =>
                      FlatButton(
                          onPressed: () =>
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        Scaffold(
                                          appBar: AppBar(),
                                          body: widgets[index],
                                        )),
                              ),
                          child: Text(
                            item.toString(),
                            style: TextStyle(color: Theme
                                .of(context)
                                .primaryColor),
                          ))),
            ]),
          ),
        ),
      );
}


Iterable<E> mapIndexed<E, T>(Iterable<T> items, E Function(int index, T item) f) sync* {
  var index = 0;

  for (final item in items) {
    yield f(index, item);
    index = index + 1;
  }
}