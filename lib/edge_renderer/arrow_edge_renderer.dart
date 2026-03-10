import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/edge_renderer/edge_renderer.dart';
import 'package:graphview/graph.dart';
import 'package:graphview/layered/sugiyama_node_data.dart';

const double ARROW_DEGREES = 0.5;
const double ARROW_LENGTH = 10;

class ArrowEdgeRenderer extends EdgeRenderer {
  var trianglePath = Path();
  final bool noArrow;
  final Animation<double>? animation;
  final Map<Edge, Path> renderedPaths = {};

  ArrowEdgeRenderer({this.noArrow = false, this.animation});

  bool _shouldAnimate(Edge edge) => edge.animation != null;

  @override
  Offset getNodeCenter(Node node) {
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

    final currentPaint = (edge.paint ?? paint)..style = PaintingStyle.stroke;
    final lineType =
        edge.ghost ? LineType.DottedLine : _getLineType(destination);
    var edgePath = Path();

    if (source == destination) {
      final loopResult = buildSelfLoopPath(
        edge,
        arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
      );

      if (loopResult != null) {
        drawStyledPath(canvas, loopResult.path, currentPaint,
            lineType: lineType);
        edgePath = loopResult.path;

        if (!noArrow) {
          final trianglePaint = Paint()
            ..color = edge.paint?.color ?? paint.color
            ..style = PaintingStyle.fill;
          final triangleCentroid = drawTriangle(
            canvas,
            trianglePaint,
            loopResult.arrowBase.dx,
            loopResult.arrowBase.dy,
            loopResult.arrowTip.dx,
            loopResult.arrowTip.dy,
          );

          drawStyledLine(
            canvas,
            loopResult.arrowBase,
            triangleCentroid,
            currentPaint,
            lineType: lineType,
          );
        }

        return;
      }
    }

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

    edgePath.moveTo(clippedLine[0], clippedLine[1]);
    edgePath.lineTo(clippedLine[2], clippedLine[3]);

    renderedPaths[edge] = edgePath;

    if (noArrow) {
      // Draw line without arrow, respecting line type
      drawStyledLine(
        canvas,
        Offset(clippedLine[0], clippedLine[1]),
        Offset(clippedLine[2], clippedLine[3]),
        currentPaint,
        lineType: lineType,
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
        lineType: lineType,
      );
    }

    if (_shouldAnimate(edge)) {
      switch (edge.animation!.shape) {
        case EdgeAnimationShape.circle:
          _drawAnimatedCircle(canvas, edgePath, currentPaint, animation!.value);
          break;
        case EdgeAnimationShape.square:
          _drawAnimatedSquare(canvas, edgePath, currentPaint, animation!.value);
          break;
        case EdgeAnimationShape.triangle:
          _drawAnimatedTriangle(
              canvas, edgePath, currentPaint, animation!.value);
          break;
        case null:
          break;
      }
      if (edge.animation!.icon != null) {
        _drawAnimatedIcon(
            canvas, edgePath, edge.animation!.icon!, animation!.value);
      }
    }

    if (edge.interactive) {
      final metrics = edgePath.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;

        // Get the exact center coordinate of the path
        final tangent = metric.getTangentForOffset(metric.length / 2.0);

        if (tangent != null) {
          final center = tangent.position;

          // 2. Draw a filled circle (the "button" background)
          final dotPaint = Paint()
            ..color = edge.interactiveFillColor ?? currentPaint.color
            ..style = PaintingStyle.fill;
          canvas.drawCircle(center, 3.0, dotPaint);

          // 3. Draw a border around it to make it pop off the line
          final borderPaint = Paint()
            ..color = edge.interactiveBorderColor ?? Colors.white
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke;
          canvas.drawCircle(center, 3.0, borderPaint);
        }
      }
    }
  }

  void _drawAnimatedCircle(
      Canvas canvas, Path path, Paint edgePaint, double progress) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    double totalLength = 0;
    for (var m in metrics) {
      totalLength += m.length;
    }

    var targetDistance = totalLength * progress;
    double currentDistance = 0;

    for (var metric in metrics) {
      if (currentDistance + metric.length >= targetDistance) {
        final localDistance = targetDistance - currentDistance;
        final tangent = metric.getTangentForOffset(localDistance);

        if (tangent != null) {
          canvas.drawCircle(
            tangent.position,
            4.0,
            edgePaint..style = PaintingStyle.fill,
          );
        }
        break;
      }
      currentDistance += metric.length;
    }
  }

  void _drawAnimatedIcon(
    Canvas canvas,
    Path path,
    TextPainter iconPainter,
    double progress,
  ) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    double totalLength = 0;
    for (var m in metrics) {
      totalLength += m.length;
    }

    var targetDistance = totalLength * progress;
    double currentDistance = 0;

    for (var metric in metrics) {
      if (currentDistance + metric.length >= targetDistance) {
        final localDistance = targetDistance - currentDistance;
        final tangent = metric.getTangentForOffset(localDistance);

        if (tangent != null) {
          canvas.save();
          canvas.translate(tangent.position.dx, tangent.position.dy);
          iconPainter.paint(
            canvas,
            Offset(-iconPainter.width / 2, -iconPainter.height / 2),
          );
          canvas.restore();
        }
        break;
      }
      currentDistance += metric.length;
    }
  }

  void _drawAnimatedTriangle(
      Canvas canvas, Path path, Paint edgePaint, double progress) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    double totalLength = 0;
    for (var m in metrics) {
      totalLength += m.length;
    }

    var targetDistance = totalLength * progress;
    double currentDistance = 0;

    for (var metric in metrics) {
      if (currentDistance + metric.length >= targetDistance) {
        final localDistance = targetDistance - currentDistance;
        final tangent = metric.getTangentForOffset(localDistance);

        if (tangent != null) {
          const sideLength = 10.0;
          final height = (sqrt(3) / 2) * sideLength;

          canvas.save();
          canvas.translate(tangent.position.dx, tangent.position.dy);
          canvas.rotate(-tangent.angle + pi / 2);

          final trianglePath = Path();
          trianglePath.moveTo(0, -height / 2);
          trianglePath.lineTo(sideLength / 2, height / 2);
          trianglePath.lineTo(-sideLength / 2, height / 2);
          trianglePath.close();

          canvas.drawPath(
            trianglePath,
            Paint.from(edgePaint)..style = PaintingStyle.fill,
          );
          canvas.restore();
        }
        break;
      }
      currentDistance += metric.length;
    }
  }

  void _drawAnimatedSquare(
      Canvas canvas, Path path, Paint edgePaint, double progress) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    // 1. Calculate the total distance covered by the animation
    double totalLength = 0;
    for (var m in metrics) {
      totalLength += m.length;
    }

    var targetDistance = totalLength * progress;
    double currentDistance = 0;

    for (var metric in metrics) {
      if (currentDistance + metric.length >= targetDistance) {
        // 2. Extract the position and tangent (angle) at the current progress
        final localDistance = targetDistance - currentDistance;
        final tangent = metric.getTangentForOffset(localDistance);

        if (tangent != null) {
          final center = tangent.position;
          final angle =
              -tangent.angle; // Adjusting for Canvas coordinate system

          canvas.save();
          // 3. Move and rotate the canvas to the square's position
          canvas.translate(center.dx, center.dy);
          canvas.rotate(angle);

          final squarePaint = Paint()
            ..color = edgePaint.color
            ..style = PaintingStyle.fill;

          const side = 8.0; // Size of your square
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: side, height: side),
            squarePaint,
          );
          canvas.restore();
        }
        break;
      }
      currentDistance += metric.length;
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
