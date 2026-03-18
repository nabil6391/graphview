import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:graphview/edge_renderer/arrow_edge_renderer.dart';
import 'package:graphview/graph.dart';
import 'package:graphview/layered/sugiyama_configuration.dart';
import 'package:graphview/layered/sugiyama_edge_data.dart';
import 'package:graphview/layered/sugiyama_node_data.dart';

class SugiyamaEdgeRenderer extends ArrowEdgeRenderer {
  Map<Node, SugiyamaNodeData> nodeData;
  Map<Edge, SugiyamaEdgeData> edgeData;
  BendPointShape bendPointShape;
  bool addTriangleToEdge;
  var path = Path();

  SugiyamaEdgeRenderer(
      this.nodeData, this.edgeData, this.bendPointShape, this.addTriangleToEdge);

  bool hasBendEdges(Edge edge) =>
      edgeData.containsKey(edge) && edgeData[edge]!.bendPoints.isNotEmpty;

  @override
  void render(Canvas canvas, Graph graph, Paint paint) {
    graph.edges.forEach((edge) {
      renderEdge(canvas, edge, paint);
    });
  }

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    final currentPaint = (edge.paint ?? paint)..style = PaintingStyle.stroke;

    var trianglePaint = Paint()
      ..color = edge.paint?.color ?? paint.color
      ..style = PaintingStyle.fill;

    if (hasBendEdges(edge)) {
      _renderEdgeWithBendPoints(canvas, edge, currentPaint, trianglePaint);
    } else {
      super.renderEdge(canvas, edge, paint);
    }
  }

  void _renderEdgeWithBendPoints(
      Canvas canvas, Edge edge, Paint currentPaint, Paint trianglePaint) {
    var source = edge.source;
    var destination = edge.destination;

    var sourceOffset = getNodePosition(source);
    var destinationOffset = getNodePosition(destination);

    var startX = sourceOffset.dx + source.width * 0.5;
    var startY = sourceOffset.dy + source.height * 0.5;
    var stopX = destinationOffset.dx + destination.width * 0.5;
    var stopY = destinationOffset.dy + destination.height * 0.5;

    final bendPoints = edgeData[edge]!.bendPoints;

    path.reset();
    path.moveTo(startX, startY);

    for (var i = 0; i < bendPoints.length; i += 2) {
        var bendX = bendPoints[i];
        var bendY = bendPoints[i + 1];
        path.lineTo(bendX, bendY);
    }

    path.lineTo(stopX, stopY);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final totalLength = metric.length;

    var triangleCentroid = Offset.zero;

    if (addTriangleToEdge) {
      final tipPos = metric.getTangentForOffset(totalLength - 1.0);
      final basePos = metric.getTangentForOffset(max(0, totalLength - ARROW_LENGTH - 1.0));

      if (tipPos != null && basePos != null) {
        triangleCentroid = drawTriangle(
          canvas,
          trianglePaint,
          basePos.position.dx,
          basePos.position.dy,
          tipPos.position.dx,
          tipPos.position.dy,
        );
      }
    }

    final edgePath = addTriangleToEdge
        ? metric.extractPath(0, max(0, totalLength - ARROW_LENGTH))
        : path;

    canvas.drawPath(edgePath, currentPaint);

    if (addTriangleToEdge && triangleCentroid != Offset.zero) {
        final tipPos = metric.getTangentForOffset(totalLength - 1.0);
        if (tipPos != null) {
            canvas.drawLine(tipPos.position, triangleCentroid, currentPaint);
        }
    }
  }
}
