import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:provider/provider.dart';

import 'graph_change_notifier.dart';

class GraphScreen extends StatefulWidget {

  @override
  _GraphScreenState createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  Timer timer;
  Icon animateIcon = Icon(Icons.play_arrow);

  @override
  void initState() {
    Provider.of<GraphChangeNotifier>(context, listen: false).setupGraph();
    startTimer();
    super.initState();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(milliseconds: 25), (timer) {
      Provider.of<GraphChangeNotifier>(context, listen: false).step();
      Provider.of<GraphChangeNotifier>(context, listen: false).update();
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Graph graph = Provider.of<GraphChangeNotifier>(context, listen: true).graph;
    Provider.of<GraphChangeNotifier>(context, listen: false).graphWidth =
        MediaQuery.of(context).size.width;
    Provider.of<GraphChangeNotifier>(context, listen: false).graphHeight =
        MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text("Graph Screen"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<GraphChangeNotifier>(context, listen: false)
                  .setNodeInitialPositions();
              Provider.of<GraphChangeNotifier>(context, listen: false).update();
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
                      Provider.of<GraphChangeNotifier>(context, listen: false)
                          .update();
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
}

class DrawLine extends CustomPainter {
  Map<String, double> start;
  Map<String, double> end;
  DrawLine({this.start, this.end});

  @override
  void paint(Canvas canvas, Size size) {
    Paint line = new Paint()
      ..color = Colors.white
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
