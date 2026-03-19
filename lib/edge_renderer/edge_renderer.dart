import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:graphview/graph.dart';

abstract class EdgeRenderer {
  @protected
  Map<Node, Offset>? animatedPositions;

  void setAnimatedPositions(Map<Node, Offset> positions) =>
      animatedPositions = positions;

  Offset getNodePosition(Node node) =>
      animatedPositions?[node] ?? node.position;

  void renderEdge(Canvas canvas, Edge edge, Paint paint);

  void render(Canvas canvas, Graph graph, Paint paint);

  Offset getNodeCenter(Node node) {
    final nodePosition = getNodePosition(node);
    return Offset(
      nodePosition.dx + node.width * 0.5,
      nodePosition.dy + node.height * 0.5,
    );
  }

  /// Draws a dashed path along a complex path
  void drawDashedPath(Canvas canvas, Path path, Paint paint,
      {double dashWidth = 10, double dashSpace = 10}) {
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
    final dx = destination.dx - source.dx;
    final dy = destination.dy - source.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance == 0) return;

    final sinePath = Path();
    sinePath.moveTo(source.dx, source.dy);

    const stepSize = 2.0;
    const waveLength = 20.0;
    const amplitude = 4.0;

    for (var i = 0.0; i < distance; i += stepSize) {
      final x = source.dx + (dx * i / distance);
      final y = source.dy + (dy * i / distance);

      // Add sine offset perpendicular to the line direction
      final angle = atan2(dy, dx);
      final offsetX = amplitude * sin(2 * pi * i / waveLength) * sin(angle);
      final offsetY = -amplitude * sin(2 * pi * i / waveLength) * cos(angle);

      sinePath.lineTo(x + offsetX, y + offsetY);
    }

    canvas.drawPath(sinePath, paint);
  }

  void drawStyledPath(Canvas canvas, Path path, Paint paint,
      {LineType lineType = LineType.Default}) {
    switch (lineType) {
      case LineType.DashedLine:
        drawDashedPath(canvas, path, paint);
        break;
      case LineType.DottedLine:
        drawDashedPath(canvas, path, paint, dashWidth: 2, dashSpace: 4);
        break;
      case LineType.Default:
      default:
        canvas.drawPath(path, paint);
        break;
    }
  }

  void drawStyledLine(
      Canvas canvas, Offset source, Offset destination, Paint paint,
      {LineType lineType = LineType.Default}) {
    switch (lineType) {
      case LineType.DashedLine:
        drawDashedLine(canvas, source, destination, paint, 1.0);
        break;
      case LineType.DottedLine:
        drawDashedLine(canvas, source, destination, paint, 0.0);
        break;
      case LineType.Default:
      default:
        canvas.drawLine(source, destination, paint);
        break;
    }
  }

  EdgeSelfLoopResult? buildSelfLoopPath(Edge edge, {double arrowLength = 0}) {
    final node = edge.source;
    final position = getNodePosition(node);
    final center = Offset(
      position.dx + node.width * 0.5,
      position.dy + node.height * 0.5,
    );

    final loopPath = Path();
    final loopRadius = node.width * 0.4;

    // Start from the top-middle of the node
    final start = Offset(center.dx, position.dy);

    // Points for a "teardrop" loop above the node
    final cp1 = Offset(center.dx - loopRadius * 2, position.dy - loopRadius * 2);
    final cp2 = Offset(center.dx + loopRadius * 2, position.dy - loopRadius * 2);

    loopPath.moveTo(start.dx, start.dy);
    loopPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, start.dx, start.dy);

    // If no arrow needed, return the path with dummy offsets
    if (arrowLength == 0) {
        return EdgeSelfLoopResult(
            path: loopPath,
            arrowBase: start,
            arrowTip: start,
        );
    }

    // To place an arrow at the end, we need a slightly shortened path
    final metrics = loopPath.computeMetrics().toList();
    if (metrics.isEmpty) return null;

    final metric = metrics.first;
    final totalLength = metric.length;

    // Find the tip position (almost at the end of the loop)
    final tipPos = metric.getTangentForOffset(totalLength - 1.0);
    // Find the base of the arrow (a few pixels back)
    final basePos = metric.getTangentForOffset(totalLength - arrowLength - 1.0);

    if (tipPos == null || basePos == null) return null;

    return EdgeSelfLoopResult(
      path: metric.extractPath(0, totalLength - arrowLength),
      arrowBase: basePos.position,
      arrowTip: tipPos.position,
    );
  }
}

class EdgeSelfLoopResult {
  final Path path;
  final Offset arrowBase;
  final Offset arrowTip;

  EdgeSelfLoopResult({
    required this.path,
    required this.arrowBase,
    required this.arrowTip,
  });
}
