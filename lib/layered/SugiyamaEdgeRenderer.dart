part of graphview;

class SugiyamaEdgeRenderer extends ArrowEdgeRenderer {
  Map<Node, SugiyamaNodeData> nodeData;
  Map<Edge, SugiyamaEdgeData> edgeData;

  SugiyamaEdgeRenderer(this.nodeData, this.edgeData);
  var path = Path();

  @override
  void render(Canvas canvas, Graph? graph, Paint? paint) {
    var trianglePaint = Paint()
      ..color = paint!.color
      ..style = PaintingStyle.fill;

    graph!.edges.forEach((edge) {
      final source = edge.source;

      var x = source.x;
      var y = source.y;

      var destination = edge.destination;

      var x1 = destination.x;
      var y1 = destination.y;
      path.reset();

      var clippedLine = <double>[];

      Paint? edgeTrianglePaint;
      if (edge.paint != null) {
        edgeTrianglePaint = Paint()
          ..color = edge.paint!.color
          ..style = PaintingStyle.fill;
      }

      Paint? p = edge.paint ?? paint
        ..style = PaintingStyle.stroke;

      if (edgeData.containsKey(edge) && edgeData[edge]!.bendPoints.isNotEmpty) {
        // draw bend points
        var bendPoints = edgeData[edge]!.bendPoints;
        final size = bendPoints.length;

        if (nodeData[source]!.isReversed) {
          clippedLine = clipLine(bendPoints[2], bendPoints[3], bendPoints[0],
              bendPoints[1], destination);
        } else {
          clippedLine = clipLine(bendPoints[size - 4], bendPoints[size - 3],
              bendPoints[size - 2], bendPoints[size - 1], destination);
        }

        final triangleCentroid = drawTriangle(
            canvas,
            edgeTrianglePaint ?? trianglePaint,
            clippedLine[0],
            clippedLine[1],
            clippedLine[2],
            clippedLine[3]);

        path.reset();
        path.moveTo(bendPoints[0], bendPoints[1]);

        for (var i = 3; i < size - 2; i = i + 2) {
          path.lineTo(bendPoints[i - 1], bendPoints[i]);
        }

        path.lineTo(triangleCentroid[0], triangleCentroid[1]);
        canvas.drawPath(path, p);
      } else {
        final startX = x + source.width / 2;
        final startY = y + source.height / 2;
        final stopX = x1 + destination.width / 2;
        final stopY = y1 + destination.height / 2;

        clippedLine = clipLine(startX, startY, stopX, stopY, destination);

        final triangleCentroid = drawTriangle(
            canvas,
            edgeTrianglePaint ?? trianglePaint,
            clippedLine[0],
            clippedLine[1],
            clippedLine[2],
            clippedLine[3]);

        canvas.drawLine(Offset(clippedLine[0], clippedLine[1]),
            Offset(triangleCentroid[0], triangleCentroid[1]), p);
      }
    });
  }
}
