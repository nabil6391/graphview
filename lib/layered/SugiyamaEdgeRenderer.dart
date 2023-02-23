part of graphview;

class SugiyamaEdgeRenderer extends ArrowEdgeRenderer {
  Map<Node, SugiyamaNodeData> nodeData;
  Map<Edge, SugiyamaEdgeData> edgeData;
  BendPointShape bendPointShape;
  bool addTriangleToEdge;

  SugiyamaEdgeRenderer(this.nodeData, this.edgeData, this.bendPointShape, this.addTriangleToEdge);

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

        if (addTriangleToEdge) {
          final triangleCentroid = drawTriangle(
              canvas, edgeTrianglePaint ?? trianglePaint, clippedLine[0], clippedLine[1], clippedLine[2], clippedLine[3]);

          path.lineTo(triangleCentroid[0], triangleCentroid[1]);
        } else {
          final stopX = x1 + destination.width / 2;
          final stopY = y1 + destination.height / 2;
          path.lineTo(stopX, stopY);
        }
        // path.lineTo(triangleCentroid[0], triangleCentroid[1]);
        path.lineTo(triangleCentroid[0], triangleCentroid[1]);
        canvas.drawPath(path, currentPaint);
      } else {
        final startX = x + source.width / 2;
        final startY = y + source.height / 2;
        final stopX = x1 + destination.width / 2;
        final stopY = y1 + destination.height / 2;

        clippedLine = clipLine(startX, startY, stopX, stopY, destination);

        if (addTriangleToEdge) {
          final triangleCentroid = drawTriangle(
              canvas, edgeTrianglePaint ?? trianglePaint, clippedLine[0],
              clippedLine[1], clippedLine[2], clippedLine[3]);

          canvas.drawLine(
              Offset(clippedLine[0], clippedLine[1]), Offset(triangleCentroid[0], triangleCentroid[1]), currentPaint);
        } else {
          canvas.drawLine(
              Offset(clippedLine[0], clippedLine[1]), Offset(stopX, stopY), currentPaint);
        // final triangleCentroid = drawTriangle(
        //     canvas, edgeTrianglePaint ?? trianglePaint, clippedLine[0], clippedLine[1], clippedLine[2], clippedLine[3]);

        // canvas.drawLine(
        //     Offset(clippedLine[0], clippedLine[1]), Offset(triangleCentroid[0], triangleCentroid[1]), currentPaint);

        switch (nodeData[destination]?.lineType.toUpperCase()) {
          case 'DASHEDLINE':
            _drawDashedLine(canvas, Offset(clippedLine[0], clippedLine[1]), Offset(stopX, stopY), currentPaint, 0.6);
            break;
          case 'DOTTEDLINE':
            _drawDashedLine(canvas, Offset(clippedLine[0], clippedLine[1]), Offset(stopX, stopY), currentPaint, 0.0);
            break;
          case 'SINELINE':
            _drawSineLine(canvas, Offset(clippedLine[0], clippedLine[1]), Offset(stopX, stopY), currentPaint);
            break;
          default:
            canvas.drawLine(Offset(clippedLine[0], clippedLine[1]), Offset(stopX, stopY), currentPaint);
            break;
        }
      }
    }});
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

  void _drawDashedLine(Canvas canvas, Offset source, Offset destination, Paint paint, double lineLength) {
    var numLines = 14;

    // lineLength == 0.0 to use dotted lines
    if (lineLength == 0.0) {
      numLines = 40;
    }

    // Calculate the distance between the source and destination points
    var dx = destination.dx - source.dx;
    var dy = destination.dy - source.dy;

    // Calculate the step size for each line
    var stepX = dx / numLines;
    var stepY = dy / numLines;

    // Draw the lines between the two points
    Iterable<int>.generate(numLines).map((i) {
      var startX = source.dx + (i * stepX);
      var startY = source.dy + (i * stepY);
      var endX = startX + (stepX * lineLength);
      var endY = startY + (stepY * lineLength);
      return [Offset(startX, startY), Offset(endX, endY)];
    }).forEach((points) => canvas.drawLine(points[0], points[1], paint));
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
        } else { // dx < 0 && dy < 0
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
