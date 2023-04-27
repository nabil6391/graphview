part of graphview;

class SugiyamaEdgeRenderer extends ArrowEdgeRenderer {
  Map<Node, SugiyamaNodeData> nodeData;
  Map<Edge, SugiyamaEdgeData> edgeData;
  BendPointShape bendPointShape;

  SugiyamaEdgeRenderer(this.nodeData, this.edgeData, this.bendPointShape);

  var path = Path();

  @override
  void render(Canvas canvas, Graph graph, Paint paint) {
    var trianglePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    graph.edges.forEach((edge) {
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
          ..color = edge.paint?.color ?? paint.color
          ..style = PaintingStyle.fill;
      }

      var currentPaint = edge.paint ?? paint
        ..style = PaintingStyle.stroke;

      if (edgeData.containsKey(edge) && edgeData[edge]!.bendPoints.isNotEmpty) {
        // draw bend points
        var bendPoints = edgeData[edge]!.bendPoints;
        final size = bendPoints.length;

        if (nodeData[source]!.isReversed) {
          clippedLine = clipLine(bendPoints[2], bendPoints[3], bendPoints[0], bendPoints[1], destination);
        } else {
          clippedLine = clipLine(
              bendPoints[size - 4], bendPoints[size - 3], bendPoints[size - 2], bendPoints[size - 1], destination);
        }

        final triangleCentroid = drawTriangle(
            canvas, edgeTrianglePaint ?? trianglePaint, clippedLine[0], clippedLine[1], clippedLine[2], clippedLine[3]);

        path.reset();
        path.moveTo(bendPoints[0], bendPoints[1]);

        final bendPointsWithoutDuplication = <Offset>[];

        for (var i = 0; i < bendPoints.length; i += 2) {
          final isLastPoint = i == bendPoints.length - 2;

          final x = bendPoints[i];
          final y = bendPoints[i + 1];
          final x2 = isLastPoint ? -1 : bendPoints[i + 2];
          final y2 = isLastPoint ? -1 : bendPoints[i + 3];
          if (x == x2 && y == y2) {
            // Skip when two consecutive points are identical
            // because drawing a line between would be redundant in this case.
            continue;
          }
          bendPointsWithoutDuplication.add(Offset(x, y));
        }

        if (bendPointShape is MaxCurvedBendPointShape) {
          _drawMaxCurvedBendPointsEdge(bendPointsWithoutDuplication);
        } else if (bendPointShape is CurvedBendPointShape) {
          final shape = bendPointShape as CurvedBendPointShape;
          _drawCurvedBendPointsEdge(bendPointsWithoutDuplication, shape.curveLength);
        } else {
          _drawSharpBendPointsEdge(bendPointsWithoutDuplication);
        }

        path.lineTo(triangleCentroid[0], triangleCentroid[1]);
        canvas.drawPath(path, currentPaint);
      } else {
        final startX = x + source.width / 2;
        final startY = y + source.height / 2;
        final stopX = x1 + destination.width / 2;
        final stopY = y1 + destination.height / 2;

        clippedLine = clipLine(startX, startY, stopX, stopY, destination);

        final triangleCentroid = drawTriangle(
            canvas, edgeTrianglePaint ?? trianglePaint, clippedLine[0], clippedLine[1], clippedLine[2], clippedLine[3]);

        canvas.drawLine(
            Offset(clippedLine[0], clippedLine[1]), Offset(triangleCentroid[0], triangleCentroid[1]), currentPaint);
      }
    });
  }

  void _drawSharpBendPointsEdge(List<Offset> bendPoints) {
    for (var i = 1; i < bendPoints.length - 1; i++) {
      path.lineTo(bendPoints[i].dx, bendPoints[i].dy);
    }
  }

  void _drawMaxCurvedBendPointsEdge(List<Offset> bendPoints) {
    for (var i = 1; i < bendPoints.length - 1; i++) {
      final nextNode = bendPoints[i];
      final afterNextNode = bendPoints[i + 1];
      final curveEndPoint = Offset((nextNode.dx + afterNextNode.dx) / 2, (nextNode.dy + afterNextNode.dy) / 2);
      path.quadraticBezierTo(nextNode.dx, nextNode.dy, curveEndPoint.dx, curveEndPoint.dy);
    }
  }

  void _drawCurvedBendPointsEdge(List<Offset> bendPoints, double curveLength) {
    for (var i = 1; i < bendPoints.length - 1; i++) {
      final previousNode = i == 1 ? null : bendPoints[i - 2];
      final currentNode = bendPoints[i - 1];
      final nextNode = bendPoints[i];
      final afterNextNode = bendPoints[i + 1];

      final arcStartPointRadians = atan2(nextNode.dy - currentNode.dy, nextNode.dx - currentNode.dx);
      final arcStartPoint = nextNode - Offset.fromDirection(arcStartPointRadians, curveLength);
      final arcEndPointRadians = atan2(nextNode.dy - afterNextNode.dy, nextNode.dx - afterNextNode.dx);
      final arcEndPoint = nextNode - Offset.fromDirection(arcEndPointRadians, curveLength);

      if (previousNode != null &&
          ((currentNode.dx == nextNode.dx && nextNode.dx == afterNextNode.dx) ||
              (currentNode.dy == nextNode.dy && nextNode.dy == afterNextNode.dy))) {
        path.lineTo(nextNode.dx, nextNode.dy);
      } else {
        path.lineTo(arcStartPoint.dx, arcStartPoint.dy);
        path.quadraticBezierTo(nextNode.dx, nextNode.dy, arcEndPoint.dx, arcEndPoint.dy);
      }
    }
  }
}
