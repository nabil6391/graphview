import 'package:flutter/material.dart';
import 'package:graphview/graph_view.dart';

class ZoomBasedRendering extends StatefulWidget {
  @override
  _ZoomBasedRenderingState createState() => _ZoomBasedRenderingState();
}

class _ZoomBasedRenderingState extends State<ZoomBasedRendering> {
  final Graph fullGraph = Graph()..isTree = true;
  final Graph clusterGraph = Graph()..isTree = true;

  // We use late and don't re-initialize to keep the reference stable
  late final GraphViewController _graphController;
  late final TransformationController _transformationController;

  final double _zoomThreshold = 0.6;
  bool _isZoomedOut = false;

  final Map<int, List<int>> clusters = {
    1: [13, 21, 4, 3, 22],
    3: [5, 23],
    4: [5],
    6: [8, 16],
    8: [13],
    10: [13, 14, 15],
  };

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _setupGraphs();

    // Use a robust listener
    _transformationController.addListener(_handleZoomChange);

    _graphController = GraphViewController(
      transformationController: _transformationController,
    );
  }

  void _handleZoomChange() {
    // Check mounted to avoid the "disposed" error
    if (!mounted) return;

    final double scale = _transformationController.value.row0[0];
    final bool shouldBeZoomedOut = scale < _zoomThreshold;

    if (shouldBeZoomedOut != _isZoomedOut) {
      setState(() {
        _isZoomedOut = shouldBeZoomedOut;
      });
    }
  }

  void _setupGraphs() {
    final nodes = List.generate(1000, (index) => Node.Id(index));

    // Full Detail Graph
    fullGraph.addEdge(nodes[1], nodes[3]);
    fullGraph.addEdge(nodes[1], nodes[4]);
    fullGraph.addEdge(nodes[4], nodes[6]);
    fullGraph.addEdge(nodes[6], nodes[8]);
    fullGraph.addEdge(nodes[8], nodes[10]);
    fullGraph.addEdge(nodes[1], nodes[13]);
    fullGraph.addEdge(nodes[3], nodes[5]);
    fullGraph.addEdge(nodes[10], nodes[14]);
    fullGraph.addEdge(nodes[21], nodes[23]);

    // Cluster Graph
    clusterGraph.addEdge(nodes[1], nodes[3]);
    clusterGraph.addEdge(nodes[1], nodes[4]);
    clusterGraph.addEdge(nodes[4], nodes[6]);
    clusterGraph.addEdge(nodes[6], nodes[8]);
    clusterGraph.addEdge(nodes[8], nodes[10]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zoom Based Rendering')),
      body: Column(
        children: [
          TextButton(
            onPressed: () {
              fullGraph.addEdge(Node.Id(1), Node.Id(5));
              _graphController.forceRecalculation();
            },
            child: Text('Add Edge'),
          ),
          Expanded(
            child: GraphView.builder(
              // IMPORTANT: Removed the ValueKey from here.
              // Swapping the graph object inside a stable GraphView prevents controller disposal errors.
              graph: _isZoomedOut ? clusterGraph : fullGraph,
              controller: _graphController,
              trackpadScrollCausesScale: true,
              algorithm: SugiyamaAlgorithm(
                SugiyamaConfiguration()
                  // We increase separation when zoomed out to accommodate the 140px bubbles
                  ..levelSeparation = _isZoomedOut ? 180 : 100
                  ..nodeSeparation = _isZoomedOut ? 160 : 80
                  ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM,
              ),
              paint: Paint()
                ..color = Colors.blueGrey.withValues(alpha: 0.4)
                ..strokeWidth = 2
                ..style = PaintingStyle.stroke,
              builder: (Node node) => _buildNode(node),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(Node node) {
    final int id = node.key!.value;
    final bool isClusterHead = clusters.containsKey(id);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      // This transition ensures that the node scales from its center
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      // If we are zoomed out but the node is NOT a cluster head,
      // we return a tiny placeholder to keep the layout engine happy
      // without showing a card.
      child: Container(
        constraints: BoxConstraints(
          minWidth: _isZoomedOut ? 150 : 70,
          minHeight: _isZoomedOut ? 150 : 70,
        ),
        child: _isZoomedOut && isClusterHead
            ? _buildMassiveCluster(id)
            : _buildDetailCard(id),
      ),
    );
  }

  Widget _buildMassiveCluster(int id) {
    return Container(
      key: ValueKey('massive_cluster_$id'),
      width: 150, // Your significantly bigger size
      height: 150,
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black26)],
      ),
      child: Center(
        child: Text(
          "+${clusters[id]?.length ?? 0}",
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
      key: ValueKey('detail_$id'),
      // Detail cards are much smaller than the clusters
      width: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, size: 20, color: Colors.blueAccent),
          Text('ID $id', style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}
