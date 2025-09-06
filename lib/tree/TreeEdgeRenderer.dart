part of graphview;

class TreeEdgeRenderer extends EdgeRenderer {
  BuchheimWalkerConfiguration configuration;

  TreeEdgeRenderer(this.configuration);

  var linePath = Path();

  @override
  void render(Canvas canvas, Graph graph, Paint paint) {
    var levelSeparationHalf = configuration.levelSeparation * 0.5;

    graph.nodes.forEach((node) {
      var children = graph.successorsOf(node);

      children.forEach((child) {
        var edge = graph.getEdgeBetween(node, child);
        var edgePaint = (edge?.paint ?? paint)..style = PaintingStyle.stroke;
        final parentOffset = getNodePosition(node);
        final childOffset = getNodePosition(child);

        final parentCenterX = parentOffset.dx + node.width * 0.5;
        final parentCenterY = parentOffset.dy + node.height * 0.5;
        final childCenterX = childOffset.dx + child.width * 0.5;
        final childCenterY = childOffset.dy + child.height * 0.5;

        linePath.reset();

        switch (configuration.orientation) {
          case BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM:
            _drawLShapedPath(
                childCenterX,
                childOffset.dy,
                childCenterX,
                childOffset.dy - levelSeparationHalf,
                parentCenterX,
                childOffset.dy - levelSeparationHalf,
                parentCenterX,
                parentOffset.dy + node.height);
            break;
          case BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP:
            _drawLShapedPath(
                childCenterX,
                childOffset.dy + child.height,
                childCenterX,
                childOffset.dy + child.height + levelSeparationHalf,
                parentCenterX,
                childOffset.dy + child.height + levelSeparationHalf,
                parentCenterX,
                parentOffset.dy + node.height);
            break;

          case BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT:
            _drawLShapedPath(
                childOffset.dx,
                childCenterY,
                childOffset.dx - levelSeparationHalf,
                childCenterY,
                childOffset.dx - levelSeparationHalf,
                parentCenterY,
                parentOffset.dx + node.width,
                parentCenterY);
            break;

          case BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT:
            _drawLShapedPath(
                childOffset.dx + child.width,
                childCenterY,
                childOffset.dx + child.width + levelSeparationHalf,
                childCenterY,
                childOffset.dx + child.width + levelSeparationHalf,
                parentCenterY,
                parentOffset.dx + node.width,
                parentCenterY);
            break;
        }
        canvas.drawPath(linePath, edgePaint);
      });
    });
  }

  void _drawLShapedPath(double x1, double y1, double x2, double y2, double x3,
      double y3, double x4, double y4) {
    linePath
      ..moveTo(x1, y1)
      ..lineTo(x2, y2)
      ..lineTo(x3, y3)
      ..moveTo(x3, y3)
      ..lineTo(x4, y4);
  }
}
