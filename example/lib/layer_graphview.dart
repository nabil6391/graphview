import 'dart:math';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class LayeredGraphViewPage extends StatefulWidget {
  @override
  _LayeredGraphViewPageState createState() => _LayeredGraphViewPageState();
}

class _LayeredGraphViewPageState extends State<LayeredGraphViewPage> {
  final GraphViewController _controller = GraphViewController();
  final Random r = Random();
  int nextNodeId = 0;
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Graph Visualizer', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showControls ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showControls = !_showControls),
            tooltip: 'Toggle Controls',
          ),
          IconButton(
            icon: Icon(Icons.shuffle),
            onPressed: _navigateToRandomNode,
            tooltip: 'Random Node',
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _showControls ? null : 0,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 300),
              opacity: _showControls ? 1.0 : 0.0,
              child: _buildControlPanel(),
            ),
          ),
          Expanded(child: _buildGraphView()),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          _buildNumericControls(),
          SizedBox(height: 16),
          _buildShapeControls(),
        ],
      ),
    );
  }

  Widget _buildNumericControls() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildSliderControl('Node Sep', builder.nodeSeparation, 5, 50, (v) => builder.nodeSeparation = v),
        _buildSliderControl('Level Sep', builder.levelSeparation, 5, 100, (v) => builder.levelSeparation = v),
        _buildDropdown<CoordinateAssignment>('Alignment', builder.coordinateAssignment, CoordinateAssignment.values, (v) => builder.coordinateAssignment = v),
        _buildDropdown<LayeringStrategy>('Layering', builder.layeringStrategy, LayeringStrategy.values, (v) => builder.layeringStrategy = v),
        _buildDropdown<CrossMinimizationStrategy>('Cross Min', builder.crossMinimizationStrategy, CrossMinimizationStrategy.values, (v) => builder.crossMinimizationStrategy = v),
        _buildDropdown<CycleRemovalStrategy>('Cycle Removal', builder.cycleRemovalStrategy, CycleRemovalStrategy.values, (v) => builder.cycleRemovalStrategy = v),
      ],
    );
  }

  Widget _buildSliderControl(String label, int value, int min, int max, Function(int) onChanged) {
    return Container(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Slider(
            value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: value.toString(),
            onChanged: (v) => setState(() => onChanged(v.round())),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>(String label, T value, List<T> items, Function(T) onChanged) {
    return Container(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toString().split('.').last, style: TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) => setState(() => onChanged(v!)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Edge Shape', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Row(
          children: [
            _buildShapeButton('Sharp', builder.bendPointShape is SharpBendPointShape, () => builder.bendPointShape = SharpBendPointShape()),
            SizedBox(width: 8),
            _buildShapeButton('Curved', builder.bendPointShape is CurvedBendPointShape, () => builder.bendPointShape = CurvedBendPointShape(curveLength: 20)),
            SizedBox(width: 8),
            _buildShapeButton('Max Curved', builder.bendPointShape is MaxCurvedBendPointShape, () => builder.bendPointShape = MaxCurvedBendPointShape()),
            Spacer(),
            Row(
              children: [
                Text('Post Straighten', style: TextStyle(fontSize: 12)),
                Switch(
                  value: builder.postStraighten,
                  onChanged: (v) => setState(() => builder.postStraighten = v),
                  activeThumbColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShapeButton(String text, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: () => setState(onPressed),
      child: Text(text, style: TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[100],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        elevation: isSelected ? 2 : 0,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildGraphView() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GraphView.builder(
          controller: _controller,
          graph: graph,
          algorithm: SugiyamaAlgorithm(builder),
          paint: Paint()
            ..color = Colors.blue[300]!
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
          builder: (Node node) {
            final nodeId = node.key!.value as int;
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.blue[100]!, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Center(
                child: Text('$nodeId', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            );
          },
        ),
      ),
    );
  }

  final Graph graph = Graph();
  SugiyamaConfiguration builder = SugiyamaConfiguration()
    ..bendPointShape = CurvedBendPointShape(curveLength: 20)
    ..nodeSeparation = 15
    ..levelSeparation = 15
    ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

  void _navigateToRandomNode() {
    if (graph.nodes.isEmpty) return;
    final randomNode = graph.nodes[r.nextInt(graph.nodes.length)];
    _controller.animateToNode(randomNode.key!);
  }

  @override
  void initState() {
    super.initState();
    _initializeGraph();
  }

  void _initializeGraph() {
    // Define edges more concisely
    final node1 = Node.Id(1);
    final node2 = Node.Id(2);
    final node3 = Node.Id(3);
    final node4 = Node.Id(4);
    final node5 = Node.Id(5);
    final node6 = Node.Id(6);
    final node8 = Node.Id(7);
    final node7 = Node.Id(8);
    final node9 = Node.Id(9);
    final node10 = Node.Id(10);
    final node11 = Node.Id(11);
    final node12 = Node.Id(12);
    final node13 = Node.Id(13);
    final node14 = Node.Id(14);
    final node15 = Node.Id(15);
    final node16 = Node.Id(16);
    final node17 = Node.Id(17);
    final node18 = Node.Id(18);
    final node19 = Node.Id(19);
    final node20 = Node.Id(20);
    final node21 = Node.Id(21);
    final node22 = Node.Id(22);
    final node23 = Node.Id(23);

    graph.addEdge(node1, node13, paint: Paint()..color = Colors.red);
    graph.addEdge(node1, node21);
    graph.addEdge(node1, node4);
    graph.addEdge(node1, node3);
    graph.addEdge(node2, node3);
    graph.addEdge(node2, node20);
    graph.addEdge(node3, node4);
    graph.addEdge(node3, node5);
    graph.addEdge(node3, node23);
    graph.addEdge(node4, node6);
    graph.addEdge(node5, node7);
    graph.addEdge(node6, node8);
    graph.addEdge(node6, node16);
    graph.addEdge(node6, node23);
    graph.addEdge(node7, node9);
    graph.addEdge(node8, node10);
    graph.addEdge(node8, node11);
    graph.addEdge(node9, node12);
    graph.addEdge(node10, node13);
    graph.addEdge(node10, node14);
    graph.addEdge(node10, node15);
    graph.addEdge(node11, node15);
    graph.addEdge(node11, node16);
    graph.addEdge(node12, node20);
    graph.addEdge(node13, node17);
    graph.addEdge(node14, node17);
    graph.addEdge(node14, node18);
    graph.addEdge(node16, node18);
    graph.addEdge(node16, node19);
    graph.addEdge(node16, node20);
    graph.addEdge(node18, node21);
    graph.addEdge(node19, node22);
    graph.addEdge(node21, node23);
    graph.addEdge(node22, node23);
    graph.addEdge(node1, node22);
    graph.addEdge(node7, node8);
  }
}