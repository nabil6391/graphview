import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';


class GraphScreen extends StatefulWidget {
  Graph graph;
  Layout algorithm;
  final Paint paint;
  GraphScreen(this.graph, this.algorithm, this.paint);

  @override
  _GraphScreenState createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  Timer timer;
  Icon animateIcon = Icon(Icons.play_arrow);

  Graph graph;

  Layout algorithm;

  @override
  void initState() {
    graph = widget.graph;

    algorithm = widget.algorithm;
    algorithm.init(graph);
    startTimer();
    super.initState();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(milliseconds: 25), (timer) {
      algorithm.step(graph);
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
     algorithm.setDimensions(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text("Graph Screen"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              algorithm.init(graph);
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
              CustomPaint(
                size: MediaQuery.of(context).size,
                painter: EdgeRender(algorithm, graph, Offset(20,20)),
              ),
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

class EdgeRender extends CustomPainter {
  Layout algorithm;
  Graph graph;
  Offset offset;
  EdgeRender(this.algorithm, this.graph, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    var edgePaint = (Paint()
          ..color = Colors.black
          ..strokeWidth = 3)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    algorithm.renderer.render(canvas, graph, edgePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
