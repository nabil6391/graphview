part of graphview;

class MindmapEdgeRenderer extends TreeEdgeRenderer {
  MindmapEdgeRenderer(BuchheimWalkerConfiguration configuration)
      : super(configuration);

  @override
  int getEffectiveOrientation(dynamic node, dynamic child) {
    var orientation = configuration.orientation;

    if (child.y < 0) {
      if (configuration.orientation == BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM) {
        orientation = BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP;
      } else {
        // orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
      }
    } else if (child.x < 0) {
      if (configuration.orientation == BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT) {
        orientation = BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT;
      } else {
        orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
      }
    }

    return orientation;
  }
}