part of graphview;

const double ARROW_DEGREES = 0.5;
const double ARROW_LENGTH = 10;

class ArrowEdgeRenderer extends EdgeRenderer {
  var trianglePath = Path();

  @override
  void render(Canvas canvas, Graph graph, Paint paint) {
    var trianglePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    graph.edges.forEach((edge) {
      var source = edge.source;
      var destination = edge.destination;

      var sourceOffset = source.position;

      var x1 = sourceOffset.dx;
      var y1 = sourceOffset.dy;

      var destinationOffset = destination.position;

      var x2 = destinationOffset.dx;
      var y2 = destinationOffset.dy;

      var startX = x1 + source.width / 2;
      var startY = y1 + source.height / 2;
      var stopX = x2 + destination.width / 2;
      var stopY = y2 + destination.height / 2;

      var clippedLine = clipLine(startX, startY, stopX, stopY, destination);

      Paint? edgeTrianglePaint;
      if (edge.paint != null) {
        edgeTrianglePaint = Paint()
          ..color = edge.paint?.color ?? paint.color
          ..style = PaintingStyle.fill;
      }

      var triangleCentroid = drawTriangle(
          canvas, edgeTrianglePaint ?? trianglePaint, clippedLine[0], clippedLine[1], clippedLine[2], clippedLine[3]);

      canvas.drawLine(Offset(clippedLine[0], clippedLine[1]), Offset(triangleCentroid[0], triangleCentroid[1]),
          edge.paint ?? paint);
    });
  }

  List<double> drawTriangle(Canvas canvas, Paint paint, double x1, double y1, double x2, double y2) {
    var angle = (atan2(y2 - y1, x2 - x1) + pi);
    var x3 = (x2 + ARROW_LENGTH * cos((angle - ARROW_DEGREES)));
    var y3 = (y2 + ARROW_LENGTH * sin((angle - ARROW_DEGREES)));
    var x4 = (x2 + ARROW_LENGTH * cos((angle + ARROW_DEGREES)));
    var y4 = (y2 + ARROW_LENGTH * sin((angle + ARROW_DEGREES)));
    trianglePath.moveTo(x2, y2); // Top;
    trianglePath.lineTo(x3, y3); // Bottom left
    trianglePath.lineTo(x4, y4); // Bottom right
    trianglePath.close();
    canvas.drawPath(trianglePath, paint);

    // calculate centroid of the triangle
    var x = (x2 + x3 + x4) / 3;
    var y = (y2 + y3 + y4) / 3;
    var triangleCentroid = [x, y];
    trianglePath.reset();
    return triangleCentroid;
  }

  List<double> clipLine(double startX, double startY, double stopX, double stopY, Node destination) {
    var resultLine = List.filled(4, 0.0);
    resultLine[0] = startX;
    resultLine[1] = startY;

    var slope = (startY - stopY) / (startX - stopX);
    var halfHeight = destination.height / 2;
    var halfWidth = destination.width / 2;
    var halfSlopeWidth = slope * halfWidth;
    var halfSlopeHeight = halfHeight / slope;

    if (-halfHeight <= halfSlopeWidth && halfSlopeWidth <= halfHeight) {
      // line intersects with ...
      if (destination.x > startX) {
        // left edge
        resultLine[2] = stopX - halfWidth;
        resultLine[3] = stopY - halfSlopeWidth;
      } else if (destination.x < startX) {
        // right edge
        resultLine[2] = stopX + halfWidth;
        resultLine[3] = stopY + halfSlopeWidth;
      }
    }

    if (-halfWidth <= halfSlopeHeight && halfSlopeHeight <= halfWidth) {
      // line intersects with ...
      if (destination.y < startY) {
        // bottom edge
        resultLine[2] = stopX + halfSlopeHeight;
        resultLine[3] = stopY + halfHeight;
      } else if (destination.y > startY) {
        // top edge
        resultLine[2] = stopX - halfSlopeHeight;
        resultLine[3] = stopY - halfHeight;
      }
    }

    return resultLine;
  }
}
