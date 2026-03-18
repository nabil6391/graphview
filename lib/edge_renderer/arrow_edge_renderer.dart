import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:graphview/edge_renderer/edge_renderer.dart';
import 'package:graphview/graph.dart';
import 'package:graphview/layered/sugiyama_node_data.dart';
import 'package:collection/collection.dart';

const double ARROW_DEGREES = 0.5;
const double ARROW_LENGTH = 10;

class ArrowEdgeRenderer extends EdgeRenderer {
  var trianglePath = Path();
  final bool noArrow;
  final Map<Edge, Path> renderedPaths = {};

  ArrowEdgeRenderer({this.noArrow = false});

  @override
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
    final lineType = edge.lineType ?? _getLineType(destination);
    var edgePath = Path();

    var sourceOffset = getNodePosition(source);
    var destinationOffset = getNodePosition(destination);

    if (source == destination) {
      final loopResult = buildSelfLoopPath(
        edge,
        arrowLength: noArrow ? 0.0 : ARROW_LENGTH,
      );

      if (loopResult != null) {
        drawStyledPath(canvas, loopResult.path, currentPaint,
            lineType: lineType ?? LineType.Default);
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
            lineType: lineType ?? LineType.Default,
          );
        }
        
        return;
      }
    }

    // If we have ELK sections AND nodes are NOT moving (not animating to new positions), use complex path
    bool isAnimatingMovement = (sourceOffset != source.position) || (destinationOffset != destination.position);

    if (edge.sections != null && edge.sections!.isNotEmpty && !isAnimatingMovement) {
      edgePath.moveTo(edge.sections!.first.dx, edge.sections!.first.dy);
      for (var i = 1; i < edge.sections!.length; i++) {
        edgePath.lineTo(edge.sections![i].dx, edge.sections![i].dy);
      }
    } else {
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
    }

    renderedPaths[edge] = edgePath;

    if (noArrow) {
      // Draw path without arrow, respecting line type
      drawStyledPath(canvas, edgePath, currentPaint, lineType: lineType ?? LineType.Default);
    } else {
      // For ELK paths, we need to find the orientation of the arrow
      final metrics = edgePath.computeMetrics().toList();
      final firstMetric = metrics.firstOrNull;
      
      final lastPoint = edge.sections?.last ?? 
          firstMetric?.getTangentForOffset(firstMetric.length)?.position ??
          destinationOffset;
      
      final secondLastPoint = (edge.sections != null && edge.sections!.length > 1) 
          ? edge.sections![edge.sections!.length - 2]
          : firstMetric?.getTangentForOffset(firstMetric != null ? max(0, firstMetric.length - 1.0) : 0)?.position ??
            sourceOffset;

      var trianglePaint = Paint()
        ..color = currentPaint.color
        ..style = PaintingStyle.fill;

      var triangleCentroid = drawTriangle(
          canvas,
          trianglePaint,
          secondLastPoint.dx,
          secondLastPoint.dy,
          lastPoint.dx,
          lastPoint.dy);

      // Draw the path up to the triangle centroid
      drawStyledPath(canvas, edgePath, currentPaint, lineType: lineType ?? LineType.Default);
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

  /// Helper to get line type from node data if available
  LineType? _getLineType(Node node) {
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
          resultLine[3] = stopY + halfHeight;
        }
      }
    }

    return resultLine;
  }
}
