part of graphview;

/// Configuration for tree layout algorithms ([BuchheimWalkerAlgorithm], [TidierTreeLayoutAlgorithm], etc.).
///
/// Controls spacing between siblings, levels, and subtrees, as well as layout orientation.
class BuchheimWalkerConfiguration {
  /// Horizontal spacing between sibling nodes.
  int siblingSeparation = DEFAULT_SIBLING_SEPARATION;

  /// Vertical spacing between tree levels.
  int levelSeparation = DEFAULT_LEVEL_SEPARATION;

  /// Horizontal spacing between adjacent subtrees.
  int subtreeSeparation = DEFAULT_SUBTREE_SEPARATION;

  /// Layout direction. Use ORIENTATION_* constants.
  int orientation = DEFAULT_ORIENTATION;

  /// Root at top, leaves at bottom.
  static const ORIENTATION_TOP_BOTTOM = 1;

  /// Root at bottom, leaves at top.
  static const ORIENTATION_BOTTOM_TOP = 2;

  /// Root at left, leaves at right.
  static const ORIENTATION_LEFT_RIGHT = 3;

  /// Root at right, leaves at left.
  static const ORIENTATION_RIGHT_LEFT = 4;

  static const DEFAULT_SIBLING_SEPARATION = 100;
  static const DEFAULT_SUBTREE_SEPARATION = 100;
  static const DEFAULT_LEVEL_SEPARATION = 100;
  static const DEFAULT_ORIENTATION = 1;

  /// Whether to use curved Bezier connections instead of straight lines.
  bool useCurvedConnections = true;

  int getSiblingSeparation() {
    return siblingSeparation;
  }

  int getLevelSeparation() {
    return levelSeparation;
  }

  int getSubtreeSeparation() {
    return subtreeSeparation;
  }
  BuchheimWalkerConfiguration(
      {this.siblingSeparation = DEFAULT_SIBLING_SEPARATION,
        this.levelSeparation = DEFAULT_LEVEL_SEPARATION,
        this.subtreeSeparation = DEFAULT_SUBTREE_SEPARATION,
        this.orientation = DEFAULT_ORIENTATION});

}
