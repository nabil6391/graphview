part of graphview;

class TreeEdgeRenderer extends EdgeRenderer {
  BuchheimWalkerConfiguration configuration;

  TreeEdgeRenderer(this.configuration);

  var linePath = Path();

  @override
  void render(Canvas canvas, Graph graph, Paint paint) {
    for (final node in graph.nodes) {
      for (final child in graph.successorsOf(node)) {
        final edge = graph.getEdgeBetween(node, child);
        final edgePaint = (edge?.paint ?? paint)..style = PaintingStyle.stroke;

        renderEdge(canvas, node, child, edgePaint);
      }
    }
  }

  void renderEdge(Canvas canvas, Node node, Node child, Paint edgePaint) {
    final parentPos = getNodePosition(node);
    final childPos = getNodePosition(child);

    final orientation = getEffectiveOrientation(node, child);

    linePath.reset();
    buildEdgePath(node, child, parentPos, childPos, orientation);
    canvas.drawPath(linePath, edgePaint);
  }

  int getEffectiveOrientation(Node node, Node child) {
    return configuration.orientation;
  }

  /// Builds the path for the edge based on orientation
  void buildEdgePath(Node node, Node child, Offset parentPos, Offset childPos, int orientation) {
    final parentCenterX = parentPos.dx + node.width * 0.5;
    final parentCenterY = parentPos.dy + node.height * 0.5;
    final childCenterX = childPos.dx + child.width * 0.5;
    final childCenterY = childPos.dy + child.height * 0.5;

    switch (orientation) {
      case BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM:
        buildTopBottomPath(node, child, parentPos, childPos, parentCenterX, parentCenterY, childCenterX, childCenterY);
        break;

      case BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP:
        buildBottomTopPath(node, child, parentPos, childPos, parentCenterX, parentCenterY, childCenterX, childCenterY);
        break;

      case BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT:
        buildLeftRightPath(node, child, parentPos, childPos, parentCenterX, parentCenterY, childCenterX, childCenterY);
        break;

      case BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT:
        buildRightLeftPath(node, child, parentPos, childPos, parentCenterX, parentCenterY, childCenterX, childCenterY);
        break;
    }
  }

  /// Builds path for top-bottom orientation
  void buildTopBottomPath(Node node, Node child, Offset parentPos, Offset childPos,
      double parentCenterX, double parentCenterY, double childCenterX, double childCenterY) {
    final parentBottomY = parentPos.dy + node.height;
    final childTopY = childPos.dy;
    final midY = (parentBottomY + childTopY) * 0.5;

    if (configuration.useCurvedConnections) {
      // Curved connection
      linePath
        ..moveTo(childCenterX, childTopY)
        ..cubicTo(
          childCenterX, midY,
          parentCenterX, midY,
          parentCenterX, parentBottomY,
        );
    } else {
      // L-shaped connection
      linePath
        ..moveTo(parentCenterX, parentBottomY)
        ..lineTo(parentCenterX, midY)
        ..lineTo(childCenterX, midY)
        ..lineTo(childCenterX, childTopY);
    }
  }

  /// Builds path for bottom-top orientation
  void buildBottomTopPath(Node node, Node child, Offset parentPos, Offset childPos,
      double parentCenterX, double parentCenterY, double childCenterX, double childCenterY) {
    final parentTopY = parentPos.dy;
    final childBottomY = childPos.dy + child.height;
    final midY = (parentTopY + childBottomY) * 0.5;

    if (configuration.useCurvedConnections) {
      linePath
        ..moveTo(childCenterX, childBottomY)
        ..cubicTo(
          childCenterX, midY,
          parentCenterX, midY,
          parentCenterX, parentTopY,
        );
    } else {
      linePath
        ..moveTo(parentCenterX, parentTopY)
        ..lineTo(parentCenterX, midY)
        ..lineTo(childCenterX, midY)
        ..lineTo(childCenterX, childBottomY);
    }
  }

  /// Builds path for left-right orientation
  void buildLeftRightPath(Node node, Node child, Offset parentPos, Offset childPos,
      double parentCenterX, double parentCenterY, double childCenterX, double childCenterY) {
    final parentRightX = parentPos.dx + node.width;
    final childLeftX = childPos.dx;
    final midX = (parentRightX + childLeftX) * 0.5;

    if (configuration.useCurvedConnections) {
      linePath
        ..moveTo(childLeftX, childCenterY)
        ..cubicTo(
          midX, childCenterY,
          midX, parentCenterY,
          parentRightX, parentCenterY,
        );
    } else {
      linePath
        ..moveTo(parentRightX, parentCenterY)
        ..lineTo(midX, parentCenterY)
        ..lineTo(midX, childCenterY)
        ..lineTo(childLeftX, childCenterY);
    }
  }

  /// Builds path for right-left orientation
  void buildRightLeftPath(Node node, Node child, Offset parentPos, Offset childPos,
      double parentCenterX, double parentCenterY, double childCenterX, double childCenterY) {
    final parentLeftX = parentPos.dx;
    final childRightX = childPos.dx + child.width;
    final midX = (parentLeftX + childRightX) * 0.5;

    if (configuration.useCurvedConnections) {
      linePath
        ..moveTo(childRightX, childCenterY)
        ..cubicTo(
          midX, childCenterY,
          midX, parentCenterY,
          parentLeftX, parentCenterY,
        );
    } else {
      linePath
        ..moveTo(parentLeftX, parentCenterY)
        ..lineTo(midX, parentCenterY)
        ..lineTo(midX, childCenterY)
        ..lineTo(childRightX, childCenterY);
    }
  }
}