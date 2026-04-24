part of graphview;

/// Configuration for the [FruchtermanReingoldAlgorithm] force-directed layout.
class FruchtermanReingoldConfiguration {
  static const int DEFAULT_ITERATIONS = 100;
  static const double DEFAULT_REPULSION_RATE = 0.2;
  static const double DEFAULT_REPULSION_PERCENTAGE = 0.4;
  static const double DEFAULT_ATTRACTION_RATE = 0.15;
  static const double DEFAULT_ATTRACTION_PERCENTAGE = 0.15;
  static const int DEFAULT_CLUSTER_PADDING = 15;
  static const double DEFAULT_EPSILON = 0.0001;
  static const double DEFAULT_LERP_FACTOR = 0.05;
  static const double DEFAULT_MOVEMENT_THRESHOLD = 0.6;

  /// Maximum number of simulation iterations.
  int iterations;

  /// Strength of the repulsive force between nodes.
  double repulsionRate;

  /// Percentage of graph area used for repulsion calculation.
  double repulsionPercentage;

  /// Strength of the attractive force along edges.
  double attractionRate;

  /// Percentage of graph area used for attraction calculation.
  double attractionPercentage;

  /// Padding between node clusters in logical pixels.
  int clusterPadding;

  /// Minimum distance threshold to avoid division by zero in repulsion.
  double epsilon;

  /// Interpolation factor for smooth position transitions (0.0 to 1.0).
  double lerpFactor;

  /// Minimum movement threshold below which the simulation stops early.
  double movementThreshold;

  /// Whether to randomize initial node positions before simulation.
  bool shuffleNodes = true;

  FruchtermanReingoldConfiguration({
    this.iterations = DEFAULT_ITERATIONS,
    this.repulsionRate = DEFAULT_REPULSION_RATE,
    this.attractionRate = DEFAULT_ATTRACTION_RATE,
    this.repulsionPercentage = DEFAULT_REPULSION_PERCENTAGE,
    this.attractionPercentage = DEFAULT_ATTRACTION_PERCENTAGE,
    this.clusterPadding = DEFAULT_CLUSTER_PADDING,
    this.epsilon = DEFAULT_EPSILON,
    this.lerpFactor = DEFAULT_LERP_FACTOR,
    this.movementThreshold = DEFAULT_MOVEMENT_THRESHOLD,
    this.shuffleNodes = true
  });

}