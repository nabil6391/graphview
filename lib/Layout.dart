part of graphview;

abstract class Layout {
  EdgeRenderer renderer;

  /// Executes the algorithm.
  /// @param shiftY Shifts the y-coordinate origin
  /// @param shiftX Shifts the x-coordinate origin
  /// @return The size of the graph
  Size run(Graph graph, double shiftX, double shiftY);

}
