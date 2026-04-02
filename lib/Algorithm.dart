import 'package:flutter/material.dart';
import 'package:graphview/edge_renderer/edge_renderer.dart';
import 'package:graphview/graph.dart';

abstract class Algorithm {
  EdgeRenderer? renderer;

  /// Executes the algorithm.
  /// @param shiftY Shifts the y-coordinate origin
  /// @param shiftX Shifts the x-coordinate origin
  /// @return The size of the graph
  Size run(Graph? graph, double shiftX, double shiftY);

  void init(Graph? graph);

  void setDimensions(double width, double height);
}
