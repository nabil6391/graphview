import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:graphview/edge_renderer/edge_renderer.dart';
import 'package:graphview/graph.dart';
import 'package:collection/collection.dart';

const double ARROW_DEGREES = 0.5;
const double ARROW_LENGTH = 10;
const double MIN_ANCHOR_OFFSET = 12.0; 
const double MAX_ANCHOR_OFFSET = 32.0;
const double ANCHOR_RADIUS = 2.5;

class AnchorInfo {
  final Edge edge;
  final bool isSource;

  AnchorInfo({required this.edge, required this.isSource});
}

class ArrowEdgeRenderer extends EdgeRenderer {
  var trianglePath = Path();
  final bool noArrow;
  final Map<Edge, Path> renderedPaths = {};
  
  // Stores the local positions of all drawn anchors for hit testing
  final Map<Offset, AnchorInfo> anchorLookup = {};
  
  // Track unique anchor coordinates to avoid drawing dots on top of each other
  final Set<String> _drawnAnchors = {};

  ArrowEdgeRenderer({this.noArrow = false});

  @override
  void render(Canvas canvas, Graph graph, Paint paint) {
    _drawnAnchors.clear();
    anchorLookup.clear();
    renderedPaths.clear();
    
    graph.edges.forEach((edge) {
      renderEdge(canvas, edge, paint);
    });
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    var source = edge.source;
    var destination = edge.destination;

    final currentPaint = Paint()
      ..color = edge.paint?.color ?? paint.color
      ..strokeWidth = edge.paint?.strokeWidth ?? paint.strokeWidth
      ..style = PaintingStyle.stroke;
      
    final lineType = edge.lineType ?? LineType.Default;
    var edgePath = Path();

    // 1. Get real-time positions
    var sourceOffset = getNodePosition(source);
    var destinationOffset = getNodePosition(destination);
    
    final sourceShift = sourceOffset - source.position;
    final destinationShift = destinationOffset - destination.position;

    Offset arrowTip;
    Offset secondToLast;
    Offset sourceAnchor;
    Offset destAnchor;
    Offset sourceContact;
    Offset destContact;

    if (edge.sections != null && edge.sections!.isNotEmpty) {
      // 2. Identify Contact Points
      final count = edge.sections!.length;
      sourceContact = edge.sections!.first + sourceShift;
      destContact = edge.sections!.last + destinationShift;

      // 3. Calculate DYNAMIC 90° Perpendicular Anchors
      // Offset is larger at side center, smaller at corners
      final sNormal = _getNormal(source, sourceContact);
      final sOffset = _getDynamicOffset(source, sourceContact);
      sourceAnchor = sourceContact + (sNormal * sOffset);

      final dNormal = _getNormal(destination, destContact);
      final dOffset = _getDynamicOffset(destination, destContact);
      destAnchor = destContact + (dNormal * dOffset);

      // 4. Build Edge Path
      Offset finalSegmentStart;
      if (count > 2) {
          final tLast = (count - 2) / (count - 1);
          final lastBend = edge.sections![count - 2] + Offset.lerp(sourceShift, destinationShift, tLast)!;
          finalSegmentStart = lastBend;
      } else {
          finalSegmentStart = sourceAnchor;
      }

      final dir = destAnchor - finalSegmentStart;
      final unit = dir / (dir.distance > 0 ? dir.distance : 1.0);
      arrowTip = destAnchor - (unit * ANCHOR_RADIUS);
      secondToLast = finalSegmentStart;

      edgePath.moveTo(sourceAnchor.dx, sourceAnchor.dy);
      if (count > 2) {
        for (var i = 1; i < count - 1; i++) {
          final t = i / (count - 1);
          final currentShift = Offset.lerp(sourceShift, destinationShift, t)!;
          final bendPoint = edge.sections![i] + currentShift;
          edgePath.lineTo(bendPoint.dx, bendPoint.dy);
        }
      }
      edgePath.lineTo(arrowTip.dx, arrowTip.dy);
      
      anchorLookup[sourceAnchor] = AnchorInfo(edge: edge, isSource: true);
      anchorLookup[destAnchor] = AnchorInfo(edge: edge, isSource: false);
    } else {
      // Fallback
      final sCenter = sourceOffset + Offset(source.width / 2, source.height / 2);
      final dCenter = destinationOffset + Offset(destination.width / 2, destination.height / 2);
      edgePath.moveTo(sCenter.dx, sCenter.dy);
      edgePath.lineTo(dCenter.dx, dCenter.dy);
      arrowTip = dCenter;
      secondToLast = sCenter;
      sourceAnchor = sCenter;
      destAnchor = dCenter;
      sourceContact = sCenter;
      destContact = dCenter;
    }

    renderedPaths[edge] = edgePath;

    // 5. Draw the main path
    drawStyledPath(canvas, edgePath, currentPaint, lineType: lineType);

    // 6. Draw 90° Anchor Structures using Node Colors
    if (edge.sections != null && edge.sections!.isNotEmpty) {
        final sourceColor = _getNodeColor(source, currentPaint.color);
        final destColor = _getNodeColor(destination, currentPaint.color);

        final sInterfacePaint = Paint()..color = sourceColor..strokeWidth = 1.0..style = PaintingStyle.stroke;
        final dInterfacePaint = Paint()..color = destColor..strokeWidth = 1.0..style = PaintingStyle.stroke;

        canvas.drawLine(sourceContact, sourceAnchor, sInterfacePaint);
        canvas.drawLine(destContact, destAnchor, dInterfacePaint);

        _drawAnchorDot(canvas, sourceAnchor, sourceColor);
        _drawAnchorDot(canvas, destAnchor, destColor);
    }

    // 7. Draw the arrowhead
    if (!noArrow) {
      var trianglePaint = Paint()
        ..color = currentPaint.color
        ..style = PaintingStyle.fill;

      drawTriangle(
          canvas,
          trianglePaint,
          secondToLast.dx,
          secondToLast.dy,
          arrowTip.dx,
          arrowTip.dy);
    }

    // 8. Interactive Dot
    if (edge.interactive) {
      final metrics = edgePath.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final tangent = metric.getTangentForOffset(metric.length / 2.0);
        if (tangent != null) {
          final center = tangent.position;
          final dotPaint = Paint()
            ..color = edge.interactiveFillColor ?? currentPaint.color
            ..style = PaintingStyle.fill;
          canvas.drawCircle(center, 3.0, dotPaint);
          final borderPaint = Paint()
            ..color = edge.interactiveBorderColor ?? Colors.white
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke;
          canvas.drawCircle(center, 3.0, borderPaint);
        }
      }
    }
  }

  double _getDynamicOffset(Node node, Offset contact) {
    final center = Offset(node.x + node.width / 2, node.y + node.height / 2);
    final rel = contact - center;
    
    final nx = rel.dx / (node.width > 0 ? node.width : 1.0);
    final ny = rel.dy / (node.height > 0 ? node.height : 1.0);
    
    double t; // 0.0 at center, 1.0 at corner
    if (nx.abs() > ny.abs()) {
        // Left/Right side - depth is determined by vertical deviation
        t = (ny.abs() * 2.0).clamp(0.0, 1.0);
    } else {
        // Top/Bottom side - depth is determined by horizontal deviation
        t = (nx.abs() * 2.0).clamp(0.0, 1.0);
    }

    // Parabolic curve: connections at center are farther out (MaxOffset)
    return MIN_ANCHOR_OFFSET + (MAX_ANCHOR_OFFSET - MIN_ANCHOR_OFFSET) * (1.0 - t * t);
  }

  Color _getNodeColor(Node node, Color fallback) {
      final colorVal = node.metadata['color'];
      if (colorVal is int) {
          return Color(colorVal);
      }
      return fallback;
  }

  Offset _getNormal(Node node, Offset contact) {
    final center = Offset(node.x + node.width / 2, node.y + node.height / 2);
    final rel = contact - center;
    final nx = rel.dx / (node.width > 0 ? node.width : 1.0);
    final ny = rel.dy / (node.height > 0 ? node.height : 1.0);
    if (nx.abs() > ny.abs()) {
      return nx > 0 ? const Offset(1, 0) : const Offset(-1, 0);
    } else {
      return ny > 0 ? const Offset(0, 1) : const Offset(0, -1);
    }
  }

  void _drawAnchorDot(Canvas canvas, Offset anchor, Color color) {
    final anchorKey = '${anchor.dx.toStringAsFixed(1)}_${anchor.dy.toStringAsFixed(1)}';
    if (_drawnAnchors.contains(anchorKey)) return;
    _drawnAnchors.add(anchorKey);

    final anchorOutlinePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final anchorFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(anchor, ANCHOR_RADIUS, anchorFillPaint);
    canvas.drawCircle(anchor, ANCHOR_RADIUS, anchorOutlinePaint);
  }

  Offset drawTriangle(Canvas canvas, Paint paint, double lineStartX,
      double lineStartY, double arrowTipX, double arrowTipY) {
    var angle = atan2(arrowTipY - lineStartY, arrowTipX - lineStartX);
    if ((arrowTipX - lineStartX).abs() < 0.1 && (arrowTipY - lineStartY).abs() < 0.1) {
        return Offset(arrowTipX, arrowTipY);
    }
    var leftWingX = arrowTipX - ARROW_LENGTH * cos(angle - ARROW_DEGREES);
    var leftWingY = arrowTipY - ARROW_LENGTH * sin(angle - ARROW_DEGREES);
    var rightWingX = arrowTipX - ARROW_LENGTH * cos(angle + ARROW_DEGREES);
    var rightWingY = arrowTipY - ARROW_LENGTH * sin(angle + ARROW_DEGREES);
    trianglePath.reset();
    trianglePath.moveTo(arrowTipX, arrowTipY); 
    trianglePath.lineTo(leftWingX, leftWingY); 
    trianglePath.lineTo(rightWingX, rightWingY); 
    trianglePath.close(); 
    canvas.drawPath(trianglePath, paint);
    return Offset((arrowTipX + leftWingX + rightWingX) / 3, (arrowTipY + leftWingY + rightWingY) / 3);
  }

  List<double> clipLineEnd(
      double startX, double startY, double stopX, double stopY, 
      double destX, double destY, double destWidth, double destHeight) {
    final dx = stopX - startX;
    final dy = stopY - startY;
    if (dx.abs() < 0.1 && dy.abs() < 0.1) return [startX, startY, stopX, stopY];
    if (dx.abs() < 0.001) {
        final halfHeight = destHeight * 0.5;
        return [startX, startY, stopX, stopY + (dy > 0 ? -halfHeight : halfHeight)];
    }
    var slope = dy / dx;
    final halfHeight = destHeight * 0.5;
    final halfWidth = destWidth * 0.5;
    final xDist = stopX > startX ? halfWidth : -halfWidth;
    final yAtVerticalBoundary = stopY - (slope * xDist);
    if ((yAtVerticalBoundary - stopY).abs() <= halfHeight) return [startX, startY, stopX - xDist, yAtVerticalBoundary];
    final yDist = stopY > startY ? halfHeight : -halfHeight;
    final xAtHorizontalBoundary = stopX - (yDist / slope);
    return [startX, startY, xAtHorizontalBoundary, stopY - yDist];
  }

  List<double> clipLine(double startX, double startY, double stopX,
      double stopY, Node destination) {
    return clipLineEnd(startX, startY, stopX, stopY, destination.x, destination.y, destination.width, destination.height);
  }
}
