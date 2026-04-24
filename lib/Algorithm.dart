part of graphview;

/// Abstract base class for graph layout algorithms.
///
/// Implementations position nodes by setting [Node.position] and [Node.size]
/// for every node in the graph. The typical lifecycle is:
/// `init(graph) → setDimensions(w, h) → run(graph, shiftX, shiftY)`.
abstract class Algorithm {
  /// The edge renderer used to draw connections between nodes.
  EdgeRenderer? renderer;

  /// Executes the algorithm, positioning all nodes in the [graph].
  ///
  /// [shiftX] and [shiftY] offset the coordinate origin.
  /// Returns the bounding [Size] of the laid-out graph.
  Size run(Graph? graph, double shiftX, double shiftY);

  /// Initializes internal data structures for the given [graph].
  void init(Graph? graph);

  /// Sets the available viewport dimensions for layout computation.
  void setDimensions(double width, double height);
}
