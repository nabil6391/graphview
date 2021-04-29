import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';


class GraphScreenCluster extends StatefulWidget {
  Graph graph;

  GraphScreenCluster(this.graph, Layout builder);

  @override
  _GraphScreenClusterState createState() => _GraphScreenClusterState();
}

class _GraphScreenClusterState extends State<GraphScreenCluster> {
  Timer timer;
  Icon animateIcon = Icon(Icons.play_arrow);

  Graph graph;

  Layout builder;

  @override
  void initState() {
    graph = widget.graph;


    builder.init(graph);
    startTimer();
    super.initState();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(milliseconds: 25), (timer) {
      builder.step(graph);
      update();
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     builder.setDimensions(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text("Graph Screen"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              builder.init(graph);
              update();
            },
          ),
          IconButton(
            icon: animateIcon,
            onPressed: () async {
              if (timer.isActive) {
                timer.cancel();
                setState(() {
                  animateIcon = Icon(Icons.pause);
                });
              } else {
                startTimer();
                setState(() {
                  animateIcon = Icon(Icons.play_arrow);
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              add();
              update();
            },
          )
        ],
      ),
      body: InteractiveViewer(
        scaleEnabled: true,
        panEnabled: true,
        boundaryMargin: EdgeInsets.all(double.infinity),
        maxScale: 2,
        minScale: .01,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.white)),
          child: Stack(
            overflow: Overflow.visible,
            clipBehavior: Clip.none,
            children: [
              ...List<Widget>.generate(graph.edges.length, (index) {
                return GestureDetector(
                  onLongPress: () {
                    print(graph.edges[index].source.key.toString());
                  },
                  child: CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: DrawLine(
                      start: {
                        "x": graph.edges[index].source.position.dx + 20,
                        "y": graph.edges[index].source.position.dy + 20
                      },
                      end: {
                        "x": graph.edges[index].destination.position.dx + 20,
                        "y": graph.edges[index].destination.position.dy + 20
                      },
                    ),
                  ),
                );
              }),
              ...List<Widget>.generate(graph.nodeCount(), (index) {
                return Positioned(
                  child: GestureDetector(
                    child: graph.getNodeAtPosition(index).data,
                    onPanUpdate: (details) {
                      graph.getNodeAtPosition(index).position += details.delta;
                      update();
                    },
                  ),
                  top: graph.getNodeAtPosition(index).position.dy,
                  left: graph.getNodeAtPosition(index).position.dx,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> update() async {
    setState(() {});
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

  void add() {
    var node2 = Node(createNode(Random().nextInt(10).toString()));

    var node1 = graph.getNodeAtPosition(Random().nextInt(graph.nodes.length));
    graph.addEdge(node1, node2);
  }
}

class DrawLine extends CustomPainter {
  Map<String, double> start;
  Map<String, double> end;

  DrawLine({this.start, this.end});

  @override
  void paint(Canvas canvas, Size size) {
    Paint line = new Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(start["x"], start["y"]),
      Offset(end["x"], end["y"]),
      line,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
