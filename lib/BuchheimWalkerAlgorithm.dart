library graphview;

import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'Graph.dart';
import 'Layout.dart';

class BuchheimWalkerAlgorithm extends Layout {
  Map<Node, BuchheimWalkerNodeData> mNodeData;
  double minNodeHeight;
  double minNodeWidth;
  double maxNodeWidth;
  double maxNodeHeight;
  BuchheimWalkerConfiguration configuration;

  bool isVertical() {
    int orientation = this.configuration.getOrientation();
    return orientation == 1 || orientation == 2;
  }

  int compare(int x, int y) {
    return x < y ? -1 : (x == y ? 0 : 1);
  }

  BuchheimWalkerNodeData createNodeData(Node node) {
    BuchheimWalkerNodeData var3 = BuchheimWalkerNodeData();
    var3.ancestor = node;

    mNodeData[node] = var3;
    return var3;
  }

  BuchheimWalkerNodeData getNodeData(Node node) {
    return mNodeData[node];
  }

  void firstWalk(Graph graph, Node node, int depth, int number) {
    final nodeData = createNodeData(node);
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
        nodeData.prelim =
            getPrelim(leftSibling) + getSpacing(graph, leftSibling, node);
      }
    } else {
      final leftMost = getLeftMostChild(graph, node);
      final rightMost = getRightMostChild(graph, node);
      var defaultAncestor = leftMost;

      var next = leftMost;
      var i = 1;
      while (next != null) {
        firstWalk(graph, next, depth + 1, i++);
        defaultAncestor = apportion(graph, next, defaultAncestor);

        next = getRightSibling(graph, next);
      }

      executeShifts(graph, node);

      double midPoint = 0.5 *
          ((getPrelim(leftMost) +
                  getPrelim(rightMost) +
                  (this.isVertical() ? rightMost.width : rightMost.height)
                      .toDouble()) -
              (this.isVertical() ? node.width : node.height));

      if (hasLeftSibling(graph, node)) {
        final leftSibling = getLeftSibling(graph, node);
        nodeData.prelim =
            getPrelim(leftSibling) + getSpacing(graph, leftSibling, node);
        nodeData.modifier = nodeData.prelim - midPoint;
      } else {
        nodeData.prelim = midPoint;
      }
    }
  }

  void secondWalk(Graph graph, Node node, double modifier) {
    BuchheimWalkerNodeData nodeData = this.getNodeData(node);
    int depth = nodeData.depth;
    bool vertical = this.isVertical();

    node.position = Offset(
        (nodeData.prelim + modifier),
        (depth * (vertical ? this.minNodeHeight : this.minNodeWidth) +
                depth * this.configuration.levelSeparation)
            .ceilToDouble());

    graph.successorsOf(node).forEach((w) {
      secondWalk(graph, w, modifier + nodeData.modifier);
    });
  }

  Size calculateGraphSize(Graph graph) {
    var left = double.infinity;
    var top = double.infinity;
    var right = -double.infinity;
    var bottom = -double.infinity;

    graph.nodes.forEach((node) {
      left = min(left, node.x);
      top = min(top, node.y);
      right = max(right, node.x + node.width);
      bottom = max(bottom, node.y + node.height);
    });

    return Size(right - left, bottom - top);
  }

  void executeShifts(Graph graph, Node node) {
    double shift = 0.0;
    double change = 0.0;

    var w = getRightMostChild(graph, node);
    while (w != null) {
      final nodeData = getNodeData(w);

      nodeData.prelim = nodeData.prelim + shift;
      nodeData.modifier = nodeData.modifier + shift;
      change += nodeData.change;
      shift += nodeData.shift + change;

      w = getLeftSibling(graph, w);
    }
  }

  Node apportion(Graph graph, Node node, Node defaultAncestor) {
    Node ancestor = defaultAncestor;
    if (this.hasLeftSibling(graph, node)) {
      Node leftSibling = this.getLeftSibling(graph, node);
      Node vop = node;
      Node vom = this.getLeftMostChild(graph, graph.predecessorsOf(node)[0]);
      double sip = this.getModifier(node);

      double sop = this.getModifier(node);

      double sim = this.getModifier(leftSibling);

      double som = this.getModifier(vom);
      Node nextRight = this.nextRight(graph, leftSibling);

      Node nextLeft;
      for (nextLeft = this.nextLeft(graph, node);
          nextRight != null && nextLeft != null;
          nextLeft = this.nextLeft(graph, nextLeft)) {
        vom = this.nextLeft(graph, vom);
        vop = this.nextRight(graph, vop);

        this.setAncestor(vop, node);
        double shift = this.getPrelim(nextRight) +
            sim -
            (this.getPrelim(nextLeft) + sip) +
            this.getSpacing(graph, nextRight, node);
        if (shift > 0) {
          this.moveSubtree(
              this.ancestor(graph, nextRight, node, ancestor), node, shift);
          sip += shift;
          sop += shift;
        }

        sim += this.getModifier(nextRight);
        sip += this.getModifier(nextLeft);

        som += this.getModifier(vom);
        sop += this.getModifier(vop);
        nextRight = this.nextRight(graph, nextRight);
      }

      if (nextRight != null && this.nextRight(graph, vop) == null) {
        this.setThread(vop, nextRight);
        this.setModifier(vop, this.getModifier(vop) + sim - sop);
      }

      if (nextLeft != null && this.nextLeft(graph, vom) == null) {
        this.setThread(vom, nextLeft);
        this.setModifier(vom, this.getModifier(vom) + sip - som);
        ancestor = node;
      }
    }

    return ancestor;
  }

  void setAncestor(Node v, Node ancestor) {
    this.getNodeData(v).ancestor = (ancestor);
  }

  void setModifier(Node v, double modifier) {
    this.getNodeData(v).modifier = (modifier);
  }

  void setThread(Node v, Node thread) {
    this.getNodeData(v).thread = (thread);
  }

  double getPrelim(Node v) {
    return this.getNodeData(v).prelim;
  }

  double getModifier(Node vip) {
    return this.getNodeData(vip).modifier;
  }

  void moveSubtree(Node wm, Node wp, double shift) {
    BuchheimWalkerNodeData wpNodeData = this.getNodeData(wp);
    BuchheimWalkerNodeData wmNodeData = this.getNodeData(wm);
    int subtrees = wpNodeData.number - wmNodeData.number;
    wpNodeData.change = (wpNodeData.change - shift / subtrees);
    wpNodeData.shift = (wpNodeData.shift + shift);
    wmNodeData.change = (wmNodeData.change + shift / subtrees);
    wpNodeData.prelim = (wpNodeData.prelim + shift);
    wpNodeData.modifier = (wpNodeData.modifier + shift);
  }

  Node ancestor(Graph graph, Node vim, Node node, Node defaultAncestor) {
    BuchheimWalkerNodeData vipNodeData = this.getNodeData(vim);
    return graph.predecessorsOf(vipNodeData.ancestor)[0] ==
            graph.predecessorsOf(node)[0]
        ? vipNodeData.ancestor
        : defaultAncestor;
  }

  Node nextRight(Graph graph, Node node) {
    return graph.hasSuccessor(node)
        ? this.getRightMostChild(graph, node)
        : this.getNodeData(node).thread;
  }

  Node nextLeft(Graph graph, Node node) {
    return graph.hasSuccessor(node)
        ? this.getLeftMostChild(graph, node)
        : this.getNodeData(node).thread;
  }

  num getSpacing(Graph graph, Node leftNode, Node rightNode) {
    int separation = this.configuration.getSubtreeSeparation();
    if (this.isSibling(graph, leftNode, rightNode)) {
      separation = this.configuration.getSiblingSeparation();
    }

    bool vertical = this.isVertical();
    num var10001;
    if (vertical) {
      var10001 = leftNode.width;
    } else {
      var10001 = leftNode.height;
    }

    return separation + var10001;
  }

  bool isSibling(Graph graph, Node leftNode, Node rightNode) {
    Node leftParent = graph.predecessorsOf(leftNode)[0];
    return graph.successorsOf(leftParent).contains(rightNode);
  }

  bool isLeaf(Graph graph, Node node) {
    return graph.successorsOf(node).isEmpty;
  }

  Node getLeftSibling(Graph graph, Node node) {
    if (!this.hasLeftSibling(graph, node)) {
      return null;
    } else {
      Node parent = graph.predecessorsOf(node)[0];
      List<Node> children = graph.successorsOf(parent);
      int nodeIndex = children.indexOf(node);
      return children[nodeIndex - 1];
    }
  }

  bool hasLeftSibling(Graph graph, Node node) {
    List<Node> parents = graph.predecessorsOf(node);
    if (parents.isEmpty) {
      return false;
    } else {
      Node parent = parents[0];
      int nodeIndex = graph.successorsOf(parent).indexOf(node);
      return nodeIndex > 0;
    }
  }

  Node getRightSibling(Graph graph, Node node) {
    if (!this.hasRightSibling(graph, node)) {
      return null;
    } else {
      var parent = graph.predecessorsOf(node)[0];
      var children = graph.successorsOf(parent);
      int nodeIndex = children.indexOf(node);
      return children[nodeIndex + 1];
    }
  }

  bool hasRightSibling(Graph graph, Node node) {
    var parents = graph.predecessorsOf(node);
    if (parents.isEmpty) {
      return false;
    } else {
      var parent = parents[0];
      List children = graph.successorsOf(parent);
      var nodeIndex = children.indexOf(node);
      return nodeIndex < children.length - 1;
    }
  }

  Node getLeftMostChild(Graph graph, Node node) {
    return graph.successorsOf(node)[0];
  }

  Node getRightMostChild(Graph graph, Node node) {
    var children = graph.successorsOf(node);
    return children.isEmpty ? null : children[children.length - 1];
  }

  Size run(Graph graph, double shiftX, double shiftY) {
    this.mNodeData.clear();
    var firstNode = graph.getNodeAtPosition(0);
    firstWalk(graph, firstNode, 0, 0);
    secondWalk(graph, firstNode, 0.0);
    positionNodes(graph);
    shiftCoordinates(graph, shiftX, shiftY);
    return calculateGraphSize(graph);
  }

  void positionNodes(Graph graph) {
    double globalPadding = 0;
    double localPadding = 0;
    Offset offset = this.getOffset(graph);
    int orientation = this.configuration.getOrientation();
    bool needReverseOrder = orientation == 2 || orientation == 4;
    List<Node> nodes = this.sortByLevel(graph, needReverseOrder);
    int firstLevel = this.getNodeData(nodes[0]).depth;
    Size localMaxSize = this.findMaxSize(this.filterByLevel(nodes, firstLevel));
    int currentLevel = needReverseOrder ? firstLevel : 0;

    nodes.forEach((node) {
      final depth = getNodeData(node).depth;
      if (depth != currentLevel) {
        switch (configuration.orientation) {
          case BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM:
          case BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT:
            globalPadding += localPadding;
            break;
          case BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP:
          case BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT:
            globalPadding -= localPadding;
        }
        localPadding = 0;
        currentLevel = depth;

        localMaxSize = findMaxSize(filterByLevel(nodes, currentLevel));
      }

      final height = node.height;
      final width = node.width;
      switch (configuration.orientation) {
        case BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM:
          if (height > minNodeHeight) {
            final double diff = height - minNodeHeight;
            localPadding = max(localPadding, diff);
          }
          break;

        case BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP:
          if (height < localMaxSize.height) {
            double diff = localMaxSize.height - height;
            node.position = (node.position - (Offset(0, diff)));
            localPadding = max(localPadding, diff);
          }
          break;
        case BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT:
          if (width > minNodeWidth) {
            final double diff = width - minNodeWidth;
            localPadding = max(localPadding, diff);
          }
          break;
        case BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT:
          if (width < localMaxSize.width) {
            double diff = localMaxSize.width - width;
            node.position = (node.position - (Offset(0, diff)));
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

  Offset getOffset(Graph graph) {
    var offsetX = double.infinity;
    var offsetY = double.infinity;

    switch (configuration.orientation) {
      case BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP:
      case BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT:
        offsetY = double.minPositive;
    }

    graph.nodes.forEach((node) {
      switch (configuration.orientation) {
        case BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM:
        case BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT:
          offsetX = min(offsetX, node.x);
          offsetY = min(offsetY, node.y);
          break;
        case BuchheimWalkerConfiguration.ORIENTATION_BOTTOM_TOP:
        case BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT:
          offsetX = min(offsetX, node.x);
          offsetY = max(offsetY, node.y);
      }
    });

    return Offset(offsetX, offsetY);
  }

  Offset getPosition(Node node, double globalPadding, Offset offset) {
    Offset var10000;
    switch (this.configuration.getOrientation()) {
      case 1:
        var10000 = Offset(node.x - offset.dx, node.y + globalPadding);
        break;
      case 2:
        var10000 =
            Offset(node.x - offset.dx, offset.dy - node.y - globalPadding);
        break;
      case 3:
        var10000 = Offset(node.y + globalPadding, node.x - offset.dx);
        break;
      case 4:
        var10000 =
            Offset(offset.dy - node.y - globalPadding, node.x - offset.dx);
        break;
    }

    return var10000;
  }

  List<Node> sortByLevel(Graph graph, bool descending) {
    List<Node> nodes = []..addAll(graph.nodes);
    if (descending) {
      nodes.reversed;
    }
    nodes.sort((data1, data2) =>
        compare(getNodeData(data1).depth, getNodeData(data2).depth));

    return nodes;
  }

  List<Node> filterByLevel(List<Node> nodes, int level) {
    return nodes.where((node) => getNodeData(node).depth == level).toList();
  }

  void drawEdges(Canvas canvas, Graph graph, Paint linePaint) {}

  BuchheimWalkerAlgorithm(BuchheimWalkerConfiguration configuration) {
    this.configuration = configuration;
    this.mNodeData = HashMap();
    this.minNodeHeight = double.infinity;
    this.minNodeWidth = double.infinity;
    this.maxNodeWidth = double.negativeInfinity;
    this.maxNodeHeight = double.negativeInfinity;
  }
}

class BuchheimWalkerNodeData {
  Node ancestor;
  Node thread;
  int number = 0;
  int depth = 0;
  double prelim = 0.toDouble();
  double modifier = 0.toDouble();
  double shift = 0.toDouble();
  double change = 0.toDouble();
}

class BuchheimWalkerConfiguration {
  int siblingSeparation;
  int levelSeparation;
  int subtreeSeparation;
  int orientation;
  static const ORIENTATION_TOP_BOTTOM = 1;
  static const ORIENTATION_BOTTOM_TOP = 2;
  static const ORIENTATION_LEFT_RIGHT = 3;
  static const ORIENTATION_RIGHT_LEFT = 4;
  static const DEFAULT_SIBLING_SEPARATION = 100;
  static const DEFAULT_SUBTREE_SEPARATION = 100;
  static const DEFAULT_LEVEL_SEPARATION = 100;
  static const DEFAULT_ORIENTATION = 1;

  int getSiblingSeparation() {
    return this.siblingSeparation;
  }

  int getLevelSeparation() {
    return this.levelSeparation;
  }

  int getSubtreeSeparation() {
    return this.subtreeSeparation;
  }

  int getOrientation() {
    return this.orientation;
  }
}
