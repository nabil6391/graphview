part of graphview;

class SugiyamaConfiguration {
  static const int X_SEPARATION = 100;
  static const int Y_SEPARATION = 100;

  int levelSeparation = Y_SEPARATION;
  int nodeSeparation = X_SEPARATION;

  int getLevelSeparation() {
    return levelSeparation;
  }

  int getNodeSeparation() {
    return nodeSeparation;
  }
}
