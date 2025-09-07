part of graphview;

enum MindmapSide { LEFT, RIGHT, ROOT }

class _SideData {
  MindmapSide side = MindmapSide.ROOT;
}

class MindmapAlgorithm extends BuchheimWalkerAlgorithm {
  final Map<Node, _SideData> _side = {};

  MindmapAlgorithm(BuchheimWalkerConfiguration config, EdgeRenderer? renderer)
      : super(config, renderer ?? MindmapEdgeRenderer(config));

  @override
  void initData(Graph? graph) {
    super.initData(graph);
    _side.clear();
    graph?.nodes.forEach((n) => _side[n] = _SideData());
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    initData(graph);
    _detectCycles(graph!);
    final root = getFirstNode(graph);
    _applyBuchheimWalkerSpacing(graph, root);
    _createMindmapLayout(graph, root);
    shiftCoordinates(graph, shiftX, shiftY);
    return calculateGraphSize(graph);
  }

  void _markSubtree(Node node, MindmapSide side) {
    final d = _side[node]!;
    d.side = side;

    for (final child in successorsOf(node)) {
      _markSubtree(child, side);
    }
  }

  void _applyBuchheimWalkerSpacing(Graph graph, Node root) {
    // Apply the standard Buchheim-Walker algorithm to get proper spacing
    // This gives us optimal spacing relationships between all nodes
    firstWalk(graph, root, 0, 0);
    secondWalk(graph, root, 0.0);
    positionNodes(graph);

    // At this point, all nodes have positions with proper spacing,
    // but they're in a traditional tree layout. We'll reposition them next.
  }

  void _createMindmapLayout(Graph graph, Node root) {
    final vertical = isVertical();
    final rootPos = vertical ? root.x : root.y;

    // Mark subtrees and position nodes in one pass
    for (final child in successorsOf(root)) {
      final childPos = vertical ? child.x : child.y;
      final side = childPos < rootPos ? MindmapSide.LEFT : MindmapSide.RIGHT;
      _markSubtree(child, side);
    }

    // Position all non-root nodes
    for (final node in graph.nodes) {
      final info = nodeData[node]!;
      if (info.depth == 0) continue; // Skip root

      final sideMultiplier = _side[node]!.side == MindmapSide.LEFT ? -1 : 1;
      final secondary = vertical ? node.x : node.y;
      final distanceFromRoot = info.depth * configuration.levelSeparation +
          (vertical ? maxNodeWidth : maxNodeHeight) / 2;

      if (vertical) {
        node.position = Offset(
            secondary - root.x * 0.5 * sideMultiplier,
            sideMultiplier * distanceFromRoot
        );
      } else {
        node.position = Offset(
            sideMultiplier * distanceFromRoot,
            secondary - root.y * 0.5 * sideMultiplier
        );
      }
    }

    // Adjust root and apply final transformations
    if (needReverseOrder()) {
      if (vertical) {
        root.y = 0.0;
      } else {
        root.x = 0.0;
      }
    }

    for (final node in graph.nodes) {
      final info = nodeData[node]!;
      if (info.depth == 0) {
        if (vertical) {
          node.x = node.x * 0.5;
        } else {
          node.y = node.y * 0.5;
        }
      } else {
        if (vertical) {
          node.x = node.x - root.x;
        } else {
          node.y = node.y - root.y;
        }
      }
    }
  }
}
