part of graphview;

/// Abstract base class for rendering edges between nodes on a canvas.
///
/// Provides shared utilities for line styling ([drawStyledLine], [drawStyledPath]),
/// self-loop path construction ([buildSelfLoopPath]), and node position lookups.
abstract class EdgeRenderer {
  Map<Node, Offset>? _animatedPositions;

  /// Sets animated positions used during collapse/expand transitions.
  void setAnimatedPositions(Map<Node, Offset> positions) => _animatedPositions = positions;

  /// Returns the current position of [node], using animated position if available.
  Offset getNodePosition(Node node) => _animatedPositions?[node] ?? node.position;

  /// Renders a single [edge] on the [canvas] using the given [paint].
  void renderEdge(Canvas canvas, Edge edge, Paint paint);

  /// Returns the center point of [node] based on its position and size.
  Offset getNodeCenter(Node node) {
    final nodePosition = getNodePosition(node);
    return Offset(
      nodePosition.dx + node.width * 0.5,
      nodePosition.dy + node.height * 0.5,
    );
  }

  /// Draws a line between two points respecting the node's line type
  void drawStyledLine(Canvas canvas, Offset start, Offset end, Paint paint,
      {LineType? lineType}) {
    switch (lineType) {
      case LineType.DashedLine:
        drawDashedLine(canvas, start, end, paint, 0.6);
        break;
      case LineType.DottedLine:
        drawDashedLine(canvas, start, end, paint, 0.0);
        break;
      case LineType.SineLine:
        drawSineLine(canvas, start, end, paint);
        break;
      default:
        canvas.drawLine(start, end, paint);
        break;
    }
  }

  /// Draws a styled path respecting the node's line type
  void drawStyledPath(Canvas canvas, Path path, Paint paint,
      {LineType? lineType}) {
    if (lineType == null || lineType == LineType.Default) {
      canvas.drawPath(path, paint);
    } else {
      // For non-solid lines, we need to convert the path to segments
      // This is a simplified approach - for complex paths with curves,
      // you might need a more sophisticated solution
      canvas.drawPath(path, paint);
    }
  }

  /// Draws a dashed line between two points
  void drawDashedLine(Canvas canvas, Offset source, Offset destination,
      Paint paint, double lineLength) {
    final dx = destination.dx - source.dx;
    final dy = destination.dy - source.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance == 0) return;

    final numLines = lineLength == 0.0 ? (distance / 5).ceil() : 14;
    final stepX = dx / numLines;
    final stepY = dy / numLines;

    if (lineLength == 0.0) {
      // Draw dots
      final circleRadius = 1.0;
      final circlePaint = Paint()
        ..color = paint.color
        ..strokeWidth = 1.0
        ..style = PaintingStyle.fill;

      for (var i = 0; i < numLines; i++) {
        final x = source.dx + (i * stepX);
        final y = source.dy + (i * stepY);
        canvas.drawCircle(Offset(x, y), circleRadius, circlePaint);
      }
    } else {
      // Draw dashes
      for (var i = 0; i < numLines; i++) {
        final startX = source.dx + (i * stepX);
        final startY = source.dy + (i * stepY);
        final endX = startX + (stepX * lineLength);
        final endY = startY + (stepY * lineLength);
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      }
    }
  }

  /// Draws a sine wave line between two points
  void drawSineLine(Canvas canvas, Offset source, Offset destination, Paint paint) {
    final originalStrokeWidth = paint.strokeWidth;
    paint.strokeWidth = 1.5;

    final dx = destination.dx - source.dx;
    final dy = destination.dy - source.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance == 0 || (dx == 0 && dy == 0)) {
      paint.strokeWidth = originalStrokeWidth;
      return;
    }

    const lineLength = 6.0;
    const phaseOffset = 2.0;
    var distanceTraveled = 0.0;
    var phase = 0.0;

    final path = Path()..moveTo(source.dx, source.dy);

    while (distanceTraveled < distance) {
      final segmentLength = min(lineLength, distance - distanceTraveled);
      final segmentFraction = (distanceTraveled + segmentLength) / distance;
      final segmentDestination = Offset(
        source.dx + dx * segmentFraction,
        source.dy + dy * segmentFraction,
      );

      final waveAmplitude = sin(phase + phaseOffset) * segmentLength;

      double perpX, perpY;
      if ((dx > 0 && dy < 0) || (dx < 0 && dy > 0)) {
        perpX = waveAmplitude;
        perpY = waveAmplitude;
      } else {
        perpX = -waveAmplitude;
        perpY = waveAmplitude;
      }

      path.lineTo(segmentDestination.dx + perpX, segmentDestination.dy + perpY);

      distanceTraveled += segmentLength;
      phase += pi * segmentLength / lineLength;
    }

    canvas.drawPath(path, paint);
    paint.strokeWidth = originalStrokeWidth;
  }

  /// Builds a loop path for self-referential edges and returns geometry
  /// data that renderers can use to draw arrows or style the segment.
  LoopRenderResult? buildSelfLoopPath(
    Edge edge, {
    double loopPadding = 16.0,
    double arrowLength = 12.0,
  }) {
    if (edge.source != edge.destination) {
      return null;
    }

    final node = edge.source;
    final nodeCenter = getNodeCenter(node);

    final anchorRadius = node.size.shortestSide * 0.5;

    final start = nodeCenter + Offset(anchorRadius, 0);

    final end = nodeCenter + Offset(0, -anchorRadius);

    final loopRadius = max(
      loopPadding + anchorRadius,
      anchorRadius * 1.5,
    );

    final controlPoint1 = start + Offset(loopRadius, 0);

    final controlPoint2 = end + Offset(0, -loopRadius);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        end.dx,
        end.dy,
      );

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) {
      return LoopRenderResult(path, start, end);
    }

    final metric = metrics.first;
    final totalLength = metric.length;
    final effectiveArrowLength = arrowLength <= 0
        ? 0.0
        : min(arrowLength, totalLength * 0.3);
    final arrowBaseOffset = max(0.0, totalLength - effectiveArrowLength);
    final arrowBaseTangent = metric.getTangentForOffset(arrowBaseOffset);
    final arrowTipTangent = metric.getTangentForOffset(totalLength);

    return LoopRenderResult(
      path,
      arrowBaseTangent?.position ?? end,
      arrowTipTangent?.position ?? end,
    );
  }
}

/// Result of building a self-loop edge path, containing geometry for arrow rendering.
class LoopRenderResult {
  /// The cubic Bezier path forming the loop arc.
  final Path path;

  /// The position where the arrowhead base starts.
  final Offset arrowBase;

  /// The position of the arrowhead tip.
  final Offset arrowTip;

  /// Creates a loop render result with the given [path], [arrowBase], and [arrowTip].
  const LoopRenderResult(this.path, this.arrowBase, this.arrowTip);
}
