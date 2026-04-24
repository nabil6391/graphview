part of graphview;

/// Internal data attached to each edge during [SugiyamaAlgorithm] execution.
class SugiyamaEdgeData {
  /// Coordinates of intermediate bend points along the edge path.
  List<double> bendPoints = [];
}
