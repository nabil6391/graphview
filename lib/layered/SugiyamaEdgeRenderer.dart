part of graphview;

class SugiyamaEdgeRenderer extends ArrowEdgeRenderer {
  Map<Node, SugiyamaNodeData> nodeData;
  Map<Edge, SugiyamaEdgeData> edgeData;
  BendPointShape bendPointShape;
  bool addTriangleToEdge;
  var path = Path();

  SugiyamaEdgeRenderer(this.nodeData, this.edgeData, this.bendPointShape, this.addTriangleToEdge);

  bool hasBendEdges(Edge edge) => edgeData.containsKey(edge) && edgeData[edge]!.bendPoints.isNotEmpty;

  void render(Canvas canvas, Graph graph, Paint paint) {
    graph.edges.forEach((edge) {
      renderEdge(canvas, edge, paint);
    });
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    var trianglePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

      Paint? edgeTrianglePaint;
      if (edge.paint != null) {
        edgeTrianglePaint = Paint()
          ..color = edge.paint?.color ?? paint.color
          ..style = PaintingStyle.fill;
      }

      var currentPaint = edge.paint ?? paint
        ..style = PaintingStyle.stroke;

      if (hasBendEdges(edge)) {
        _renderEdgeWithBendPoints(canvas, edge, currentPaint, edgeTrianglePaint ?? trianglePaint);
      } else {
        _renderStraightEdge(canvas, edge, currentPaint, edgeTrianglePaint ?? trianglePaint);
      }
    }

  void _renderEdgeWithBendPoints(Canvas canvas, Edge edge, Paint currentPaint, Paint trianglePaint) {
    final source = edge.source;
    final destination = edge.destination;
    var bendPoints = edgeData[edge]!.bendPoints;

    var sourceCenter = _getNodeCenter(source);

    // Calculate the transition/offset from the original bend point to animated position
    final transitionDx = sourceCenter.dx - bendPoints[0];
    final transitionDy = sourceCenter.dy - bendPoints[1];

    path.reset();
    path.moveTo(sourceCenter.dx, sourceCenter.dy);

    final bendPointsWithoutDuplication = <Offset>[];

    for (var i = 0; i < bendPoints.length; i += 2) {
      final isLastPoint = i == bendPoints.length - 2;

      // Apply the same transition to all bend points
      final x = bendPoints[i] + transitionDx;
      final y = bendPoints[i + 1] + transitionDy;
      final x2 = isLastPoint ? -1 : bendPoints[i + 2] + transitionDx;
      final y2 = isLastPoint ? -1 : bendPoints[i + 3] + transitionDy;

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

    var descOffset = getNodePosition(destination);
    var stopX = descOffset.dx + destination.width * 0.5;
    var stopY = descOffset.dy + destination.height * 0.5;

    if (addTriangleToEdge) {
      var clippedLine = <double>[];
      final size = bendPoints.length;
      if (nodeData[source]!.isReversed) {
        clippedLine = clipLineEnd(bendPoints[2], bendPoints[3], stopX, stopY, destination.x,
            destination.y, destination.width, destination.height);
      } else {
        clippedLine = clipLineEnd(bendPoints[size - 4], bendPoints[size - 3],
            stopX, stopY, descOffset.dx,
            descOffset.dy, destination.width, destination.height);
      }
      final triangleCentroid = drawTriangle(canvas, trianglePaint, clippedLine[0], clippedLine[1], clippedLine[2], clippedLine[3]);
      path.lineTo(triangleCentroid.dx, triangleCentroid.dy);
    } else {
      path.lineTo(stopX, stopY);
    }
    canvas.drawPath(path, currentPaint);
  }

  void _renderStraightEdge(Canvas canvas, Edge edge, Paint currentPaint, Paint trianglePaint) {
    final source = edge.source;
    final destination = edge.destination;
    final sourceCenter = _getNodeCenter(source);
    var destCenter = _getNodeCenter(destination);

    if (addTriangleToEdge) {
      final clippedLine = clipLineEnd(sourceCenter.dx, sourceCenter.dy,
          destCenter.dx, destCenter.dy, destination.x,
          destination.y, destination.width, destination.height);

      destCenter = drawTriangle(canvas, trianglePaint, clippedLine[0], clippedLine[1], clippedLine[2], clippedLine[3]);
    }

    // Draw the line with appropriate line type using the base class method
    final lineType = nodeData[destination]?.lineType;
    drawStyledLine(canvas, sourceCenter, destCenter, currentPaint, lineType: lineType);
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

      if (previousNode != null && ((currentNode.dx == nextNode.dx && nextNode.dx == afterNextNode.dx) || (currentNode.dy == nextNode.dy && nextNode.dy == afterNextNode.dy))) {
        path.lineTo(nextNode.dx, nextNode.dy);
      } else {
        path.lineTo(arcStartPoint.dx, arcStartPoint.dy);
        path.quadraticBezierTo(nextNode.dx, nextNode.dy, arcEndPoint.dx, arcEndPoint.dy);
      }
    }
  }
}