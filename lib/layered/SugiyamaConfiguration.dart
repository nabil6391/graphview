part of graphview;

/// Configuration for the [SugiyamaAlgorithm] layered graph layout.
class SugiyamaConfiguration {
  /// Root at top, leaves at bottom.
  static const ORIENTATION_TOP_BOTTOM = 1;

  /// Root at bottom, leaves at top.
  static const ORIENTATION_BOTTOM_TOP = 2;

  /// Root at left, leaves at right.
  static const ORIENTATION_LEFT_RIGHT = 3;

  /// Root at right, leaves at left.
  static const ORIENTATION_RIGHT_LEFT = 4;

  static const DEFAULT_ORIENTATION = 1;
  static const int DEFAULT_ITERATIONS = 10;
  static const int X_SEPARATION = 100;
  static const int Y_SEPARATION = 100;

  /// Vertical spacing between layers.
  int levelSeparation = Y_SEPARATION;

  /// Horizontal spacing between nodes within a layer.
  int nodeSeparation = X_SEPARATION;

  /// Layout direction. Use ORIENTATION_* constants.
  int orientation = DEFAULT_ORIENTATION;

  /// Number of iterations for crossing minimization.
  int iterations = DEFAULT_ITERATIONS;

  /// Shape used for edge bend points (sharp, curved, or max-curved).
  BendPointShape bendPointShape = SharpBendPointShape();

  /// Strategy for assigning x-coordinates to nodes within layers.
  CoordinateAssignment coordinateAssignment = CoordinateAssignment.Average;

  /// Strategy for assigning nodes to layers.
  LayeringStrategy layeringStrategy = LayeringStrategy.topDown;

  /// Strategy for minimizing edge crossings between layers.
  CrossMinimizationStrategy crossMinimizationStrategy = CrossMinimizationStrategy.simple;

  /// Strategy for removing cycles in the input graph.
  CycleRemovalStrategy cycleRemovalStrategy = CycleRemovalStrategy.greedy;

  /// Whether to apply post-processing to straighten edges.
  bool postStraighten = true;

  /// Whether to draw arrowhead triangles on edge endpoints.
  bool addTriangleToEdge = true;

  int getLevelSeparation() {
    return levelSeparation;
  }

  int getNodeSeparation() {
    return nodeSeparation;
  }

  int getOrientation() {
    return orientation;
  }
}

/// Strategy for assigning x-coordinates to nodes within layers.
enum CoordinateAssignment {
  /// Assign coordinates favoring down-right placement.
  DownRight,
  /// Assign coordinates favoring down-left placement.
  DownLeft,
  /// Assign coordinates favoring up-right placement.
  UpRight,
  /// Assign coordinates favoring up-left placement.
  UpLeft,
  /// Average of all four directional assignments.
  Average,
}

/// Strategy for assigning nodes to layers in the Sugiyama framework.
enum LayeringStrategy {
  /// Simple top-down depth-first layer assignment.
  topDown,
  /// Assigns layers based on the longest path from source nodes.
  longestPath,
  /// Coffman-Graham layering with bounded layer width.
  coffmanGraham,
  /// Optimal layering via network simplex (most expensive).
  networkSimplex
}

/// Strategy for minimizing edge crossings between adjacent layers.
enum CrossMinimizationStrategy {
  /// Simple median/barycenter heuristic.
  simple,
  /// Accumulator tree-based crossing count for faster minimization.
  accumulatorTree
}

/// Strategy for removing cycles from a directed graph before layering.
enum CycleRemovalStrategy {
  /// Depth-first search based cycle removal.
  dfs,
  /// Greedy heuristic cycle removal.
  greedy,
}

/// Base class for edge bend point rendering shapes.
abstract class BendPointShape {}

/// Renders bend points as sharp 90-degree angles.
class SharpBendPointShape extends BendPointShape {}

/// Renders bend points with maximum curvature.
class MaxCurvedBendPointShape extends BendPointShape {}

/// Renders bend points with a configurable curve radius.
class CurvedBendPointShape extends BendPointShape {
  /// The length of the curved segment at each bend point.
  final double curveLength;

  /// Creates a curved bend point shape with the given [curveLength].
  CurvedBendPointShape({
    required this.curveLength,
  });
}
