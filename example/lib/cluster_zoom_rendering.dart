import 'package:flutter/material.dart';
import 'package:graphview/graph_view.dart';

class ClusterZoomRendering extends StatefulWidget {
  @override
  _ClusterZoomRenderingState createState() => _ClusterZoomRenderingState();
}

class _ClusterZoomRenderingState extends State<ClusterZoomRendering> {
  final Graph fullGraph = Graph()..isTree = true;
  final Graph clusterGraph = Graph()..isTree = true;

  late final GraphViewController _graphController;
  late final TransformationController _transformationController;

  final double _zoomThreshold = 0.6;
  bool _isZoomedOut = false;

  final Map<int, List<int>> clusters = {
    1: [13, 21, 4, 3, 22],
    3: [5, 23],
    4: [5, 6],
    6: [8, 16],
    8: [10],
    10: [13, 14, 15],
  };

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    // Initialize controller first so it's ready for setup
    _graphController = GraphViewController(
      transformationController: _transformationController,
    );

    _setupGraphs();

    _transformationController.addListener(_handleZoomChange);
  }

  void _handleZoomChange() {
    if (!mounted) return;

    final double scale = _transformationController.value.row0[0];
    final bool shouldBeZoomedOut = scale < _zoomThreshold;

    if (shouldBeZoomedOut != _isZoomedOut) {
      // Hiding children by default in the cluster graph after the first frame

      setState(() {
        _isZoomedOut = shouldBeZoomedOut;
      });
    }
  }

  void _setupGraphs() {
    final nodes = List.generate(100, (index) => Node.Id(index));

    void addBackboneEdge(int s, int d) {
      fullGraph.addEdge(nodes[s], nodes[d]);
      clusterGraph.addEdge(nodes[s], nodes[d]);
    }

    addBackboneEdge(1, 3);
    addBackboneEdge(1, 4);
    addBackboneEdge(4, 6);
    addBackboneEdge(6, 8);
    addBackboneEdge(8, 10);

    // Full graph details
    fullGraph.addEdge(nodes[1], nodes[13]);
    fullGraph.addEdge(nodes[3], nodes[5]);
    fullGraph.addEdge(nodes[10], nodes[14]);
    fullGraph.addEdge(nodes[10], nodes[15]);
    fullGraph.addEdge(nodes[6], nodes[16]);
    fullGraph.addEdge(nodes[21], nodes[23]);
    fullGraph.addEdge(nodes[1], nodes[21]);
    fullGraph.addEdge(nodes[1], nodes[22]);

    // Build clusterGraph with the cluster's children as requested
    clusters.forEach((parentId, childIds) {
      for (var childId in childIds) {
        clusterGraph.addEdge(nodes[parentId], nodes[childId]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Normalized Hybrid Graph')),
      body: GraphView.builder(
        graph: _isZoomedOut ? clusterGraph : fullGraph,
        controller: _graphController,
        trackpadScrollCausesScale: true,
        algorithm: SugiyamaAlgorithm(
          SugiyamaConfiguration()
            ..levelSeparation = _isZoomedOut ? 200 : 150
            ..nodeSeparation = _isZoomedOut ? 160 : 100
            ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM,
        ),
        paint: Paint()
          ..color = Colors.blueGrey
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
        builder: (Node node) => _buildNode(node),
      ),
    );
  }

  Widget _buildNode(Node node) {
    final int id = node.key!.value;
    final bool isClusterHead = clusters.containsKey(id);

    return GestureDetector(
      onTap: () {
        setState(() {
          // Toggle successors on the graph currently in use
          _graphController.toggleNodeExpanded(
            _isZoomedOut ? clusterGraph : fullGraph,
            node,
          );
        });
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Container(
          constraints: BoxConstraints(
            minWidth: _isZoomedOut ? 150 : 80,
            minHeight: _isZoomedOut ? 150 : 80,
          ),
          child: _isZoomedOut && isClusterHead
              ? _buildMassiveCluster(id)
              : _buildDetailCard(id),
        ),
      ),
    );
  }

  Widget _buildMassiveCluster(int id) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black26)],
      ),
      child: Center(
        child: Text(
          '+${clusters[id]?.length ?? 0}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(int id) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, size: 24, color: Colors.blueAccent),
          Text(
            'ID $id',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
