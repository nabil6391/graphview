import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/graph_view.dart';

// Enum for algorithm types
enum LayoutAlgorithmType {
  tidierTree,
  buchheimWalker,
  balloon,
  radialTree,
  circle,
}

class NodeWidget extends StatefulWidget {
  final Node node;
  final ValueNotifier<int> notifier;
  final GraphViewController controller;
  final Graph graph;

  const NodeWidget({
    Key? key,
    required this.node,
    required this.notifier,
    required this.controller,
    required this.graph,
  }) : super(key: key);

  @override
  _NodeWidgetState createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.notifier,
      builder: (context, value, child) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: InkWell(
            onTap: () {
              print('Clicked on Node ${widget.node.key?.value}');
              widget.controller.toggleNodeExpanded(widget.graph, widget.node);
            },
            child: Container(
              padding: EdgeInsets.all(8),
              height: 64,
              width: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.lightBlue[100],
                borderRadius: BorderRadius.circular(8),
                border: isHovered ? Border.all(color: Colors.red, width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.node.key?.value.toString() ?? ''),
                  Text('v:$value', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AlgorithmSelectedVIewPage extends StatefulWidget {
  @override
  _TreeViewPageState createState() => _TreeViewPageState();
}

class _TreeViewPageState extends State<AlgorithmSelectedVIewPage>
    with TickerProviderStateMixin {
  GraphViewController _controller = GraphViewController();
  final Random r = Random();
  int nextNodeId = 1;

  // Algorithm selection
  LayoutAlgorithmType _selectedAlgorithm = LayoutAlgorithmType.radialTree;
  Algorithm? _currentAlgorithm;
  late final AnimationController _edgeController;
  late final Animation<double> edgeAnimation;
  Timer? _updateTimer;
  final Map<Node, ValueNotifier<int>> nodeNotifiers = {};

  @override
  void dispose() {
    _updateTimer?.cancel();
    for (var notifier in nodeNotifiers.values) {
      notifier.dispose();
    }
    _edgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Tree View - Multiple Algorithms'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Algorithm selection dropdown
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Text('Layout Algorithm: '),
                  SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<LayoutAlgorithmType>(
                      value: _selectedAlgorithm,
                      isExpanded: true,
                      onChanged: (LayoutAlgorithmType? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedAlgorithm = newValue;
                            _updateAlgorithm();
                          });
                        }
                      },
                      items: LayoutAlgorithmType.values
                          .map<DropdownMenuItem<LayoutAlgorithmType>>(
                              (LayoutAlgorithmType value) {
                        return DropdownMenuItem<LayoutAlgorithmType>(
                          value: value,
                          child: Text(_getAlgorithmDisplayName(value)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Configuration controls
            Wrap(
              children: [
                Container(
                  width: 100,
                  child: TextFormField(
                    initialValue: builder.siblingSeparation.toString(),
                    decoration:
                        InputDecoration(labelText: 'Sibling Separation'),
                    onChanged: (text) {
                      builder.siblingSeparation = int.tryParse(text) ?? 100;
                      _updateAlgorithm();
                      this.setState(() {});
                    },
                  ),
                ),
                Container(
                  width: 100,
                  child: TextFormField(
                    initialValue: builder.levelSeparation.toString(),
                    decoration: InputDecoration(labelText: 'Level Separation'),
                    onChanged: (text) {
                      builder.levelSeparation = int.tryParse(text) ?? 100;
                      _updateAlgorithm();
                      this.setState(() {});
                    },
                  ),
                ),
                Container(
                  width: 100,
                  child: TextFormField(
                    initialValue: builder.subtreeSeparation.toString(),
                    decoration:
                        InputDecoration(labelText: 'Subtree separation'),
                    onChanged: (text) {
                      builder.subtreeSeparation = int.tryParse(text) ?? 100;
                      _updateAlgorithm();
                      this.setState(() {});
                    },
                  ),
                ),
                Container(
                  width: 100,
                  child: TextFormField(
                    initialValue: builder.orientation.toString(),
                    decoration: InputDecoration(labelText: 'Orientation'),
                    onChanged: (text) {
                      builder.orientation = int.tryParse(text) ?? 100;
                      _updateAlgorithm();
                      this.setState(() {});
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final node12 = Node.Id(r.nextInt(100));
                    var edge =
                        graph.getNodeAtPosition(r.nextInt(graph.nodeCount()));
                    print(edge);
                    graph.addEdge(edge, node12);
                    setState(() {});
                  },
                  child: Text('Add'),
                ),
                ElevatedButton(
                  onPressed: _navigateToRandomNode,
                  child: Text('Go to Node $nextNodeId'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _resetView,
                  child: Text('Reset View'),
                ),
                SizedBox(
                  width: 8,
                ),
                ElevatedButton(
                    onPressed: () {
                      _controller.zoomToFit();
                    },
                    child: Text('Zoom to fit'))
              ],
            ),

            Expanded(
                child: GraphView.builder(
              //key: _graphKey,
              controller: _controller,
              graph: graph,
              algorithm:
                  _currentAlgorithm ?? TidierTreeLayoutAlgorithm(builder, null),
              trackpadScrollCausesScale: true,
              edgeAnimation: edgeAnimation,
              builder: (Node node) {
                var notifier = nodeNotifiers.putIfAbsent(node, () => ValueNotifier<int>(0));
                return NodeWidget(
                  node: node,
                  notifier: notifier,
                  controller: _controller,
                  graph: graph,
                );
              },
            )),
          ],
        ));
  }

  String _getAlgorithmDisplayName(LayoutAlgorithmType type) {
    switch (type) {
      case LayoutAlgorithmType.tidierTree:
        return 'Tidier Tree Layout';
      case LayoutAlgorithmType.buchheimWalker:
        return 'Buchheim Walker Tree Layout';
      case LayoutAlgorithmType.balloon:
        return 'Balloon Layout';
      case LayoutAlgorithmType.radialTree:
        return 'Radial Tree Layout';
      case LayoutAlgorithmType.circle:
        return 'Circle Layout';
    }
  }

  void _updateAlgorithm() {
    switch (_selectedAlgorithm) {
      case LayoutAlgorithmType.tidierTree:
        _currentAlgorithm = TidierTreeLayoutAlgorithm(builder, null);
        break;
      case LayoutAlgorithmType.buchheimWalker:
        _currentAlgorithm = BuchheimWalkerAlgorithm(builder, null);
        break;
      case LayoutAlgorithmType.balloon:
        _currentAlgorithm = BalloonLayoutAlgorithm(builder, null);
        break;
      case LayoutAlgorithmType.radialTree:
        _currentAlgorithm = RadialTreeLayoutAlgorithm(
            builder, ArrowEdgeRenderer(animation: edgeAnimation));
        break;
      case LayoutAlgorithmType.circle:
        final circleConfig = CircleLayoutConfiguration(
          radius: 200.0,
          reduceEdgeCrossing: true,
          reduceEdgeCrossingMaxEdges: 200,
        );
        _currentAlgorithm = CircleLayoutAlgorithm(circleConfig, null);
        break;
    }
  }

  Widget rectangleWidget(int? a) {
    return InkWell(
      onTap: () {
        print('clicked node $a');
      },
      child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.blue[100]!, spreadRadius: 1),
            ],
          ),
          child: Text('Node ${a} ')),
    );
  }

  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  void _navigateToRandomNode() {
    if (graph.nodes.isEmpty) return;

    final randomNode = graph.nodes.firstWhere(
      (node) => node.key != null && node.key!.value == nextNodeId,
      orElse: () => graph.nodes.first,
    );
    final nodeId = randomNode.key!;
    _controller.animateToNode(nodeId);

    setState(() {
      nextNodeId = r.nextInt(graph.nodes.length) + 1;
    });
  }

  void _resetView() {
    _controller.resetView();
  }

  @override
  void initState() {
    super.initState();

    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (graph.nodes.isNotEmpty) {
        var targetNode = graph.nodes.firstWhere(
          (n) => n.key?.value == 50,
          orElse: () => graph.nodes.first,
        );
        if (targetNode.key?.value == 50 && nodeNotifiers.containsKey(targetNode)) {
          nodeNotifiers[targetNode]!.value++;
        }
      }
    });

    _controller.onEdgeTap = (edge) {
      print('Edge from ${edge.source.key} to ${edge.destination.key} clicked!');
    };

    _edgeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    edgeAnimation = CurvedAnimation(
      parent: _edgeController,
      curve: Curves.linear, // important for constant speed
    );

    _edgeController.repeat();

    /* _edgeController.addListener(() {
      // Find the low-level rendering object for the GraphView
      final renderObject = _graphKey.currentContext?.findRenderObject();
      if (renderObject != null) {
        // Force the canvas to redraw the edges immediately
        renderObject.markNeedsPaint();
      }
    }); */

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.lock.codePoint),
      style: TextStyle(
        fontSize: 16.0,
        fontFamily: Icons.lock.fontFamily,
        color: Colors.blueAccent,
        package: Icons.lock.fontPackage,
      ),
    );

    textPainter.layout();

    var json = {
      'edges': [
        // A0 -> B0, B1, B2
        {'from': 1, 'to': 2}, // A0 -> B0
        {'from': 1, 'to': 3}, // A0 -> B1
        {'from': 1, 'to': 4}, // A0 -> B2

        // B0 -> C0, C1, C2, C3
        {'from': 2, 'to': 5}, // B0 -> C0
        {'from': 2, 'to': 6}, // B0 -> C1
        {'from': 2, 'to': 7}, // B0 -> C2
        {'from': 2, 'to': 8}, // B0 -> C3

        // C2 -> H0, H1
        {'from': 7, 'to': 9}, // C2 -> H0
        {'from': 7, 'to': 10}, // C2 -> H1

        // H1 -> H2, H3
        {'from': 10, 'to': 11}, // H1 -> H2
        {'from': 10, 'to': 12}, // H1 -> H3

        // H3 -> H4, H5
        {'from': 12, 'to': 13}, // H3 -> H4
        {'from': 12, 'to': 14}, // H3 -> H5

        // H5 -> H6, H7
        {'from': 14, 'to': 15}, // H5 -> H6
        {'from': 14, 'to': 16}, // H5 -> H7

        // B1 -> D0, D1, D2
        {'from': 3, 'to': 17}, // B1 -> D0
        {'from': 3, 'to': 18}, // B1 -> D1
        {'from': 3, 'to': 19}, // B1 -> D2

        // B2 -> E0, E1, E2
        {'from': 4, 'to': 20}, // B2 -> E0
        {'from': 4, 'to': 21}, // B2 -> E1
        {'from': 4, 'to': 22}, // B2 -> E2

        // D0 -> F0, F1, F2
        {'from': 17, 'to': 23}, // D0 -> F0
        {'from': 17, 'to': 24}, // D0 -> F1
        {'from': 17, 'to': 25}, // D0 -> F2

        // D1 -> G0, G1, G2, G3, G4, G5, G6, G7
        {'from': 18, 'to': 26}, // D1 -> G0
        {'from': 18, 'to': 27}, // D1 -> G1
        {'from': 18, 'to': 28}, // D1 -> G2
        {'from': 18, 'to': 29}, // D1 -> G3
        {'from': 18, 'to': 30}, // D1 -> G4
        {'from': 18, 'to': 31}, // D1 -> G5
        {'from': 18, 'to': 32}, // D1 -> G6
        {'from': 18, 'to': 33}, // D1 -> G7
      ],
      'ghostEdges': [
        {'from': 1, 'to': 4}, // A0 -> B0
        {'from': 1, 'to': 7}, // A0 -> B1
        {'from': 1, 'to': 6}, // A0 -> B2
        {'from': 17, 'to': 4}, // A0 -> B0
        {'from': 17, 'to': 30}, // A0 -> B1
        {'from': 17, 'to': 6},

        // B0 -> C0, C1, C2, C3
        {'from': 2, 'to': 3}, // B0 -> C0
        {'from': 2, 'to': 32}, // B0 -> C1
        {'from': 2, 'to': 26}, // B0 -> C2
        {'from': 2, 'to': 33}, // B0 -> C3
      ],
      'animatedEdges': [
        {'from': 19, 'to': 50}, // A0 -> B0
        {'from': 50, 'to': 51}, // A0 -> B1
        {'from': 51, 'to': 52},
        {'from': 52, 'to': 53},
      ],
    };

    // Usage code (as in your example)
    var edges = json['edges']!;
    edges.forEach((element) {
      var fromNodeId = element['from'];
      var toNodeId = element['to'];
      graph.addEdge(Node.Id(fromNodeId), Node.Id(toNodeId));
    });

    var ghostEdges = json['ghostEdges']!;
    ghostEdges.forEach((element) {
      var fromNodeId = element['from'];
      var toNodeId = element['to'];
      graph.addEdge(Node.Id(fromNodeId), Node.Id(toNodeId),
          ghost: true, paint: Paint()..color = Colors.lightGreen);
    });

    var animatedEdges = json['animatedEdges']!;
    animatedEdges.forEach((element) {
      var fromNodeId = element['from'];
      var toNodeId = element['to'];
      EdgeAnimation? animation;

      switch (fromNodeId) {
        case 19:
          animation = EdgeAnimation(shape: EdgeAnimationShape.triangle);
          break;
        case 50:
          animation = EdgeAnimation(shape: EdgeAnimationShape.square);
          break;
        case 51:
          animation = EdgeAnimation(shape: EdgeAnimationShape.circle);
          break;
        case 52:
          animation = EdgeAnimation(icon: textPainter);
      }
      graph.addEdge(Node.Id(fromNodeId), Node.Id(toNodeId),
          animation: animation, paint: Paint()..color = Colors.purpleAccent);
    });

    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

    // Initialize with default algorithm
    _updateAlgorithm();
  }
}
