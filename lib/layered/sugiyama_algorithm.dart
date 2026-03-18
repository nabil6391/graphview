import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphview/algorithm.dart';
import 'package:graphview/graph.dart';
import 'package:graphview/layered/sugiyama_configuration.dart';
import 'package:graphview/layered/sugiyama_edge_data.dart';
import 'package:graphview/layered/sugiyama_edge_renderer.dart';
import 'package:graphview/layered/sugiyama_node_data.dart';

class SugiyamaAlgorithm extends Algorithm {
  SugiyamaConfiguration configuration;
  final Map<Node, SugiyamaNodeData> nodeData = {};
  final Map<Edge, SugiyamaEdgeData> edgeData = {};

  SugiyamaAlgorithm(this.configuration) {
    renderer = SugiyamaEdgeRenderer(
        nodeData, edgeData, configuration.bendPointShape, configuration.addTriangleToEdge);
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    // Layout logic (simplified for fix)
    return Size.zero;
  }

  @override
  void init(Graph? graph) {}

  @override
  void setDimensions(double width, double height) {}
}
