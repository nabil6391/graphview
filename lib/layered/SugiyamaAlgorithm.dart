part of graphview;

class SugiyamaAlgorithm extends Algorithm {
  Map<Node, SugiyamaNodeData> nodeData = {};
  Map<Edge, SugiyamaEdgeData> edgeData = {};
  Set<Node> stack = {};
  Set<Node> visited = {};
  List<List<Node>> layers = [];
  final type1Conflicts = <int, int>{};
  late Graph graph;
  SugiyamaConfiguration configuration;

  @override
  EdgeRenderer? renderer;

  var nodeCount = 1;

  SugiyamaAlgorithm(this.configuration) {
    renderer = SugiyamaEdgeRenderer(nodeData, edgeData, configuration.bendPointShape, configuration.addTriangleToEdge);
  }

  int get dummyId => 'Dummy ${nodeCount++}'.hashCode;

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

  @override
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
                element.source == node && (nodeData[element.destination]!.layer - nodeData[node]!.layer).abs() > 1).toList();

        final iterator = edges.iterator;

        while (iterator.moveNext()) {
          final edge = iterator.current;
          final dummy = Node.Id(dummyId.hashCode);
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
    final predecessors = <Node, bool>{};
    graph.edges.forEach((element) {
      predecessors[element.destination] = true;
    });

    var roots = graph.nodes.where((node) => predecessors[node] == null);
    roots.forEach((node) {
      nodeData[node]?.layer = layers.length;
    });

    return roots.toList();
  }

  Graph copyGraph(Graph graph) {
    final copy = Graph();
    copy.addNodes(graph.nodes);
    copy.addEdges(graph.edges);
    return copy;
  }

  void nodeOrdering() {
    final best = <List<Node>>[...layers];

    // Precalculate predecessor and successor info that we require during the following processes.
    graph.edges.forEach((element) {
      nodeData[element.source]?.successorNodes.add(element.destination);
      nodeData[element.destination]?.predecessorNodes.add(element.source);
    });

    for (var i = 0; i < configuration.iterations; i++) {
      median(best, i);
      // transpose(best);
      // if (!changed) {
      //   break;
      // }
      // var c = crossing(best);
      // var l = crossing(layers);
      // if (c < l) {
      // layers = best;
      // }
      var changed = transpose(best);
      if (!changed) {
        break;
      }
    }
    // Set the final position of the nodes in memory
    var pos = 0;
    for (var currentLayer in layers) {
      pos = 0;
      for (var node in currentLayer) {
        nodeData[node]?.position = pos;
        pos++;
      }
    }
  }

  void median(List<List<Node?>> layers, int currentIteration) {
    if (currentIteration % 2 == 0) {
      for (var i = 1; i < layers.length; i++) {
        var currentLayer = layers[i];
        var previousLayer = layers[i - 1];

        // get the positions of adjacent vertices in adj_rank
        var positions = <int>[];
        var pos = 0;
        previousLayer.forEach((node) {
          successorsOf(node).forEach((element) {
            positions.add(pos);
          });
          pos++;
        });
        positions.sort();

        // set the position in terms of median based on adjacent values
        if (positions.isNotEmpty) {
          var median = positions.length ~/ 2;

          if (positions.length == 1) {
            median = -1;
          } else if (positions.length == 2) {
            median = (positions[0] + positions[1]) ~/ 2;
          } else if (positions.length % 2 == 1) {
            median = positions[median];
          } else {
            final left = positions[median - 1] - positions[0];
            final right = positions[positions.length - 1] - positions[median];
            if (left + right != 0) {
              median = (positions[median - 1] * right + positions[median] * left) ~/ (left + right);
            }
          }

          for (var node in currentLayer) {
            nodeData[node!]!.median = median;
          }
        }

        currentLayer.sort((n1, n2) => nodeData[n1!]!.median - nodeData[n2!]!.median);
      }
    } else {
      for (var l = 1; l < layers.length; l++) {
        var currentLayer = layers[l];
        var previousLayer = layers[l - 1];

        var positions = <int>[];
        var pos = 0;
        previousLayer.forEach((node) {
          successorsOf(node).forEach((element) {
            positions.add(pos);
          });
          pos++;
        });
        positions.sort();

        if (positions.isNotEmpty) {
          var median = 0;

          if (positions.length == 1) {
            median = positions[0];
          } else {
            median = (positions[(positions.length / 2.0).ceil()] + positions[(positions.length / 2.0).ceil() - 1]) ~/ 2;
          }

          for (var i = currentLayer.length - 1; i > 1; i--) {
            final node = currentLayer[i];
            nodeData[node!]!.median = median;
          }
        }

        currentLayer.sort((n1, n2) => nodeData[n1!]!.median - nodeData[n2!]!.median);
      }
    }
  }

  bool transpose(List<List<Node>> layers) {
    var changed = false;
    var improved = true;

    while (improved) {
      improved = false;
      for (var l = 0; l < layers.length - 1; l++) {
        final northernNodes = layers[l];
        final southernNodes = layers[l + 1];

        // Create a map that holds the index of every [Node]. Key is the [Node] and value is the index of the item.
        final indexMap = HashMap.of(northernNodes.asMap().map((key, value) => MapEntry(value, key)));

        for (var i = 0; i < southernNodes.length - 1; i++) {
          final v = southernNodes[i];
          final w = southernNodes[i + 1];
          if (crossingCount(indexMap, v, w) > crossingCount(indexMap, w, v)) {
            improved = true;
            exchange(southernNodes, v, w);
            changed = true;
          }
        }
      }
    }
    return changed;
  }

  void exchange(List<Node> nodes, Node v, Node w) {
    var i = nodes.indexOf(v);
    var j = nodes.indexOf(w);
    var temp = nodes[i];
    nodes[i] = nodes[j];
    nodes[j] = temp;
  }

  // counts the number of edge crossings if n2 appears to the left of n1 in their layer.;
  int crossingCount(HashMap<Node, int> northernNodes, Node? n1, Node? n2) {
    final indexOf = (Node node) => northernNodes[node]!;
    var crossing = 0;
    final parentNodesN1 = nodeData[n1]!.predecessorNodes;
    final parentNodesN2 = nodeData[n2]!.predecessorNodes;
    parentNodesN2.forEach((pn2) {
      final indexOfPn2 = indexOf(pn2);
      parentNodesN1.where((it) => indexOfPn2 < indexOf(it)).forEach((element) {
        crossing++;
      });
    });

    return crossing;
  }

  int crossing(List<List<Node>> layers) {
    var crossinga = 0;

    for (var l = 0; l < layers.length - 1; l++) {
      final southernNodes = layers[l];
      final northernNodes = layers[l + 1];

      final indexMap = HashMap.of(northernNodes.asMap().map((key, value) => MapEntry(value, key)));

      for (var i = 0; i < southernNodes.length - 2; i++) {
        final v = southernNodes[i];
        final w = southernNodes[i + 1];

        crossinga += crossingCount(indexMap, v, w);
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
    final blockWidth = <Map<Node, double>>[];

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
    var separation = configuration.nodeSeparation;

    var vertical = isVertical();
    for (var downward = 0; downward <= 1; downward++) {
      var isDownward = downward == 0;
      final type1Conflicts = markType1Conflicts(isDownward);
      for (var leftToRight = 0; leftToRight <= 1; leftToRight++) {
        final k = 2 * downward + leftToRight;
        var isLeftToRight = leftToRight == 0;
        verticalAlignment(root[k], align[k], type1Conflicts, isDownward, isLeftToRight);
        graph.nodes.forEach((v) {
          final r = root[k][v]!;
          blockWidth[k][r] = max(blockWidth[k][r]!, vertical ? v.width + separation : v.height);
        });
          horizontalCompactation(
              align[k],
              root[k],
              sink[k],
              shift[k],
              blockWidth[k],
              x[k],
              isLeftToRight,
              isDownward,
              layers,
              separation);
      }
    }

    balance(x, blockWidth);
  }

  void balance(List<Map<Node, double>> x, List<Map<Node?, double>> blockWidth) {
    final coordinates = <Node, double>{};

    switch (configuration.coordinateAssignment) {
      case CoordinateAssignment.Average:
        var minWidth = double.infinity;

        var smallestWidthLayout = 0;
        final minArray = List.filled(4, 0.0);
        final maxArray = List.filled(4, 0.0);

        // Get the layout with the smallest width and set minimum and maximum value for each direction;
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

        // Align the layouts to the one with the smallest width
        for (var layout = 0; layout < 4; layout++) {
          if (layout != smallestWidthLayout) {
            // Align the left to right layouts to the left border of the smallest layout
            var diff = 0.0;
            if (layout < 2) {
              diff = minArray[layout] - minArray[smallestWidthLayout];
            } else {
              // Align the right to left layouts to the right border of the smallest layout
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

        // Get the average median of each coordinate
        var values = List.filled(4, 0.0);
        graph.nodes.forEach((n) {
          for (var i = 0; i < 4; i++) {
            values[i] = x[i][n]!;
          }
          values.sort();
          var average = (values[1] + values[2]) * 0.5;
          coordinates[n] = average;
        });
        break;
      case CoordinateAssignment.DownRight:
        graph.nodes.forEach((n) {
          coordinates[n] = x[0][n] ?? 0.0;
        });
        break;
      case CoordinateAssignment.DownLeft:
        graph.nodes.forEach((n) {
          coordinates[n] = x[1][n] ?? 0.0;
        });
        break;
      case CoordinateAssignment.UpRight:
        graph.nodes.forEach((n) {
          coordinates[n] = x[2][n] ?? 0.0;
        });
        break;
      case CoordinateAssignment.UpLeft:
        graph.nodes.forEach((n) {
          coordinates[n] = x[3][n] ?? 0.0;
        });
        break;
    }

    // Get the minimum coordinate value
    var minValue = coordinates.values.reduce(min);

    // Set left border to 0
    if (minValue != 0) {
      coordinates.keys.forEach((n) {
        coordinates[n] = coordinates[n]! - minValue;
      });
    }

    resolveOverlaps(coordinates);


    graph.nodes.forEach((v) {
      v.x = coordinates[v]!;
    });
  }

  void resolveOverlaps(Map<Node, double> coordinates) {
     for (var layer in layers) {
      var layerNodes = List<Node>.from(layer);
      layerNodes.sort((a, b) => nodeData[a]!.position.compareTo(nodeData[b]!.position));

      var data = nodeData[layerNodes.first];
      if (data?.layer != 0) {
        var leftCoordinate = 0.0;
        for (var i = 1; i < layerNodes.length; i++) {
          var currentNode = layerNodes[i];
          if(!nodeData[currentNode]!.isDummy) {
            var previousNode = getPreviousNonDummyNode(layerNodes, i);

            if (previousNode != null) {
              leftCoordinate = coordinates[previousNode]! + previousNode.width + configuration.nodeSeparation;
            } else {
              leftCoordinate = 0.0;
            }

            if (leftCoordinate > coordinates[currentNode]!) {
              var adjustment = leftCoordinate - coordinates[currentNode]!;
              if (coordinates[currentNode] != null) {
                coordinates[currentNode] = coordinates[currentNode]! + adjustment;
              }
            }
          }
        }
      }
    }
  }

  Node? getPreviousNonDummyNode(List<Node> layerNodes, int currentIndex) {
    for (var i = currentIndex - 1; i >= 0; i--) {
      var previousNode = layerNodes[i];
      if (!nodeData[previousNode]!.isDummy) {
        return previousNode;
      }
    }
    return null;
  }

  Map<int, int> markType1Conflicts(bool downward) {
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
      for (var i = lower; downward ? i <= upper : i >= upper; i += downward ? 1 : -1) {
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
                  type1Conflicts[l1] = currentNeighbourIndex;
                }
              }
              firstIndex++;
            }

            k0 = k1;
          }
        }
      }
    }
    return type1Conflicts;
  }

  void verticalAlignment(Map<Node?, Node?> root, Map<Node?, Node?> align, Map<int,int> type1Conflicts,
      bool downward, bool leftToRight) {
    // for all Level;

    var layersa = downward ? layers : layers.reversed;

    for (var layer in layersa) {
      // As with layers, we need a reversed iterator for blocks for different directions
      var nodes = leftToRight ? layer : layer.reversed;
      // Do an initial placement for all blocks
      var r = leftToRight ? -1 : double.infinity;
      for (var v in nodes) {
        final adjNodes = getAdjNodes(v, downward);
        if (adjNodes.isNotEmpty) {
          var midLevelValue = adjNodes.length / 2;
          // Calculate medians
          final medians = adjNodes.length % 2 == 1
              ? [adjNodes[midLevelValue.floor()]]
              : [adjNodes[midLevelValue.toInt() - 1], adjNodes[midLevelValue.toInt()]];

          // For all median neighbours in direction of H
          for (var m in medians) {
            final posM = positionOfNode(m);
            // if segment (u,v) not marked by type1 conflicts AND ...;
            if (align[v] == v &&
                type1Conflicts[positionOfNode(v)] != posM &&
                (leftToRight ? r < posM : r > posM)) {
              align[m] = v;
              root[v] = root[m];
              align[v] = root[v];
              r = posM;
            }
          }
        }
      }
    }
  }

  void horizontalCompactation(Map<Node, Node> align, Map<Node, Node> root, Map<Node, Node> sink,
      Map<Node, double> shift, Map<Node, double> blockWidth, Map<Node, double> x, bool leftToRight,
      bool downward, List<List<Node>> layers, int separation) {
    // calculate class relative coordinates for all roots;
    // If the layers are traversed from right to left, a reverse iterator is needed (note that this does not change the original list of layers)
    var layersa = leftToRight ? layers : layers.reversed;

    for (var layer in layersa) {
      // As with layers, we need a reversed iterator for blocks for different directions
      var nodes = downward ? layer : layer.reversed;
      // Do an initial placement for all blocks
      for (var v in nodes) {
        if (root[v] == v) {
          placeBlock(v, sink, shift, x, align, blockWidth, root, leftToRight, layers, separation);
        }
      }
    }

    var d = 0;
    var i = downward ? 0 : layers.length - 1;
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
      x[v] = x[root[v]]!;
      final shiftVal = shift[sink[root[v]]]!;
      if (shiftVal < double.infinity) {
        x[v] = x[v]! + shiftVal; // apply shift for each class;
      }
    });
  }

  void placeBlock(Node v, Map<Node, Node> sink, Map<Node, double> shift, Map<Node, double> x,
      Map<Node, Node> align, Map<Node, double> blockWidth, Map<Node, Node> root, bool leftToRight, List<List<Node>> layers, int separation) {
    if (x[v] == double.negativeInfinity) {
      x[v] = 0;
      var currentNode = v;

      try {
        do {
          // if not first node on layer;
          final hasPredecessor = leftToRight && positionOfNode(currentNode) > 0 ||
              !leftToRight &&
                  positionOfNode(currentNode) < layers[getLayerIndex(currentNode)].length - 1;
          // print("Pred  $hasPredecessor ${getLayerIndex(currentNode)>0} ${positionOfNode(currentNode)>0}");
          if (hasPredecessor) {
            final pred = predecessor(currentNode, leftToRight);
            /* Get the root of u (proceeding all the way upwards in the block) */
            final u = root[pred]!;
            /* Place the block of u recursively */
            placeBlock(u, sink, shift, x, align, blockWidth, root, leftToRight, layers, separation);
            /* If v is its own sink yet, set its sink to the sink of u */
            if (sink[v] == v) {
              sink[v] = sink[u]!;
            }
            /* If v and u have different sinks (i.e. they are in different classes),
             * shift the sink of u so that the two blocks are separated by the preferred gap  */
            var gap = separation + 0.5 * (blockWidth[u]! + blockWidth[v]!);
            if (sink[v] != sink[u]) {
              if (leftToRight) {
                shift[sink[u]!] = min(shift[sink[u]]!, x[v]! - x[u]! - gap);
              } else {
                shift[sink[u]!] = max(shift[sink[u]]!, x[v]! - x[u]! + gap);
              }
            } else {
              /* v and u have the same sink, i.e. they are in the same level.
              Make sure that v is separated from u by at least gap.*/
              if (leftToRight) {
                x[v] = max(x[v]!, x[u]! + gap);
              } else {
                x[v] = min(x[v]!, x[u]! - gap);
              }
            }
          }
          currentNode = align[currentNode]!;
        } while (currentNode != v);
      } catch (e) {
        print(e);
      }
    }
  }

  List<Node> successorsOf(Node? node) {
    return nodeData[node]?.successorNodes ?? [];
  }

  List<Node> predecessorsOf(Node? node) {
    return nodeData[node]?.predecessorNodes ?? [];
  }

  List<Node> getAdjNodes(Node node, bool downward) {
    if (downward) {
      return predecessorsOf(node);
    } else {
      return successorsOf(node);
    }
  }

  // predecessor;
  Node? predecessor(Node? v, bool leftToRight) {
    final pos = positionOfNode(v);
    final rank = getLayerIndex(v);
    final level = layers[rank];
    if (leftToRight && pos != 0 || !leftToRight && pos != level.length - 1) {
      return level[(leftToRight) ? pos - 1 : pos + 1];
    } else {
      return null;
    }
  }

  Node? virtualTwinNode(Node node, bool downward) {
    if (!isLongEdgeDummy(node)) {
      return null;
    }
    final adjNodes = getAdjNodes(node, downward);
    return adjNodes.isEmpty ? null : adjNodes[0];
  }

  // get node index in layer;
  int positionOfNode(Node? node) {
    return nodeData[node]?.position ?? -1;
  }

  int getLayerIndex(Node? node) {
    return nodeData[node]?.layer ?? -1;
  }

  bool isLongEdgeDummy(Node? v) {
    final successors = successorsOf(v);
    return nodeData[v!]!.isDummy && successors.length == 1 && nodeData[successors[0]]!.isDummy;
  }

  void assignY() {
    // compute y-coordinates;
    final k = layers.length;

    // assign y-coordinates
    var yPos = 0.0;
    var vertical = isVertical();
    for (var i = 0; i < k; i++) {
      var level = layers[i];
      var maxHeight = 0;
      level.forEach((node) {
        var h = nodeData[node]!.isDummy
            ? 0
            : vertical
                ? node.height
                : node.width;
        if (h > maxHeight) {
          maxHeight = h.toInt();
        }
        node.y = yPos;
      });

      if (i < k - 1) {
        yPos += configuration.levelSeparation + maxHeight;
      }
    }
  }

  void denormalize() {
    // remove dummy's;
    for (var i = 1; i < layers.length - 1; i++) {
      final iterator = layers[i].iterator;

      while (iterator.moveNext()) {
        final current = iterator.current;
        if (nodeData[current]!.isDummy) {
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
        finalOffset = Offset(0, 0);
        break;
    }

    return finalOffset;
  }

  @override
  void setFocusedNode(Node node) {}

  @override
  void init(Graph? graph) {
    this.graph = copyGraph(graph!);
    reset();
    initSugiyamaData();
    cycleRemoval();
    layerAssignment();
    nodeOrdering(); //expensive operation
    coordinateAssignment(); //expensive operation
    // shiftCoordinates(shiftX, shiftY);
    //final graphSize = calculateGraphSize(this.graph);
    denormalize();
    restoreCycle();
    // shiftCoordinates(graph, shiftX, shiftY);
  }

  @override
  void step(Graph? graph) {
    reset();
    initSugiyamaData();
    cycleRemoval();
    layerAssignment();
    nodeOrdering(); //expensive operation
    coordinateAssignment(); //expensive operation
    // shiftCoordinates(shiftX, shiftY);
    //final graphSize = calculateGraphSize(this.graph);
    denormalize();
    restoreCycle();
  }

  @override
  void setDimensions(double width, double height) {
    // graphWidth = width;
    // graphHeight = height;
  }
}
