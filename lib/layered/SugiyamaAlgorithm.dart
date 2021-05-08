part of graphview;

class SugiyamaAlgorithm extends Algorithm {
  Map<Node, SugiyamaNodeData> nodeData = {};
  Map<Edge, SugiyamaEdgeData> edgeData = {};
  Set<Node> stack = {};
  Set<Node> visited = {};
  List<List<Node?>> layers = [];
  late Graph graph;
  SugiyamaConfiguration configuration;

  @override
  EdgeRenderer? renderer;

  var nodeCount = 1;

  SugiyamaAlgorithm(this.configuration) {
    renderer = SugiyamaEdgeRenderer(nodeData, edgeData);
  }

  Widget get dummyText => Text("Dummy ${nodeCount++}");

  bool isVertical() {
    var orientation = configuration.orientation;
    return orientation == SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM ||
        orientation == SugiyamaConfiguration.ORIENTATION_BOTTOM_TOP;
  }

  bool needReverseOrder() {
    var orientation = configuration.orientation;
    return orientation == SugiyamaConfiguration.ORIENTATION_BOTTOM_TOP ||
        orientation == SugiyamaConfiguration.ORIENTATION_RIGHT_LEFT;
  }

  Size run(Graph? graph, double shiftX, double shiftY) {
    this.graph = copyGraph(graph!);
    reset();
    initSugiyamaData();
    cycleRemoval();
    layerAssignment();
    nodeOrdering(); //expensive operation
    coordinateAssignment(); //expensive operation
    shiftCoordinates(shiftX, shiftY);
    final graphSize = calculateGraphSize(this.graph);
    denormalize();
    restoreCycle();
    return graphSize;
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

  void shiftCoordinates(double shiftX, double shiftY) {
    layers.forEach((List<Node?> arrayList) {
      arrayList.forEach((it) {
        it!.position = Offset(it.x + shiftX, it.y + shiftY);
      });
    });
  }

  void reset() {
    layers.clear();
    stack.clear();
    visited.clear();
    nodeData.clear();
    edgeData.clear();
    nodeCount = 1;
  }

  void initSugiyamaData() {
    graph.nodes.forEach((node) {
      node.position = Offset(0, 0);
      nodeData[node] = SugiyamaNodeData();
    });

    graph.edges.forEach((edge) {
      edgeData[edge] = SugiyamaEdgeData();
    });
  }

  void cycleRemoval() {
    graph.nodes.forEach((node) {
      dfs(node);
    });
  }

  void dfs(Node node) {
    if (visited.contains(node)) {
      return;
    }
    visited.add(node);
    stack.add(node);
    graph.getOutEdges(node).forEach((edge) {
      final target = edge.destination;
      if (stack.contains(target)) {
        graph.removeEdge(edge);
        graph.addEdge(target, node);
        nodeData[node]!.reversed.add(target);
      } else {
        dfs(target);
      }
    });
    stack.remove(node);
  }

  // top sort + add dummy nodes;
  void layerAssignment() {
    if (graph.nodes.isEmpty) {
      return;
    }
    // build layers;
    final copiedGraph = copyGraph(graph);
    var roots = getRootNodes(copiedGraph);

    while (roots.isNotEmpty) {
      layers.add(roots);
      copiedGraph.removeNodes(roots);
      roots = getRootNodes(copiedGraph);
    }

    // add dummy's;
    for (var i = 0; i < layers.length - 1; i++) {
      var indexNextLayer = i + 1;
      var currentLayer = layers[i];
      var nextLayer = layers[indexNextLayer];

      for (var node in currentLayer) {
        final edges = graph.edges
            .where((element) =>
                element.source == node && ((nodeData[element.destination]!.layer - nodeData[node!]!.layer).abs() > 1))
            .toList();

        final iterator = edges.iterator;

        while (iterator.moveNext()) {
          final edge = iterator.current;
          final dummy = Node(dummyText);
          final dummyNodeData = SugiyamaNodeData();
          dummyNodeData.isDummy = true;
          dummyNodeData.layer = indexNextLayer;
          nextLayer.add(dummy);
          nodeData[dummy] = dummyNodeData;
          dummy.size = Size(edge.source.width, 0); // calc TODO avg layer height;
          final dummyEdge1 = graph.addEdge(edge.source, dummy);
          final dummyEdge2 = graph.addEdge(dummy, edge.destination);
          edgeData[dummyEdge1] = SugiyamaEdgeData();
          edgeData[dummyEdge2] = SugiyamaEdgeData();
          graph.removeEdge(edge);
//                    iterator.remove();
        }
      }
    }
  }

  List<Node> getRootNodes(Graph graph) {
    var roots = <Node>[];
    graph.nodes.forEach((node) {
      var inDegree = 0;
      graph.edges.forEach((edge) {
        var destination = edge.destination;

        if (destination == node) {
          inDegree++;
        }
      });
      if (inDegree == 0) {
        roots.add(node);
        nodeData[node]!.layer = layers.length;
      }
    });
    return roots;
  }

  Graph copyGraph(Graph graph) {
    final copy = Graph();
    copy.addNodes(graph.nodes);
    copy.addEdges(graph.edges);
    return copy;
  }

  void nodeOrdering() {
    final best = <List<Node?>>[...layers];

    for (var i = 0; i < 23; i++) {
      median(best, i);
      transpose(best);
      if (crossing(best) < crossing(layers)) {
        layers = best;
      }
    }
  }

  void median(List<List<Node?>> layers, int currentIteration) {
    if (currentIteration % 2 == 0) {
      for (var i = 1; i < layers.length; i++) {
        var currentLayer = layers[i];
        var previousLayer = layers[i - 1];

        for (var node in currentLayer) {
          final positions = graph.edges
              .where((element) => previousLayer.contains(element.source))
              .map((e) => previousLayer.indexOf(e.source))
              .toList();
          positions.sort();
          final median = positions.length ~/ 2;
          if (positions.isNotEmpty) {
            if (positions.length == 1) {
              nodeData[node!]!.median = -1;
            } else if (positions.length == 2) {
              nodeData[node!]!.median = (positions[0] + positions[1]) ~/ 2;
            } else if (positions.length % 2 == 1) {
              nodeData[node!]!.median = positions[median];
            } else {
              final left = positions[median - 1] - positions[0];
              final right = positions[positions.length - 1] - positions[median];
              if (left + right != 0) {
                nodeData[node!]!.median = (positions[median - 1] * right + positions[median] * left) ~/ (left + right);
              }
            }
          }
        }

        currentLayer.sort((n1, n2) {
          return nodeData[n1!]!.median - nodeData[n2!]!.median;
        });
      }
    } else {
      for (var l = 1; l < layers.length; l++) {
        var currentLayer = layers[l];
        var previousLayer = layers[l - 1];

        for (var i = currentLayer.length - 1; i > 1; i--) {
          final node = currentLayer[i];
          final positions = graph.edges
              .where((element) => previousLayer.contains(element.source))
              .map((e) => previousLayer.indexOf(e.source))
              .toList();
          positions.sort();
          if (positions.isNotEmpty) {
            if (positions.length == 1) {
              nodeData[node!]!.median = positions[0];
            } else {
              nodeData[node!]!.median =
                  (positions[(positions.length / 2.0).ceil()] + positions[(positions.length / 2.0).ceil() - 1]) ~/ 2;
            }
          }
        }

        currentLayer.sort((n1, n2) {
          return nodeData[n1!]!.median - nodeData[n2!]!.median;
        });
      }
    }
  }

  void transpose(List<List<Node?>> layers) {
    var improved = true;
    while (improved) {
      improved = false;
      for (var l = 0; l < layers.length - 1; l++) {
        final northernNodes = layers[l];
        final southernNodes = layers[l + 1];

        for (var i = 0; i < southernNodes.length - 1; i++) {
          final v = southernNodes[i];
          final w = southernNodes[i + 1];
          if (crossingb(northernNodes, v, w) > crossingb(northernNodes, w, v)) {
            improved = true;
            exchange(southernNodes, v, w);
          }
        }
      }
    }
  }

  void exchange(List<Node?> nodes, Node? v, Node? w) {
    var i = nodes.indexOf(v);
    var j = nodes.indexOf(w);
    var temp = nodes[i];
    nodes[i] = nodes[j];
    nodes[j] = temp;
  }

  // counts the number of edge crossings if n2 appears to the left of n1 in their layer.;
  int crossingb(List<Node?> northernNodes, Node? n1, Node? n2) {
    var crossing = 0;
    final parentNodesN1 = graph.edges.where((element) => element.destination == n1).map((e) => e.source).toList();
    final parentNodesN2 = graph.edges.where((element) => element.destination == n2).map((e) => e.source).toList();
    parentNodesN2.forEach((pn2) {
      final indexOfPn2 = northernNodes.indexOf(pn2);
      parentNodesN1.where((it) => indexOfPn2 < northernNodes.indexOf(it)).forEach((element) {
        crossing++;
      });
    });

    return crossing;
  }

  int crossing(List<List<Node?>> layers) {
    var crossinga = 0;

    for (var l = 0; l < layers.length - 1; l++) {
      final southernNodes = layers[l];
      final northernNodes = layers[l + 1];

      for (var i = 0; i < southernNodes.length - 2; i++) {
        final v = southernNodes[i];
        final w = southernNodes[i + 1];
        crossinga += crossingb(northernNodes, v, w);
      }
    }
    return crossinga;
  }

  void coordinateAssignment() {
    assignX();
    assignY();
    var offset = getOffset(graph, needReverseOrder());

    graph.nodes.forEach((v) {
      v.position = getPosition(v, offset);
    });
  }

  void assignX() {
    // each node points to the root of the block.;
    final root = <Map<Node, Node>>[];
    // each node points to its aligned neighbor in the layer below.;
    final align = <Map<Node, Node>>[];
    final sink = <Map<Node, Node>>[];
    final x = <Map<Node, double>>[];
    // minimal separation between the roots of different classes.;
    final shift = <Map<Node, double>>[];
    // the width of each block (max width of node in block);
    final blockWidth = <Map<Node?, double>>[];

    for (var i = 0; i < 4; i++) {
      root.add({});
      align.add({});
      sink.add({});
      shift.add({});
      x.add({});
      blockWidth.add({});

      graph.nodes.forEach((n) {
        root[i][n] = n;
        align[i][n] = n;
        sink[i][n] = n;
        shift[i][n] = double.infinity;
        x[i][n] = double.negativeInfinity;
        blockWidth[i][n] = 0;
      });
    }

    // calc the layout for down/up and leftToRight/rightToLeft;
    for (var downward = 0; downward <= 1; downward++) {
      var isDownward = downward == 0;
      final type1Conflicts = markType1Conflicts(isDownward);
      for (var leftToRight = 0; leftToRight <= 1; leftToRight++) {
        final k = 2 * downward + leftToRight;
        var isLeftToRight = leftToRight == 0;
        verticalAlignment(root[k], align[k], type1Conflicts, isDownward, isLeftToRight);

        graph.nodes.forEach((v) {
          final r = root[k][v];
          blockWidth[k][r] = max(blockWidth[k][r]!, isVertical() ? v.width : v.height);
        });
        horizontalCompactation(align[k], root[k], sink[k], shift[k], blockWidth[k], x[k], isLeftToRight, isDownward);
      }
    }

    balance(x, blockWidth);
  }

  void balance(List<Map<Node?, double?>> x, List<Map<Node?, double>> blockWidth) {
    final coordinates = <Node, double>{};
    var minWidth = double.infinity;
    var smallestWidthLayout = 0;
    final minArray = List.filled(4, 0.0);
    final maxArray = List.filled(4, 0.0);

    // get the layout with smallest width and set minimum and maximum value for each direction;
    for (var i = 0; i < 4; i++) {
      minArray[i] = double.infinity;
      maxArray[i] = 0;

      graph.nodes.forEach((v) {
        final bw = 0.5 * blockWidth[i][v]!;
        var xp = x[i][v]! - bw;
        if (xp < minArray[i]) {
          minArray[i] = xp;
        }
        xp = x[i][v]! + bw;
        if (xp > maxArray[i]) {
          maxArray[i] = xp;
        }
      });
      final width = maxArray[i] - minArray[i];
      if (width < minWidth) {
        minWidth = width;
        smallestWidthLayout = i;
      }
    }

    // align the layouts to the one with smallest width
    for (var layout = 0; layout < 4; layout++) {
      if (layout != smallestWidthLayout) {
        // align the left to right layouts to the left border of the smallest layout
        var diff = 0.0;
        if (layout < 2) {
          diff = minArray[layout] - minArray[smallestWidthLayout];
        } else {
          // align the right to left layouts to the right border of the smallest layout
          diff = maxArray[layout] - maxArray[smallestWidthLayout];
        }
        if (diff > 0) {
          x[layout].keys.forEach((n) {
            x[layout][n] = x[layout][n]! - diff;
          });
        } else {
          x[layout].keys.forEach((n) {
            x[layout][n] = x[layout][n]! + diff;
          });
        }
      }
    }

    // get the minimum coordinate value
    double? minValue = double.infinity;

    x.forEach((element) {
      element.forEach((key, value) {
        if (value! < minValue!) {
          minValue = value;
        }
      });
    });

    // get the average median of each coordinate
    var values = List.filled(4, 0.0);
    graph.nodes.forEach((n) {
      for (var i = 0; i < 4; i++) {
        values[i] = x[i][n]!;
      }
      values.sort();
      var average = (values[1] + values[2]) / 2;
      coordinates[n] = average;
    });

    // get the minimum coordinate value
    minValue = coordinates.values.reduce(min);

    // set left border to 0
    if (minValue != 0) {
      coordinates.keys.forEach((n) {
        coordinates[n] = coordinates[n]! - minValue!;
      });
    }

    graph.nodes.forEach((v) {
      v.x = coordinates[v]!;
    });
  }

  List<List<bool>> markType1Conflicts(bool downward) {
    final type1Conflicts = <List<bool>>[];

    graph.nodes.asMap().forEach((i, value) {
      type1Conflicts.add([]);
      graph.edges.forEach((element) {
        type1Conflicts[i].add(false);
      });
    });

    if (layers.length >= 4) {
      int upper;
      int lower; // iteration bounds;
      int k1; // node position boundaries of closest inner segments;
      if (downward) {
        lower = 1;
        upper = layers.length - 2;
      } else {
        lower = layers.length - 1;
        upper = 2;
      }
      /*;
             * iterate level[2..h-2] in the given direction;
             * available 1 levels to h;
             */
      var i = lower;
      while (downward && i <= upper || !downward && i >= upper) {
        var k0 = 0;
        var firstIndex = 0; // index of first node on layer;
        final currentLevel = layers[i];
        final nextLevel = downward ? layers[i + 1] : layers[i - 1];
        // for all nodes on next level;
        for (var l1 = 0; l1 < nextLevel.length; l1++) {
          final virtualTwin = virtualTwinNode(nextLevel[l1], downward);
          if (l1 == nextLevel.length - 1 || virtualTwin != null) {
            k1 = currentLevel.length - 1;
            if (virtualTwin != null) {
              k1 = positionOfNode(virtualTwin);
            }
            while (firstIndex <= l1) {
              final upperNeighbours = getAdjNodes(nextLevel[l1], downward);
              for (var currentNeighbour in upperNeighbours) {
                /*;
                *  XXX< 0 in first iteration is still ok for indizes starting;
                * with 0 because no index can be smaller than 0;
                 */
                final currentNeighbourIndex = positionOfNode(currentNeighbour);
                if (currentNeighbourIndex < k0 || currentNeighbourIndex > k1) {
                  type1Conflicts[l1][currentNeighbourIndex] = true;
                }
              }
              firstIndex++;
            }
            k0 = k1;
          }
        }
        i = downward ? i + 1 : i - 1;
      }
    }
    return type1Conflicts;
  }

  void verticalAlignment(
      Map<Node?, Node?> root, Map<Node?, Node?> align, List<List<bool>> type1Conflicts, bool downward, bool leftToRight) {
    // for all Level;
    var i = downward ? 0 : layers.length - 1;
    while (downward && i <= layers.length - 1 || !downward && i >= 0) {
      final currentLevel = layers[i];
      var r = leftToRight ? -1 : double.infinity;
      // for all nodes on Level i (with direction leftToRight);
      var k = leftToRight ? 0 : currentLevel.length - 1;
      while (leftToRight && k <= currentLevel.length - 1 || !leftToRight && k >= 0) {
        final v = currentLevel[k];
        final adjNodes = getAdjNodes(v, downward);
        if (adjNodes.isNotEmpty) {
          // the first median;
          final median = ((adjNodes.length + 1) / 2.0).floor();
          final medianCount = adjNodes.length % 2 == 1 ? 1 : 2;
          // for all median neighbours in direction of H;

          for (var count = 0; count < medianCount; count++) {
            final m = adjNodes[median + count - 1];
            final posM = positionOfNode(m);
            if (align[v] == v
                // if segment (u,v) not marked by type1 conflicts AND ...;
                &&
                !type1Conflicts[positionOfNode(v)][posM] &&
                (leftToRight && r < posM || !leftToRight && r > posM)) {
              align[m] = v;
              root[v] = root[m];
              align[v] = root[v];
              r = posM;
            }
          }
        }
        k = leftToRight ? k + 1 : k - 1;
      }
      i = downward ? i + 1 : i - 1;
    }
  }

  void horizontalCompactation(Map<Node?, Node?> align, Map<Node?, Node?> root, Map<Node?, Node?> sink,
      Map<Node?, double> shift, Map<Node?, double> blockWidth, Map<Node?, double?> x, bool leftToRight, bool downward) {
    // calculate class relative coordinates for all roots;
    var i = downward ? 0 : layers.length - 1;
    while (downward && i <= layers.length - 1 || !downward && i >= 0) {
      final currentLevel = layers[i];
      var j = leftToRight ? 0 : currentLevel.length - 1;
      while (leftToRight && j <= currentLevel.length - 1 || !leftToRight && j >= 0) {
        final v = currentLevel[j];
        if (root[v] == v) {
          placeBlock(v, sink, shift, x, align, blockWidth, root, leftToRight);
        }
        j = (leftToRight) ? j + 1 : j - 1;
      }
      i = (downward) ? i + 1 : i - 1;
    }
    var d = 0;
    i = downward ? 0 : layers.length - 1;
    while (downward && i <= layers.length - 1 || !downward && i >= 0) {
      final currentLevel = layers[i];
      final v = currentLevel[leftToRight ? 0 : currentLevel.length - 1];
      if (v == sink[root[v]]) {
        final oldShift = shift[v]!;
        if (oldShift < double.infinity) {
          shift[v] = oldShift + d;
          d += oldShift.toInt();
        } else {
          shift[v] = 0;
        }
      }
      i = downward ? i + 1 : i - 1;
    }
    // apply root coordinates for all aligned nodes;
    // (place block did this only for the roots)+;
    graph.nodes.forEach((v) {
      x[v] = x[root[v]];
      final shiftVal = shift[sink[root[v]]]!;
      if (shiftVal < double.infinity) {
        x[v] = x[v]! + shiftVal; // apply shift for each class;
      }
    });
  }

  void placeBlock(Node? v, Map<Node?, Node?> sink, Map<Node?, double> shift, Map<Node?, double?> x, Map<Node?, Node?> align,
      Map<Node?, double> blockWidth, Map<Node?, Node?> root, bool leftToRight) {
    if (x[v] == double.negativeInfinity) {
      x[v] = 0;
      var w = v;

      try {
        do {
          // if not first node on layer;
          if (leftToRight && positionOfNode(w) > 0 ||
              !leftToRight && positionOfNode(w) < layers[getLayerIndex(w)].length - 1) {
            final pred = predecessor(w, leftToRight);
            final u = root[pred];
            placeBlock(u, sink, shift, x, align, blockWidth, root, leftToRight);
            if (sink[v] == v) {
              sink[v] = sink[u];
            }
            if (sink[v] != sink[u]) {
              if (leftToRight) {
                shift[sink[u]] = min(
                    shift[sink[u]]!, x[v]! - x[u]! - configuration.nodeSeparation - 0.5 * (blockWidth[u]! + blockWidth[v]!));
              } else {
                shift[sink[u]] = max(
                    shift[sink[u]]!, x[v]! - x[u]! + configuration.nodeSeparation + 0.5 * (blockWidth[u]! + blockWidth[v]!));
              }
            } else {
              if (leftToRight) {
                x[v] = max(x[v]!, x[u]! + configuration.nodeSeparation + 0.5 * (blockWidth[u]! + blockWidth[v]!));
              } else {
                x[v] = min(x[v]!, x[u]! - configuration.nodeSeparation - 0.5 * (blockWidth[u]! + blockWidth[v]!));
              }
            }
          }
          w = align[w];
        } while (w != v);
      } catch (e) {
        print(e);
      }
    }
  }

  // predecessor;
  Node? predecessor(Node? v, bool leftToRight) {
    final pos = positionOfNode(v);
    final rank = getLayerIndex(v);
    final level = layers[rank];
    return (leftToRight && pos != 0 || !leftToRight && pos != level.length - 1)
        ? level[(leftToRight) ? pos - 1 : pos + 1]
        : null;
  }

  Node? virtualTwinNode(Node? node, bool downward) {
    if (!isLongEdgeDummy(node)) {
      return null;
    }
    final adjNodes = getAdjNodes(node, downward);
    return adjNodes.isEmpty ? null : adjNodes[0];
  }

  List<Node> getAdjNodes(Node? node, bool downward) {
    return downward ? graph.predecessorsOf(node) : graph.successorsOf(node);
  }

  // get node index in layer;
  int positionOfNode(Node? node) {
    for (var l in layers) {
      for (var n in l) {
        if (node == n) {
          return l.indexOf(node);
        }
      }
    }
    return -1; // or exception?
  }

  int getLayerIndex(Node? node) {
    var l = -1;
    for (var layer in layers) {
      l++;
      for (var n in layer) {
        if (node == n) {
          return l;
        }
      }
    }
    return l; // or exception?;
  }

  bool isLongEdgeDummy(Node? v) {
    final successors = graph.successorsOf(v);
    return nodeData[v!]!.isDummy && successors.length == 1 && nodeData[successors[0]]!.isDummy;
  }

  void assignY() {
    // compute y-coordinates;
    final k = layers.length;
    // compute height of each layer;
    final height = List.filled(graph.nodes.length, 0);

    for (var i = 0; i < k; i++) {
      var level = layers[i];
      level.forEach((node) {
        var h = nodeData[node!]!.isDummy ? 0 : isVertical() ? node.height : node.width;
        if (h > height[i]) {
          height[i] = h.toInt();
        }
      });
    }

    // assign y-coordinates
    var yPos = 0.0;
    for (var i = 0; i < k; i++) {
      var level = layers[i];
      level.forEach((node) {
        node!.y = yPos;
      });
      if(i < k - 1) {
        yPos += configuration.levelSeparation + 0.5 * (height[i] + height[i + 1]);
      }
    }
  }

  void denormalize() {
    // remove dummy's;
    for (var i = 1; i < layers.length - 1; i++) {
      final iterator = layers[i].iterator;

      while (iterator.moveNext()) {
        final current = iterator.current;
        if (nodeData[current!]!.isDummy) {
          final predecessor = graph.predecessorsOf(current)[0];
          final successor = graph.successorsOf(current)[0];
          final bendPoints = edgeData[graph.getEdgeBetween(predecessor, current)!]!.bendPoints;

          if (bendPoints.isEmpty || !bendPoints.contains(current.x + predecessor.width / 2)) {
            bendPoints.add(predecessor.x + predecessor.width / 2);
            bendPoints.add(predecessor.y + predecessor.height / 2);
            bendPoints.add(current.x + predecessor.width / 2);
            bendPoints.add(current.y);
          }
          if (!nodeData[predecessor]!.isDummy) {
            bendPoints.add(current.x + predecessor.width / 2);
          } else {
            bendPoints.add(current.x);
          }
          bendPoints.add(current.y);
          if (nodeData[successor]!.isDummy) {
            bendPoints.add(successor.x + predecessor.width / 2);
          } else {
            bendPoints.add(successor.x + successor.width / 2);
          }
          bendPoints.add(successor.y + successor.height / 2);
          graph.removeEdgeFromPredecessor(predecessor, current);
          graph.removeEdgeFromPredecessor(current, successor);

          final edge = graph.addEdge(predecessor, successor);
          final sugiyamaEdgeData = SugiyamaEdgeData();
          sugiyamaEdgeData.bendPoints = bendPoints;
          edgeData[edge] = sugiyamaEdgeData;

//          iterator.remove();
          graph.removeNode(current);
        }
      }
    }
  }

  void restoreCycle() {
    graph.nodes.forEach((n) {
      if (nodeData[n]!.isReversed) {
        nodeData[n]!.reversed.forEach((target) {
          final bendPoints = this.edgeData[graph.getEdgeBetween(target, n)!]!.bendPoints;
          graph.removeEdgeFromPredecessor(target, n);
          final edge = graph.addEdge(n, target);

          final edgeData = SugiyamaEdgeData();
          edgeData.bendPoints = bendPoints;
          this.edgeData[edge] = edgeData;
        });
      }
    });
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

  Offset getPosition(Node node, Offset offset) {
    Offset finalOffset;
    switch (configuration.orientation) {
      case 1:
        finalOffset = Offset(node.x - offset.dx, node.y);
        break;
      case 2:
        finalOffset = Offset(node.x - offset.dx, offset.dy - node.y);
        break;
      case 3:
        finalOffset = Offset(node.y, node.x - offset.dx);
        break;
      case 4:
        finalOffset = Offset(offset.dy - node.y, node.x - offset.dx);
        break;
      default:
        finalOffset = Offset(0,0);
        break;
    }

    return finalOffset;
  }

  @override
  void setFocusedNode(Node node) {}

  void init(Graph? graph) {
    this.graph = copyGraph(graph!);
    reset();
    initSugiyamaData();
    cycleRemoval();
    layerAssignment();
    nodeOrdering(); //expensive operation
    coordinateAssignment(); //expensive operation
    // shiftCoordinates(shiftX, shiftY);
    final graphSize = calculateGraphSize(this.graph);
    denormalize();
    restoreCycle();
    // shiftCoordinates(graph, shiftX, shiftY);
  }

  void step(Graph? graph) {
    reset();
    initSugiyamaData();
    cycleRemoval();
    layerAssignment();
    nodeOrdering(); //expensive operation
    coordinateAssignment(); //expensive operation
    // shiftCoordinates(shiftX, shiftY);
    final graphSize = calculateGraphSize(this.graph);
    denormalize();
    restoreCycle();
  }

  void setDimensions(double width, double height) {
    // graphWidth = width;
    // graphHeight = height;
  }
}
