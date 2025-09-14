part of graphview;

abstract class EdgeRenderer {
  Map<Node, Offset>? _animatedPositions;

  void setAnimatedPositions(Map<Node, Offset> positions) => _animatedPositions = positions;

  Offset getNodePosition(Node node) => _animatedPositions?[node] ?? node.position;

  void render(Canvas canvas, Graph graph, Paint paint);
}