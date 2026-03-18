import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/algorithm.dart';
import 'package:graphview/edge_renderer/arrow_edge_renderer.dart';
import 'package:graphview/edge_renderer/edge_renderer.dart';
import 'package:graphview/graph.dart';
import 'package:graphview/tree/baloon_layout_algorithm.dart';
import 'package:graphview/tree/buchheim_walker_configuration.dart';

class TreeLayoutNodeData {
  Rectangle? bounds;
  int depth = 0;
  bool visited = false;
  List<Node> successorNodes = [];
  Node? parent;

  TreeLayoutNodeData();
}

class RadialTreeLayoutAlgorithm extends Algorithm {
  late BuchheimWalkerConfiguration config;
  final Map<Node, TreeLayoutNodeData> nodeData = {};
  final Map<Node, Size> baseBounds = {};
  final Map<Node, PolarPoint> polarLocations = {};

  RadialTreeLayoutAlgorithm(this.config, EdgeRenderer? renderer) {
    this.renderer = renderer ?? ArrowEdgeRenderer();
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodes.isEmpty) {
      return Size.zero;
    }

    nodeData.clear();
    baseBounds.clear();
    polarLocations.clear();

    var roots = graph.nodes.where((node) {
      return graph.edges.every((edge) => edge.destination != node);
    }).toList();

    if (roots.isEmpty && graph.nodes.isNotEmpty) {
      roots = [graph.nodes.first];
    }

    for (var node in graph.nodes) {
      nodeData[node] = TreeLayoutNodeData();
      baseBounds[node] = Size(node.width, node.height);
    }

    for (var root in roots) {
      _buildTree(graph, root, 0);
    }

    _calculatePolarLocations(roots);

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    polarLocations.forEach((node, polar) {
      final x = polar.r * cos(polar.theta);
      final y = polar.r * sin(polar.theta);

      node.x = x;
      node.y = y;

      minX = min(minX, x);
      minY = min(minY, y);
      maxX = max(maxX, x + node.width);
      maxY = max(maxY, y + node.height);
    });

    for (var node in graph.nodes) {
      node.x = node.x - minX + shiftX;
      node.y = node.y - minY + shiftY;
    }

    return Size(maxX - minX, maxY - minY);
  }

  void _buildTree(Graph graph, Node node, int depth) {
    final data = nodeData[node]!;
    if (data.visited) return;
    data.visited = true;
    data.depth = depth;

    for (var edge in graph.edges) {
      if (edge.source == node) {
        final dest = edge.destination;
        if (!nodeData[dest]!.visited) {
          data.successorNodes.add(dest);
          nodeData[dest]!.parent = node;
          _buildTree(graph, dest, depth + 1);
        }
      }
    }
  }

  void _calculatePolarLocations(List<Node> roots) {
    if (roots.isEmpty) return;

    // Simplified radial placement
    // For a real implementation, we would use Buchheim-Walker or similar
    // for calculating sub-tree widths and assigning angular wedges.
    
    _assignWedges(roots, 0, 2 * pi);
  }

  void _assignWedges(List<Node> nodes, double startAngle, double endAngle) {
      if (nodes.isEmpty) return;

      final wedgeSize = (endAngle - startAngle) / nodes.length;
      final radiusStep = 350.0;

      for (var i = 0; i < nodes.length; i++) {
          final node = nodes[i];
          final data = nodeData[node]!;
          final angle = startAngle + i * wedgeSize + wedgeSize / 2;
          final radius = data.depth * radiusStep;

          polarLocations[node] = PolarPoint(radius, angle);
          _assignWedges(data.successorNodes, startAngle + i * wedgeSize, startAngle + (i + 1) * wedgeSize);
      }
  }

  @override
  void setDimensions(double width, double height) {}

  @override
  void init(Graph? graph) {}
}

class PolarPoint {
    final double r;
    final double theta;
    PolarPoint(this.r, this.theta);
}
