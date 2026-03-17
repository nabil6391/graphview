import 'package:flutter/material.dart';
import 'package:graphview/graph_view.dart';
import 'package:graphview/elk_layout/elk_algorithm.dart';

class ElkGraphViewPage extends StatefulWidget {
  const ElkGraphViewPage({Key? key}) : super(key: key);

  @override
  State<ElkGraphViewPage> createState() => _ElkGraphViewPageState();
}

class _ElkGraphViewPageState extends State<ElkGraphViewPage>
    with TickerProviderStateMixin {
  final Graph graph = Graph()..isTree = false;
  late final ELKAlgorithm _algorithm;
  late final GraphViewController _controller;
  late final AnimationController _edgeController;
  late final Animation<double> edgeAnimation;
  bool _layoutReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _controller = GraphViewController();

    // Edge animation controller (repeats forever)
    _edgeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    edgeAnimation = CurvedAnimation(
      parent: _edgeController,
      curve: Curves.linear,
    );
    _edgeController.repeat();

    _algorithm = ELKAlgorithm(
      layoutOptions: {
        'elk.algorithm': 'radial',
        'elk.radial.radius': '150',
        'elk.radial.compactor': 'WEDGE_COMPACTION',
        'elk.spacing.nodeNode': '60',
      },
      renderer: ArrowEdgeRenderer(animation: edgeAnimation),
    );

    _buildGraphAndComputeLayout();
  }

  @override
  void dispose() {
    _edgeController.dispose();
    super.dispose();
  }

  Future<void> _buildGraphAndComputeLayout() async {
    _generateGraph();

    try {
      await _algorithm.computeLayout(graph);
      if (mounted) setState(() => _layoutReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _generateGraph() {
    final root = Node.Id('Root');

    final hubs = <Node>[
      Node.Id('Hub A'),
      Node.Id('Hub B'),
      Node.Id('Hub C'),
      Node.Id('Hub D'),
    ];

    for (final hub in hubs) {
      graph.addEdge(root, hub);
    }

    int leafId = 0;
    for (final hub in hubs) {
      for (int i = 0; i < 5; i++) {
        final leaf = Node.Id('L${leafId++}');
        graph.addEdge(hub, leaf);
      }
    }

    // --- Animated edges (shapes traveling along the edge) ---
    graph.addEdge(
      Node.Id('L10'),
      Node.Id('L11'),
      animation: EdgeAnimation(shape: EdgeAnimationShape.circle),
      paint: Paint()
        ..color = Colors.purpleAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    graph.addEdge(
      Node.Id('L9'),
      Node.Id('L8'),
      animation: EdgeAnimation(shape: EdgeAnimationShape.triangle),
      paint: Paint()
        ..color = Colors.deepOrange
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    graph.addEdge(
      Node.Id('L7'),
      Node.Id('L8'),
      animation: EdgeAnimation(shape: EdgeAnimationShape.triangle),
      paint: Paint()
        ..color = Colors.deepOrange
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    graph.addEdge(
      Node.Id('L0'),
      Node.Id('L1'),
      animation: EdgeAnimation(shape: EdgeAnimationShape.square),
      paint: Paint()
        ..color = Colors.teal
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // --- Ghost edges (rendered but not part of tree structure) ---
    graph.addEdge(
      Node.Id('L1'),
      Node.Id('L10'),
      paint: Paint()
        ..color = Colors.lightGreen
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    graph.addEdge(
      Node.Id('L3'),
      Node.Id('L15'),
      paint: Paint()
        ..color = Colors.lightGreen
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    graph.addEdge(
      Node.Id('L7'),
      Node.Id('L18'),
      paint: Paint()
        ..color = Colors.lightGreen
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ELK JS Layout (Web)')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
          child: Text('Error: $_error',
              style: const TextStyle(color: Colors.red)));
    }

    if (!_layoutReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return GraphView.builder(
      graph: graph,
      algorithm: _algorithm,
      controller: _controller,
      trackpadScrollCausesScale: true,
      edgeAnimation: edgeAnimation,
      paint: Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
      builder: (Node node) {
        final label = node.key?.value.toString() ?? '';
        final isHub = label.startsWith('Hub') || label == 'Root';
        final isCollapsed = _controller.isNodeCollapsed(node);

        return InkWell(
          onTap: () {
            _controller.toggleNodeExpanded(graph, node, animate: true);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isHub ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHub ? Colors.blue : Colors.grey[300]!,
                width: isHub ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isHub ? FontWeight.bold : FontWeight.normal,
                    color: Colors.grey[800],
                  ),
                ),
                if (graph.hasSuccessor(node)) ...[
                  const SizedBox(width: 6),
                  Icon(
                    isCollapsed
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
                    size: 16,
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
