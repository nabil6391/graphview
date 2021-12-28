part of graphview;

class BuchheimWalkerAlgorithm extends Algorithm {
  Map<Node, BuchheimWalkerNodeData> nodeData = {};
  double minNodeHeight = double.infinity;
  double minNodeWidth = double.infinity;
  double maxNodeWidth = double.negativeInfinity;
  double maxNodeHeight = double.negativeInfinity;
  BuchheimWalkerConfiguration configuration;

  bool isVertical() {
    var orientation = configuration.orientation;
    return orientation == BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM ||
        orientation == BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP;
  }

  bool needReverseOrder() {
    var orientation = configuration.orientation;
    return orientation == BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP ||
        orientation == BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT;
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    nodeData.clear();
    initData(graph);
    var firstNode = getFirstNode(graph!);
    firstWalk(graph, firstNode, 0, 0);
    secondWalk(graph, firstNode, 0.0);
    checkUnconnectedNotes(graph);
    positionNodes(graph);
    shiftCoordinates(graph, shiftX, shiftY);
    return calculateGraphSize(graph);
  }

  Node getFirstNode(Graph graph) => graph.nodes.firstWhere((element) => !hasPredecessor(element));

  void checkUnconnectedNotes(Graph graph) {
    graph.nodes.forEach((element) {
      if (getNodeData(element) == null) {
        if (!kReleaseMode) {
          print('$element is not connected to primary ancestor');
        }
      }
    });
  }

  int compare(int x, int y) {
    return x < y ? -1 : (x == y ? 0 : 1);
  }

  void firstWalk(Graph graph, Node node, int depth, int number) {
    final nodeData = getNodeData(node)!;
    nodeData.depth = depth;
    nodeData.number = number;
    minNodeHeight = min(minNodeHeight, node.height);
    minNodeWidth = min(minNodeWidth, node.width);
    maxNodeWidth = max(maxNodeWidth, node.width);
    maxNodeHeight = max(maxNodeHeight, node.height);

    if (isLeaf(graph, node)) {
      // if the node has no left sibling, prelim(node) should be set to 0, but we don't have to set it
      // here, because it's already initialized with 0
      if (hasLeftSibling(graph, node)) {
        final leftSibling = getLeftSibling(graph, node);
        nodeData.prelim = getPrelim(leftSibling) + getSpacing(graph, leftSibling, node);
      }
    } else {
      final leftMost = getLeftMostChild(graph, node);
      final rightMost = getRightMostChild(graph, node);
      var defaultAncestor = leftMost;

      Node? next = leftMost;
      var i = 1;
      while (next != null) {
        firstWalk(graph, next, depth + 1, i++);
        defaultAncestor = apportion(graph, next, defaultAncestor);

        next = getRightSibling(graph, next);
      }

      executeShifts(graph, node);

      var vertical = isVertical();
      var midPoint = 0.5 *
          ((getPrelim(leftMost) + getPrelim(rightMost) + (vertical ? rightMost!.width : rightMost!.height)) -
              (vertical ? node.width : node.height));

      if (hasLeftSibling(graph, node)) {
        final leftSibling = getLeftSibling(graph, node);
        nodeData.prelim = getPrelim(leftSibling) + getSpacing(graph, leftSibling, node);
        nodeData.modifier = nodeData.prelim - midPoint;
      } else {
        nodeData.prelim = midPoint;
      }
    }
  }

  void secondWalk(Graph graph, Node node, double modifier) {
    var nodeData = getNodeData(node)!;
    var depth = nodeData.depth;
    var vertical = isVertical();

    node.position = Offset((nodeData.prelim + modifier),
        (depth * (vertical ? minNodeHeight : minNodeWidth) + depth * configuration.levelSeparation).ceilToDouble());

    graph.successorsOf(node).forEach((w) {
      secondWalk(graph, w, modifier + nodeData.modifier);
    });
  }

  Size calculateGraphSize(Graph graph) {
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;

    graph.nodes.forEach((node) {
      left = min(left, node.x);
      top = min(top, node.y);
      right = max(right, node.x + node.width);
      bottom = max(bottom, node.y + node.height);
    });

    return Size(right - left, bottom - top);
  }

  void executeShifts(Graph graph, Node node) {
    var shift = 0.0;
    var change = 0.0;

    var w = getRightMostChild(graph, node);
    while (w != null) {
      final nodeData = getNodeData(w) ?? BuchheimWalkerNodeData();

      nodeData.prelim = nodeData.prelim + shift;
      nodeData.modifier = nodeData.modifier + shift;
      change += nodeData.change;
      shift += nodeData.shift + change;

      w = getLeftSibling(graph, w);
    }
  }

  Node apportion(Graph graph, Node node, Node defaultAncestor) {
    var ancestor = defaultAncestor;
    if (hasLeftSibling(graph, node)) {
      var leftSibling = getLeftSibling(graph, node);
      Node? vop = node;
      Node? vom = getLeftMostChild(graph, graph.predecessorsOf(node).first);
      var sip = getModifier(node);

      var sop = getModifier(node);

      var sim = getModifier(leftSibling);

      var som = getModifier(vom);
      var nextRight = this.nextRight(graph, leftSibling);

      Node? nextLeft;
      for (nextLeft = this.nextLeft(graph, node);
          nextRight != null && nextLeft != null;
          nextLeft = this.nextLeft(graph, nextLeft)) {
        vom = this.nextLeft(graph, vom);
        vop = this.nextRight(graph, vop);

        setAncestor(vop, node);
        var shift = getPrelim(nextRight) + sim - (getPrelim(nextLeft) + sip) + getSpacing(graph, nextRight, node);
        if (shift > 0) {
          moveSubtree(this.ancestor(graph, nextRight, node, ancestor), node, shift);
          sip += shift;
          sop += shift;
        }

        sim += getModifier(nextRight);
        sip += getModifier(nextLeft);

        som += getModifier(vom);
        sop += getModifier(vop);
        nextRight = this.nextRight(graph, nextRight);
      }

      if (nextRight != null && this.nextRight(graph, vop) == null) {
        setThread(vop, nextRight);
        setModifier(vop, getModifier(vop) + sim - sop);
      }

      if (nextLeft != null && this.nextLeft(graph, vom) == null) {
        setThread(vom, nextLeft);
        setModifier(vom, getModifier(vom) + sip - som);
        ancestor = node;
      }
    }

    return ancestor;
  }

  void setAncestor(Node? v, Node ancestor) {
      getNodeData(v)?.ancestor = ancestor;
  }

  void setModifier(Node? v, double modifier) {
    getNodeData(v)?.modifier = modifier;
  }

  void setThread(Node? v, Node thread) {
    getNodeData(v)?.thread = thread;
  }

  double getPrelim(Node? v) {
    return getNodeData(v)?.prelim ?? 0;
  }

  double getModifier(Node? vip) {
    return getNodeData(vip)?.modifier ?? 0;
  }

  void moveSubtree(Node? wm, Node wp, double shift) {
    var wpNodeData = getNodeData(wp)!;
    var wmNodeData = getNodeData(wm)!;
    var subtrees = wpNodeData.number - wmNodeData.number;
    wpNodeData.change = (wpNodeData.change - shift / subtrees);
    wpNodeData.shift = (wpNodeData.shift + shift);
    wmNodeData.change = (wmNodeData.change + shift / subtrees);
    wpNodeData.prelim = (wpNodeData.prelim + shift);
    wpNodeData.modifier = (wpNodeData.modifier + shift);
  }

  Node? ancestor(Graph graph, Node vim, Node node, Node defaultAncestor) {
    var vipNodeData = getNodeData(vim)!;
    return predecessorsOf(vipNodeData.ancestor).first == predecessorsOf(node).first
        ? vipNodeData.ancestor
        : defaultAncestor;
  }

  Node? nextRight(Graph graph, Node? node) {
    return graph.hasSuccessor(node) ? getRightMostChild(graph, node) : getNodeData(node)?.thread;
  }

  Node? nextLeft(Graph graph, Node? node) {
    return hasSuccessor(node)
        ? getLeftMostChild(graph, node)
        : getNodeData(node)?.thread;
  }

  num getSpacing(Graph graph, Node? leftNode, Node rightNode) {
    var separation = configuration.getSubtreeSeparation();
    if (isSibling(graph, leftNode, rightNode)) {
      separation = configuration.getSiblingSeparation();
    }

    num length = isVertical() ? leftNode!.width : leftNode!.height;

    return separation + length;
  }

  bool isSibling(Graph graph, Node? leftNode, Node rightNode) {
    var leftParent = predecessorsOf(leftNode).first;
    return successorsOf(leftParent).contains(rightNode);
  }

  bool isLeaf(Graph graph, Node node) {
    return successorsOf(node).isEmpty;
  }

  Node? getLeftSibling(Graph graph, Node node) {
    if (!hasLeftSibling(graph, node)) {
      return null;
    } else {
      var parent = predecessorsOf(node).first;
      var children = successorsOf(parent);
      var nodeIndex = children.indexOf(node);
      return children[nodeIndex - 1];
    }
  }

  bool hasLeftSibling(Graph graph, Node node) {
    var parents = predecessorsOf(node);
    if (parents.isEmpty) {
      return false;
    } else {
      var parent = parents.first;
      var nodeIndex = successorsOf(parent).indexOf(node);
      return nodeIndex > 0;
    }
  }

  Node? getRightSibling(Graph graph, Node node) {
    if (!hasRightSibling(graph, node)) {
      return null;
    } else {
      var parent = predecessorsOf(node).first;
      var children = successorsOf(parent);
      var nodeIndex = children.indexOf(node);
      return children[nodeIndex + 1];
    }
  }

  bool hasRightSibling(Graph graph, Node node) {
    var parents = predecessorsOf(node);
    if (parents.isEmpty) {
      return false;
    } else {
      var parent = parents[0];
      List children = successorsOf(parent);
      var nodeIndex = children.indexOf(node);
      return nodeIndex < children.length - 1;
    }
  }

  Node getLeftMostChild(Graph graph, Node? node) {
    return successorsOf(node).first;
  }

  Node? getRightMostChild(Graph graph, Node? node) {
    var children = successorsOf(node);
    return children.isEmpty ? null : children.last;
  }

  void positionNodes(Graph graph) {
    var doesNeedReverseOrder = needReverseOrder();

    var offset = getOffset(graph, doesNeedReverseOrder);
    var nodes = sortByLevel(graph, doesNeedReverseOrder);
    var firstLevel = getNodeData(nodes.first)?.depth ?? 0;
    var localMaxSize = findMaxSize(filterByLevel(nodes, firstLevel));
    var currentLevel = doesNeedReverseOrder ? firstLevel : 0;

    var globalPadding = 0.0;
    var localPadding = 0.0;
    nodes.forEach((node) {
      final depth = getNodeData(node)?.depth ?? 0;
      if (depth != currentLevel) {
        if (doesNeedReverseOrder) {
          globalPadding -= localPadding;
        } else {
          globalPadding += localPadding;
        }
        localPadding = 0.0;
        currentLevel = depth;

        localMaxSize = findMaxSize(filterByLevel(nodes, currentLevel));
      }

      final height = node.height;
      final width = node.width;
      switch (configuration.orientation) {
        case BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM:
          if (height > minNodeHeight) {
            final diff = height - minNodeHeight;
            localPadding = max(localPadding, diff);
          }
          break;
        case BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP:
          if (height < localMaxSize.height) {
            var diff = localMaxSize.height - height;
            node.position -= Offset(0, diff);
            localPadding = max(localPadding, diff);
          }
          break;
        case BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT:
          if (width > minNodeWidth) {
            final diff = width - minNodeWidth;
            localPadding = max(localPadding, diff);
          }
          break;
        case BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT:
          if (width < localMaxSize.width) {
            var diff = localMaxSize.width - width;
            node.position -= Offset(0, diff);
            localPadding = max(localPadding, diff);
          }
      }

      node.position = getPosition(node, globalPadding, offset);
    });
  }

  void shiftCoordinates(Graph graph, double shiftX, double shiftY) {
    graph.nodes.forEach((node) {
      node.position = (Offset(node.x + shiftX, node.y + shiftY));
    });
  }

  Size findMaxSize(List<Node> nodes) {
    var width = double.negativeInfinity;
    var height = double.negativeInfinity;

    nodes.forEach((node) {
      width = max(width, node.width);
      height = max(height, node.height);
    });

    return Size(width, height);
  }

  Offset getOffset(Graph graph, bool needReverseOrder) {
    var offsetX = double.infinity;
    var offsetY = double.infinity;

    if (needReverseOrder) {
      offsetY = double.minPositive;
    }

    graph.nodes.forEach((node) {
      if (needReverseOrder) {
        offsetX = min(offsetX, node.x);
        offsetY = max(offsetY, node.y);
      } else {
        offsetX = min(offsetX, node.x);
        offsetY = min(offsetY, node.y);
      }
    });

    return Offset(offsetX, offsetY);
  }

  Offset getPosition(Node node, double globalPadding, Offset offset) {
    Offset finalOffset;
    switch (configuration.orientation) {
      case 1:
        finalOffset = Offset(node.x - offset.dx, node.y + globalPadding);
        break;
      case 2:
        finalOffset = Offset(node.x - offset.dx, offset.dy - node.y - globalPadding);
        break;
      case 3:
        finalOffset = Offset(node.y + globalPadding, node.x - offset.dx);
        break;
      case 4:
        finalOffset = Offset(offset.dy - node.y - globalPadding, node.x - offset.dx);
        break;
      default:
        finalOffset = Offset(0, 0);
        break;
    }

    return finalOffset;
  }

  List<Node> sortByLevel(Graph graph, bool descending) {
    var nodes = <Node>[...graph.nodes];
    if (descending) {
      nodes.reversed;
    }
    nodes.sort((data1, data2) => compare(getNodeData(data1)?.depth ?? 0, getNodeData(data2)?.depth ?? 0));

    return nodes;
  }

  List<Node> filterByLevel(List<Node> nodes, int? level) {
    return nodes.where((node) => getNodeData(node)?.depth == level).toList();
  }

  @override
  EdgeRenderer? renderer;

  void initData(Graph? graph) {
    graph?.nodes.forEach((node) {
      var nodeDatab = BuchheimWalkerNodeData();
      nodeDatab.ancestor = node;

      nodeData[node] = nodeDatab;
    });

    graph?.edges.forEach((element) {
      nodeData[element.source]?.successorNodes.add(element.destination);
      nodeData[element.destination]?.predecessorNodes.add(element.source);
    });
  }

  BuchheimWalkerNodeData? getNodeData(Node? node) {
    return node == null ? null : nodeData[node];
  }

  bool hasSuccessor(Node? node) => successorsOf(node).isNotEmpty;

  bool hasPredecessor(Node node) => predecessorsOf(node).isNotEmpty;

  List<Node> successorsOf(Node? node) {
    return nodeData[node]?.successorNodes ?? [];
  }

  List<Node> predecessorsOf(Node? node) {
    return nodeData[node]?.predecessorNodes ?? [];
  }

  BuchheimWalkerAlgorithm(this.configuration, EdgeRenderer? renderer) {
    this.renderer = renderer ?? TreeEdgeRenderer(configuration);
  }

  @override
  void setFocusedNode(Node node) {}

  @override
  void init(Graph? graph) {
    var firstNode = getFirstNode(graph!);
    firstWalk(graph, firstNode, 0, 0);
    secondWalk(graph, firstNode, 0.0);
    checkUnconnectedNotes(graph);
    positionNodes(graph);
    // shiftCoordinates(graph, shiftX, shiftY);
  }

  @override
  void step(Graph? graph) {
    var firstNode = getFirstNode(graph!);
    firstWalk(graph, firstNode, 0, 0);
    secondWalk(graph, firstNode, 0.0);
    checkUnconnectedNotes(graph);
    positionNodes(graph);
  }

  @override
  void setDimensions(double width, double height) {
    // graphWidth = width;
    // graphHeight = height;
  }
}
