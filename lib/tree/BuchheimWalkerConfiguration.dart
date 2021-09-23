part of graphview;

class BuchheimWalkerConfiguration {
  int siblingSeparation = DEFAULT_SIBLING_SEPARATION;
  int levelSeparation = DEFAULT_LEVEL_SEPARATION;
  int subtreeSeparation = DEFAULT_SUBTREE_SEPARATION;
  int orientation = DEFAULT_ORIENTATION;
  static const ORIENTATION_TOP_BOTTOM = 1;
  static const ORIENTATION_BOTTOM_TOP = 2;
  static const ORIENTATION_LEFT_RIGHT = 3;
  static const ORIENTATION_RIGHT_LEFT = 4;
  static const DEFAULT_SIBLING_SEPARATION = 100;
  static const DEFAULT_SUBTREE_SEPARATION = 100;
  static const DEFAULT_LEVEL_SEPARATION = 100;
  static const DEFAULT_ORIENTATION = 1;

  int getSiblingSeparation() {
    return siblingSeparation;
  }

  int getLevelSeparation() {
    return levelSeparation;
  }

  int getSubtreeSeparation() {
    return subtreeSeparation;
  }
}
