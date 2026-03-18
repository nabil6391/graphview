import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/graph.dart';

abstract class EdgeRenderer {
  Map<Node, Offset>? _animatedPositions;
  Animation<double>? edgeAnimation;
  Animation<double>? animation;

  EdgeRenderer({this.animation});

  void setAnimatedPositions(Map<Node, Offset> positions) =>
      _animatedPositions = positions;

  Offset getNodePosition(Node node) =>
      _animatedPositions?[node] ?? node.position;

  void renderEdge(Canvas canvas, Edge edge, Paint paint);

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
      return;
    }

    final dashWidth = lineType == LineType.DottedLine ? 2.0 : 6.0;
    final dashSpace = lineType == LineType.DottedLine ? 4.0 : 4.0;

    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  /// Draws a dashed line between two points
  void drawDashedLine(Canvas canvas, Offset source, Offset destination,
      Paint paint, double lineLengthFactor) {
    final dx = destination.dx - source.dx;
    final dy = destination.dy - source.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance == 0) return;

    final dashWidth = lineLengthFactor == 0.0 ? 2.0 : 10.0;
    final dashSpace = lineLengthFactor == 0.0 ? 4.0 : 10.0;

    var currentDist = 0.0;
    final dirX = dx / distance;
    final dirY = dy / distance;

    while (currentDist < distance) {
      final startX = source.dx + dirX * currentDist;
      final startY = source.dy + dirY * currentDist;

      final actualDashWidth = min(dashWidth, distance - currentDist);
      final endX = startX + dirX * actualDashWidth;
      final endY = startY + dirY * actualDashWidth;

      if (lineLengthFactor == 0.0) {
        canvas.drawCircle(Offset(startX, startY), 1.0,
            Paint()..color = paint.color..style = PaintingStyle.fill);
      } else {
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      }

      currentDist += dashWidth + dashSpace;
    }
  }

  /// Draws a sine wave line between two points
  void drawSineLine(
      Canvas canvas, Offset source, Offset destination, Paint paint) {
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
    final effectiveArrowLength =
        arrowLength <= 0 ? 0.0 : min(arrowLength, totalLength * 0.3);
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

class LoopRenderResult {
  final Path path;
  final Offset arrowBase;
  final Offset arrowTip;

  const LoopRenderResult(this.path, this.arrowBase, this.arrowTip);
}
