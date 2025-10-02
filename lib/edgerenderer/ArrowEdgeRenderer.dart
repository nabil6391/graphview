part of graphview;

const double ARROW_DEGREES = 0.5;
const double ARROW_LENGTH = 10;

class ArrowEdgeRenderer extends EdgeRenderer {
  var trianglePath = Path();
  final bool noArrow;

  ArrowEdgeRenderer({this.noArrow = false});

  Offset _getNodeCenter(Node node) {
    final nodePosition = getNodePosition(node);
    return Offset(
      nodePosition.dx + node.width * 0.5,
      nodePosition.dy + node.height * 0.5,
    );
  }

  void render(Canvas canvas, Graph graph, Paint paint) {
    graph.edges.forEach((edge) {
      renderEdge(canvas, edge, paint);
    });
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    var source = edge.source;
    var destination = edge.destination;

    var sourceOffset = getNodePosition(source);
    var destinationOffset = getNodePosition(destination);

    var startX = sourceOffset.dx + source.width * 0.5;
    var startY = sourceOffset.dy + source.height * 0.5;
    var stopX = destinationOffset.dx + destination.width * 0.5;
    var stopY = destinationOffset.dy + destination.height * 0.5;

    var clippedLine = clipLineEnd(
        startX,
        startY,
        stopX,
        stopY,
        destinationOffset.dx,
        destinationOffset.dy,
        destination.width,
        destination.height);

    final currentPaint = edge.paint ?? paint;

    if (noArrow) {
      // Draw line without arrow, respecting line type
      drawStyledLine(
        canvas,
        Offset(clippedLine[0], clippedLine[1]),
        Offset(clippedLine[2], clippedLine[3]),
        currentPaint,
        lineType: _getLineType(destination),
      );
    } else {
      var trianglePaint = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;

      // Draw line with arrow
      Paint? edgeTrianglePaint;
      if (edge.paint != null) {
        edgeTrianglePaint = Paint()
          ..color = edge.paint?.color ?? paint.color
          ..style = PaintingStyle.fill;
      }

      var triangleCentroid = drawTriangle(
          canvas,
          edgeTrianglePaint ?? trianglePaint,
          clippedLine[0],
          clippedLine[1],
          clippedLine[2],
          clippedLine[3]);

      // Draw the line with the appropriate style
      drawStyledLine(
        canvas,
        Offset(clippedLine[0], clippedLine[1]),
        triangleCentroid,
        currentPaint,
        lineType: _getLineType(destination),
      );
    }
  }

  /// Helper to get line type from node data if available
  LineType? _getLineType(Node node) {
    // This assumes you have a way to access node data
    // You may need to adjust this based on your actual implementation
    if (node is SugiyamaNodeData) {
      return node.lineType;
    }
    return null;
  }

  Offset drawTriangle(Canvas canvas, Paint paint, double lineStartX,
      double lineStartY, double arrowTipX, double arrowTipY) {
    // Calculate direction from line start to arrow tip, then flip 180° to point backwards from tip
    var lineDirection =
    (atan2(arrowTipY - lineStartY, arrowTipX - lineStartX) + pi);

    // Calculate the two base points of the arrowhead triangle
    var leftWingX =
    (arrowTipX + ARROW_LENGTH * cos((lineDirection - ARROW_DEGREES)));
    var leftWingY =
    (arrowTipY + ARROW_LENGTH * sin((lineDirection - ARROW_DEGREES)));
    var rightWingX =
    (arrowTipX + ARROW_LENGTH * cos((lineDirection + ARROW_DEGREES)));
    var rightWingY =
    (arrowTipY + ARROW_LENGTH * sin((lineDirection + ARROW_DEGREES)));

    // Draw the triangle: tip -> left wing -> right wing -> back to tip
    trianglePath.moveTo(arrowTipX, arrowTipY); // Arrow tip
    trianglePath.lineTo(leftWingX, leftWingY); // Left wing
    trianglePath.lineTo(rightWingX, rightWingY); // Right wing
    trianglePath.close(); // Back to tip
    canvas.drawPath(trianglePath, paint);

    // Calculate center point of the triangle
    var triangleCenterX = (arrowTipX + leftWingX + rightWingX) / 3;
    var triangleCenterY = (arrowTipY + leftWingY + rightWingY) / 3;

    trianglePath.reset();
    return Offset(triangleCenterX, triangleCenterY);
  }

  List<double> clipLineEnd(
      double startX,
      double startY,
      double stopX,
      double stopY,
      double destX,
      double destY,
      double destWidth,
      double destHeight) {
    var clippedStopX = stopX;
    var clippedStopY = stopY;

    if (startX == stopX && startY == stopY) {
      return [startX, startY, clippedStopX, clippedStopY];
    }

    var slope = (startY - stopY) / (startX - stopX);
    final halfHeight = destHeight * 0.5;
    final halfWidth = destWidth * 0.5;

    // Check vertical edge intersections
    if (startX != stopX) {
      final halfSlopeWidth = slope * halfWidth;
      if (halfSlopeWidth.abs() <= halfHeight) {
        if (destX > startX) {
          // Left edge intersection
          return [startX, startY, stopX - halfWidth, stopY - halfSlopeWidth];
        } else if (destX < startX) {
          // Right edge intersection
          return [startX, startY, stopX + halfWidth, stopY + halfSlopeWidth];
        }
      }
    }

    // Check horizontal edge intersections
    if (startY != stopY && slope != 0) {
      final halfSlopeHeight = halfHeight / slope;
      if (halfSlopeHeight.abs() <= halfWidth) {
        if (destY < startY) {
          // Bottom edge intersection
          clippedStopX = stopX + halfSlopeHeight;
          clippedStopY = stopY + halfHeight;
        } else if (destY > startY) {
          // Top edge intersection
          clippedStopX = stopX - halfSlopeHeight;
          clippedStopY = stopY - halfHeight;
        }
      }
    }

    return [startX, startY, clippedStopX, clippedStopY];
  }

  List<double> clipLine(double startX, double startY, double stopX,
      double stopY, Node destination) {
    final resultLine = [startX, startY, stopX, stopY];

    if (startX == stopX && startY == stopY) return resultLine;

    var slope = (startY - stopY) / (startX - stopX);
    final halfHeight = destination.height * 0.5;
    final halfWidth = destination.width * 0.5;

    // Check vertical edge intersections
    if (startX != stopX) {
      final halfSlopeWidth = slope * halfWidth;
      if (halfSlopeWidth.abs() <= halfHeight) {
        if (destination.x > startX) {
          // Left edge intersection
          resultLine[2] = stopX - halfWidth;
          resultLine[3] = stopY - halfSlopeWidth;
          return resultLine;
        } else if (destination.x < startX) {
          // Right edge intersection
          resultLine[2] = stopX + halfWidth;
          resultLine[3] = stopY + halfSlopeWidth;
          return resultLine;
        }
      }
    }

    // Check horizontal edge intersections
    if (startY != stopY && slope != 0) {
      final halfSlopeHeight = halfHeight / slope;
      if (halfSlopeHeight.abs() <= halfWidth) {
        if (destination.y < startY) {
          // Bottom edge intersection
          resultLine[2] = stopX + halfSlopeHeight;
          resultLine[3] = stopY + halfHeight;
        } else if (destination.y > startY) {
          // Top edge intersection
          resultLine[2] = stopX - halfSlopeHeight;
          resultLine[3] = stopY - halfHeight;
        }
      }
    }

    return resultLine;
  }
}
