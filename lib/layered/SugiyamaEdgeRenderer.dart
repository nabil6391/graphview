part of graphview;

class SugiyamaEdgeRenderer extends ArrowEdgeRenderer {
  Map<Node, SugiyamaNodeData> nodeData;
  Map<Edge, SugiyamaEdgeData> edgeData;
  BendPointShape bendPointShape;
  bool addTriangleToEdge;
  var path = Path();

  SugiyamaEdgeRenderer(this.nodeData, this.edgeData, this.bendPointShape, this.addTriangleToEdge);

  bool hasBendEdges(Edge edge) => edgeData.containsKey(edge) && edgeData[edge]!.bendPoints.isNotEmpty;

  @override
  void render(Canvas canvas, Graph graph, Paint paint) {
    var trianglePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    graph.edges.forEach((edge) {
      final source = edge.source;
      final destination = edge.destination;

      Paint? edgeTrianglePaint;
      if (edge.paint != null) {
        edgeTrianglePaint = Paint()
          ..color = edge.paint?.color ?? paint.color
          ..style = PaintingStyle.fill;
      }

      var currentPaint = edge.paint ?? paint
        ..style = PaintingStyle.stroke;

      if (hasBendEdges(edge)) {
        _renderEdgeWithBendPoints(canvas, edge, source, destination, currentPaint, edgeTrianglePaint ?? trianglePaint);
      } else {
        _renderStraightEdge(canvas, edge, source, destination, currentPaint, edgeTrianglePaint ?? trianglePaint);
      }
    });
  }

  void _renderEdgeWithBendPoints(Canvas canvas, Edge edge, Node source,
      Node destination, Paint currentPaint, Paint trianglePaint) {
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
        clippedLine = clipLineEnd(bendPoints[2], bendPoints[3],  stopX, stopY, destination.x ,
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

  void _renderStraightEdge(Canvas canvas, Edge edge, Node source,
      Node destination, Paint currentPaint, Paint trianglePaint) {
    final sourceCenter = _getNodeCenter(source);
    var destCenter = _getNodeCenter(destination);

    if (addTriangleToEdge) {
      final clippedLine = clipLineEnd(sourceCenter.dx, sourceCenter.dy,
          destCenter.dx, destCenter.dy, destination.x,
          destination.y, destination.width, destination.height);

      destCenter = drawTriangle(canvas, trianglePaint, clippedLine[0], clippedLine[1], clippedLine[2], clippedLine[3]);
    }

    // Draw the line
    switch (nodeData[destination]?.lineType) {
      case LineType.DashedLine:
        _drawDashedLine(canvas, sourceCenter, destCenter, currentPaint, 0.6);
        break;
      case LineType.DottedLine:
        // dotted line uses the same method as dashed line, but with a lineLength of 0.0
        _drawDashedLine(canvas, sourceCenter, destCenter, currentPaint, 0.0);
        break;
      case LineType.SineLine:
        _drawSineLine(canvas, sourceCenter, destCenter, currentPaint);
        break;
      default:
        canvas.drawLine(sourceCenter, destCenter, currentPaint);
        break;
    }
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

  void _drawDashedLine(Canvas canvas, Offset source, Offset destination,
      Paint paint, double lineLength) {
    var dx = destination.dx - source.dx;
    var dy = destination.dy - source.dy;

    // Calculate the Euclidean distance
    var distance = sqrt(dx * dx + dy * dy);

    var numLines = lineLength == 0.0 ? (distance / 5).ceil() : 14;

    // Calculate the step size for each line
    var stepX = dx / numLines;
    var stepY = dy / numLines;

    var circleRadius = 1.0;

    var circleStrokeWidth = 1.0;
    var circlePaint = Paint()
      ..color = paint.color
      ..strokeWidth = circleStrokeWidth
      ..style = PaintingStyle.fill; // Change to fill style

    // Draw the lines or dots between the two points
    for (var i = 0; i < numLines; i++) {
      var startX = source.dx + (i * stepX);
      var startY = source.dy + (i * stepY);
      if (lineLength == 0.0) {
        // Draw a dot with a fixed radius and stroke width
        canvas.drawCircle(Offset(startX, startY), circleRadius, circlePaint);
      } else {
        // Draw a dash
        var endX = startX + (stepX * lineLength);
        var endY = startY + (stepY * lineLength);
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      }
    }
  }

  void _drawSineLine(Canvas canvas, Offset source, Offset destination, Paint paint) {
    paint..strokeWidth = 1.5;

    final dx = destination.dx - source.dx;
    final dy = destination.dy - source.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final lineLength = 6;
    var phaseOffset = 2;

    // Verify dx and dy to avoid NaN to Offset()
    if (dx != 0 || dy != 0) {
      var distanceTraveled = 0.0;
      var phase = 0.0;
      final path = Path()..moveTo(source.dx, source.dy);

      while (distanceTraveled < distance) {
        final segmentLength = min(lineLength, distance - distanceTraveled);
        final segmentFraction = segmentLength / distance;
        final segmentDestination = Offset(
          source.dx + dx * segmentFraction,
          source.dy + dy * segmentFraction,
        );

        final y = sin(phase + phaseOffset) * segmentLength;

        num x;
        if ((dx > 0 && dy < 0) || (dx < 0 && dy > 0)) {
          x = sin(phase + phaseOffset) * segmentLength;
        } else {
          // dx < 0 && dy < 0
          x = -sin(phase + phaseOffset) * segmentLength;
        }

        path.lineTo(segmentDestination.dx + x, segmentDestination.dy + y);

        distanceTraveled += segmentLength;
        source = segmentDestination;
        phase += pi * segmentLength / lineLength;
      }
      canvas.drawPath(path, paint);
    }
  }
}
