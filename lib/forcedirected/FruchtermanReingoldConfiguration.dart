part of graphview;

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

  int iterations;
  double repulsionRate;
  double repulsionPercentage;
  double attractionRate;
  double attractionPercentage;
  int clusterPadding;
  double epsilon;
  double lerpFactor;
  double movementThreshold;
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