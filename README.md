GraphView
===========
Get it from [![pub package](https://img.shields.io/pub/v/graphview.svg)](https://pub.dev/packages/graphview)

Flutter GraphView is used to display data in graph structures. It can display Tree layout, Directed and Layered graph. Useful for Family Tree, Hierarchy View.

![alt Example](https://media.giphy.com/media/Wsd5Uwm72UBZKXb77s/giphy.gif "Force Directed Graph")
![alt Example](https://media.giphy.com/media/jQ7fdMc5HmyQRoikaK/giphy.gif "Tree")
![alt Example](image/LayeredGraph.png "Layered Graph Example")

Overview
========
The library is designed to support different graph layouts and currently works excellent with small graphs.

You can have a look at the flutter web implementation here:
http://graphview.surge.sh/

Layouts
======
### Tree
Uses Walker's algorithm with Buchheim's runtime improvements (`BuchheimWalkerAlgorithm` class). Supports different orientations. All you have to do is using the `BuchheimWalkerConfiguration.orientation` with either `ORIENTATION_LEFT_RIGHT`, `ORIENTATION_RIGHT_LEFT`, `ORIENTATION_TOP_BOTTOM` and
`ORIENTATION_BOTTOM_TOP` (default). Furthermore parameters like sibling-, level-, subtree separation can be set.

Useful for: Family Tree, Hierarchy View, Flutter Widget Tree, 
### Directed graph
Directed graph drawing by simulating attraction/repulsion forces. For this the algorithm by Fruchterman and Reingold (`FruchtermanReingoldAlgorithm` class) was implemented.

Useful for: Social network, Mind Map, Cluster, Graphs, Intercity Road Network,

### Layered graph
Algorithm from Sugiyama et al. for drawing multilayer graphs, taking advantage of the hierarchical structure of the graph (SugiyamaAlgorithm class). You can also set the parameters for node and level separation using the SugiyamaConfiguration.

Useful for: Hierarchical Graph which it can have weird edges/multiple paths

Usage
======

Currently GraphView must be used together with a Zoom Engine like [InteractiveViewer](https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html). To change the zoom values just use the different attributes described in the InteractiveViewer class.

To create a graph, we need to instantiate the `Graph` class. Then we need to pass the layout and also optional the edge renderer.

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: GraphViewPage(),
      );
}


class GraphViewPage extends StatefulWidget {
  @override
  _GraphViewPageState createState() => _GraphViewPageState();
}

class _GraphViewPageState extends State<GraphViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Wrap(
              children: [
                Container(
                  width: 100,
                  child: TextFormField(
                    initialValue: builder.siblingSeparation.toString(),
                    decoration: InputDecoration(labelText: "Sibling Sepration"),
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
                    decoration: InputDecoration(labelText: "Level Seperation"),
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
                    decoration: InputDecoration(labelText: "Subtree separation"),
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
                    decoration: InputDecoration(labelText: "Orientation"),
                    onChanged: (text) {
                      builder.orientation = int.tryParse(text) ?? 100;
                      this.setState(() {});
                    },
                  ),
                ),
                RaisedButton(
                  onPressed: () {
                    final Node node12 = Node(getNodeText());
                    var edge = graph.getNodeAtPosition(r.nextInt(graph.nodeCount()));
                    print(edge);
                    graph.addEdge(edge, node12);
                    setState(() {});
                  },
                  child: Text("Add"),
                )
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                  constrained: false,
                  scaleEnabled: false,
                  boundaryMargin: EdgeInsets.all(100),
                  minScale: 0.01,
                  maxScale: 5.6,
                  child: GraphView(
                    graph: graph,
                    algorithm: BuchheimWalkerAlgorithm(builder),
                  )),
            ),
          ],
        )
    );
  }

  Random r = Random();

  int n = 1;

  Widget getNodeText() {
    return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.blue[100], spreadRadius: 1),
          ],
        ),
        child: Text("Node ${n++}"));
  }

  final Graph graph = Graph();
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  @override
  void initState() {
    final Node node1 = Node(getNodeText());
    final Node node2 = Node(getNodeText());
    final Node node3 = Node(getNodeText());
    final Node node4 = Node(getNodeText());
    final Node node5 = Node(getNodeText());
    final Node node6 = Node(getNodeText());
    final Node node8 = Node(getNodeText());
    final Node node7 = Node(getNodeText());
    final Node node9 = Node(getNodeText());
    final Node node10 = Node(getNodeText());
    final Node node11 = Node(getNodeText());
    final Node node12 = Node(getNodeText());

    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
    graph.addEdge(node1, node4);
    graph.addEdge(node2, node5);
    graph.addEdge(node2, node6);
    graph.addEdge(node6, node7);
    graph.addEdge(node6, node8);
    graph.addEdge(node4, node9);
    graph.addEdge(node4, node10);
    graph.addEdge(node4, node11);
    graph.addEdge(node11, node12);

    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }
}
```
### Using any widget inside the Node
You can use any widget inside the node:

```dart
Node node = Node(getNodeText);

getNodeText() {
    return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.blue[100], spreadRadius: 1),
          ],
        ),
        child: Text("Node ${n++}"));
  }
```

### Using Paint to color and line thickness
You can specify the edge color and thickness by using a custom paint

```dart

getGraphView() {
        return GraphView(
                graph: graph,
                algorithm: SugiyamaAlgorithm(builder),
                paint: Paint()..color = Colors.green..strokeWidth = 1..style = PaintingStyle.stroke,
              );
}
```

### Color Edges individually 
Add an additional parameter paint. Applicable for ArrowEdgeRenderer for now.

```dart
var a = Node();
var b = Node();
 graph.addEdge(a, b, paint: Paint()..color = Colors.red);
```

### Add focused Node
You can focus on a specific node. This will allow scrolling to that node in the future, but for now , using it we can drag a node with realtime updates in force directed graph

```dart
 onPanUpdate: (details) {
        var x = details.globalPosition.dx;
        var y = details.globalPosition.dy;
        setState(() {
          builder.setFocusedNode(graph.getNodeAtPosition(i));
          graph.getNodeAtPosition(i).position = Offset(x,y);
        });
      },
```
Examples
========
#### Rooted Tree
![alt Example](image/TopDownTree.png "Tree Example")

#### Rooted Tree (Bottom to Top)
![alt Example](image/BottomTopTree.png "Tree Example")

#### Rooted Tree (Left to Right)
![alt Example](image/LeftRightTree.png "Tree Example")

#### Rooted Tree (Right to Left)
![alt Example](image/RightLeftTree.png "Tree Example")

#### Directed Graph
![alt Example](image/Graph.png "Directed Graph Example")
![alt Example](https://media.giphy.com/media/eNuoOOcbvWlRmJjkDZ/giphy.gif "Force Directed Graph")

#### Layered Graph
![alt Example](image/LayeredGraph.png "Layered Graph Example")

Inspirations
========
This library is basically a dart representation of the excellent Android Library [GraphView](https://github.com/Team-Blox/GraphView) by Team-Blox

I would like to thank them for open sourcing their code for which reason I was able to port their code to dart and use for flutter.

Future Works
========

- [] Add nodeOnTap
- [x] Add Layered Graph
- [] Use a builder pattern to draw items on demand.
- [] Animations
- [] Dynamic Node Position update for directed graph


License
=======

MIT License

Copyright (c) 2020 Nabil Mosharraf

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.