part of graphview;

class EiglspergerAlgorithm extends Algorithm {
  Map<Node, EiglspergerNodeData> nodeData = {};
  Map<Edge, EiglspergerEdgeData> edgeData = {};
  Set<Node> stack = {};
  Set<Node> visited = {};
  List<List<Node>> layers = [];
  final type1Conflicts = <List<bool>>[];
  late Graph graph;
  SugiyamaConfiguration configuration;

  // /** The delegate Graph to layout */
  // Graph<Node, LE<V, E>> svGraph;
  //
  // NeighborCache<Node, LE<V, E>> neighborCache;
  //
  // /** the result of layering the graph nodes and introducint dummy nodes and edges */
  // /** when sweeping top to bottom, this is a PVertex, bottom to top, this is a QVertex */
  // Predicate<Node> joinVertexPredicate;
  // /** when sweeping top to bottom, this is a QVertex, bottom to top this is a PVertex */
  // Predicate<Node> splitVertexPredicate;
  //
  // Function<List<LE<V, E>>, List<LE<V, E>>> edgeEndpointSwapOrNot;

  // /**
  //  * When sweeping top to bottom, this function returns predecessors When sweeping bottom to top,
  //  * this function returns sucessors
  //  */
  // Function<Node, Set<Node>> neighborFunction;
  //
  // Function<LE<V, E>, Node> edgeSourceFunction;
  // Function<LE<V, E>, Node> edgeTargetFunction;
  // bool transpose;
  // Graph<Node, Integer> compactionGraph;
  // Set<LE<V, E>> typeOneConflicts = new HashSet<>();

  @override
  EdgeRenderer? renderer;

  var nodeCount = 1;

  EiglspergerAlgorithm(this.configuration) {
    renderer = SugiyamaEdgeRenderer(nodeData, edgeData);
  }

  /// @param svGraph the delegate graph
  /// @param layersArray layered nodes
  /// @param joinVertexPredicate nodes to join with Containers
  /// @param splitVertexPredicate nodes to split from Containers
  /// @param neighborFunction predecessors or successors in the Graph
  // EiglspergerSteps(
  // Graph<Node, LE<V, E>> svGraph,
  //     Node[][] layersArray,
  // Predicate<Node> joinVertexPredicate,
  //     Predicate<Node> splitVertexPredicate,
  // Function<LE<V, E>, Node> edgeSourceFunction,
  //     Function<LE<V, E>, Node> edgeTargetFunction,
  // Function<Node, Set<Node>> neighborFunction,
  //     Function<List<LE<V, E>>, List<LE<V, E>>> edgeEndpointSwapOrNot,
  // boolean transpose) {
  // this.svGraph = svGraph;
  // this.neighborCache = new NeighborCache<>(svGraph);
  // this.layersArray = layersArray;
  // this.joinVertexPredicate = joinVertexPredicate;
  // this.splitVertexPredicate = splitVertexPredicate;
  // this.edgeSourceFunction = edgeSourceFunction;
  // this.edgeTargetFunction = edgeTargetFunction;
  // this.neighborFunction = neighborFunction;
  // this.edgeEndpointSwapOrNot = edgeEndpointSwapOrNot;
  // this.transpose = transpose;
  // }

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
    initData();
    cycleRemoval();

    final stopwatch = Stopwatch()
      ..start();
    //These 3 are changed for Eiglsperger
    layerAssignment();
    print('layerAssignment()  ${stopwatch.elapsed.inMilliseconds}');
    final stopwatch1 = Stopwatch()
      ..start();

    nodeOrdering(); //expensive operation

    print('nodeOrdering()  ${stopwatch1.elapsed.inMilliseconds}');
    final stopwatch2 = Stopwatch()
      ..start();
    coordinateAssignment(); //expensive operation
    print('coordinateAssignment() ${stopwatch2.elapsed.inMilliseconds}');

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

  void initData() {
    graph.nodes.forEach((node) {
      node.position = Offset(0, 0);
      nodeData[node] = EiglspergerNodeData();
    });

    graph.edges.forEach((edge) {
      edgeData[edge] = EiglspergerEdgeData();
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
        if (nodeData[node]?.isPNode ?? false) {
          continue;
        }
        //Find edges whose whose source and destination is more than 1 layer
        final edges = graph.edges
            .where((element) =>
        element.source == node && ((nodeData[element.destination]!.layer - nodeData[node!]!.layer).abs() > 1))
            .toList();

        final iterator = edges.iterator;

        // for edges that 'jump' a row, create a new node at the previous row's layer
        // and add edges that route the original edge thru the new dummy node
        while (iterator.moveNext()) {
          final edge = iterator.current;

          // if the edge has a source and target rank that are only 2 levels apart,
          // make just one dummyNode between them.
          if ((nodeData[edge.destination]!.layer - nodeData[edge.source]!.layer).abs() == 2) {
            final dummy = Node.Id(dummyId.hashCode);
            final dummyNodeData = EiglspergerNodeData();
            dummyNodeData.isDummy = true;
            dummyNodeData.layer = indexNextLayer;
            nextLayer.add(dummy);
            nodeData[dummy] = dummyNodeData;
            dummy.size = Size(edge.source.width, 0); // calc TODO avg layer height;

            //replace one edge with 2 dummy edges
            // create 2 virtual edges spanning from source -> dummy node -> target
            final dummyEdge1 = graph.addEdge(edge.source, dummy);
            final dummyEdge2 = graph.addEdge(dummy, edge.destination);
            // add the 2 new edges and the new dummy node, remove the original edge
            edgeData[dummyEdge1] = EiglspergerEdgeData();
            edgeData[dummyEdge2] = EiglspergerEdgeData();
          } else {
            // Otherwise, make a segment
            final pDummy = Node.Id(dummyId.hashCode);
            pDummy.size = Size(edge.source.width, 0); // calc TODO avg layer height;
            final qDummy = Node.Id(dummyId.hashCode);
            qDummy.size = Size(edge.source.width, 0); // calc TODO avg layer height;

            var pNodeLayer = nodeData[edge.source]!.layer + 1;

            final pDummyNodeData = EiglspergerNodeData()
              ..isDummy = true
              ..isPNode = true
              ..layer = pNodeLayer;
            nodeData[pDummy] = pDummyNodeData;
            layers[pNodeLayer].add(pDummy);

            var qNodeLayer = nodeData[edge.destination]!.layer - 1;
            final qDummyNodeData = EiglspergerNodeData()
              ..isDummy = true
              ..layer = qNodeLayer;
            nodeData[qDummy] = qDummyNodeData;
            layers[qNodeLayer].add(qDummy);

            //Add SEgment TODO
            // add the 3 new edges and the 2 new dummy nodes, remove the original edge
            final dummyEdge1 = graph.addEdge(edge.source, pDummy);
            final dummyEdge2 = graph.addEdge(pDummy, qDummy); // THIS IS SEGMENT BASICALLY
            final dummyEdge3 = graph.addEdge(qDummy, edge.destination);
            edgeData[dummyEdge1] = EiglspergerEdgeData();
            edgeData[dummyEdge2] = EiglspergerEdgeData();
            edgeData[dummyEdge3] = EiglspergerEdgeData();
          }
          graph.removeEdge(edge);
        }
      }
    }

    // add dummy's;
//     for (var i = 0; i < layers.length - 1; i++) {
//       var indexNextLayer = i + 1;
//       var currentLayer = layers[i];
//       var nextLayer = layers[indexNextLayer];
//
//       for (var node in currentLayer) {
//         //Find edges whose whose source and destination is more than 1 layer
//         final edges = graph.edges
//             .where((element) =>
//                 element.source == node && ((nodeData[element.destination]!.layer - nodeData[node!]!.layer).abs() > 1))
//             .toList();
//
//         final iterator = edges.iterator;
//
//         // for edges that 'jump' a row, create a new node at the previous row's layer
//         // and add edges that route the original edge thru the new dummy node
//         while (iterator.moveNext()) {
//           final edge = iterator.current;
//           final dummy = Node.Id(dummyId.hashCode);
//           final dummyNodeData = SugiyamaNodeData();
//           dummyNodeData.isDummy = true;
//           dummyNodeData.layer = indexNextLayer;
//           nextLayer.add(dummy);
//           nodeData[dummy] = dummyNodeData;
//           dummy.size = Size(edge.source.width, 0); // calc TODO avg layer height;
//
//           //replace one edge with 2 dummy edges
//           // create 2 virtual edges spanning from source -> syntheticvertex -> target
//           final dummyEdge1 = graph.addEdge(edge.source, dummy);
//           final dummyEdge2 = graph.addEdge(dummy, edge.destination);
//           // add the 2 new edges and the new dummy node, remove the original edge
//           edgeData[dummyEdge1] = SugiyamaEdgeData();
//           edgeData[dummyEdge2] = SugiyamaEdgeData();
//           graph.removeEdge(edge);
// //                    iterator.remove();
//         }
//       }
//   }
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
    for (var i = 0; i < configuration.iterations; i++) {
      median(best, i);
      var changed = transpose(best);
      if (!changed) {
        break;
      }
    }
    var pos = 0;
    for (var currentLayer in layers) {
      pos = 0;
      for (var node in currentLayer) {
        nodeData[node]!.position = pos;
        pos++;
      }
    }
  }

  List<Node> scan(List<Node?> list) {
    var outList = <Node>[];
    for (var i = 0; i < list.length; i++) {
      var v = list[i]!;
      if (outList.isEmpty) {
        if (v is ContainerNode) {
          outList.add(v);
        } else {
          // outList.add(Container());
          outList.add(v);
        }
      } else {
        var previous = outList[outList.length - 1];
        if (previous is ContainerNode && v is ContainerNode) {
          // join them
          var previousContainer = previous;
          var thisContainer = v;
          // previousContainer.join(thisContainer);
          // previous container is already in the outList
        } else if (!(previous is ContainerNode) && !(v is ContainerNode)) {
          // ad empty container between 2 non containers
          // outList.add(Container());
          outList.add(v);
        } else {
          outList.add(v);
        }
      }
    }
    if (outList.isNotEmpty && !(outList[outList.length - 1] is ContainerNode)) {
      // outList.add(Container());
    }
    return outList;
  }

  void median(List<List<Node?>> layers, int currentIteration) {
    if (currentIteration % 2 == 0) {
      // stepsForward
      //  createListOfVertices : Creates and returns a list of the vertices in a rank of the sparse layering array.<br>
      //    * No Containers are inserted in the list, they will be inserted as needed in stepSix of the
      //    * algorithm Arrays.stream(rank).collect(Collectors.toList());
      //   }
      // scan Iterate over the supplied list, creating an alternating list of vertices and Containers

      List<Node>? layerEye;
      var compactionGraph = Graph();

      for (var i = 1; i < layers.length; i++) {
        if (layerEye == null) {
          layerEye = scan(layers[i]); // first rank
          Node? pred;
          for (var v in layerEye) {
            // if (v is Container) {
            //   var container = v as Container;
            //   for (Segment segment in container.segments()) {
            //     compactionGraph.addNode(segment);
            //     if (pred != null) {
            //       compactionGraph.addEdge(pred, segment);
            //     }
            //     pred = segment;
            //   }
            // } else if (v is SegmentVertex) {
            //   compactionGraph.addNode(v);
            //   if (pred != null) {
            //     compactionGraph.addEdge(pred, v);
            //   }
            //   pred = v;
            // } else {
            //   compactionGraph.addNode(v);
            //   if (pred != null) {
            //     compactionGraph.addEdge(pred, v);
            //   }
            //   pred = v;
            // }
          }
        }
        var currentLayer = layers[i];

        //step one
        // step two
        //step three
        // step four
        // step five

        stepOne(layerEye);
        // handled PVertices by merging them into containers
        // if (log.isTraceEnabled()) {
        //   log.trace("stepOneOut:{}", layerEye);
        // }
        //
        // var currentLayer = layerEye;
        // List<Node> downstreamLayer = EiglspergerUtil.createListOfVertices(layersArray[i + 1]);
        // stepTwo(currentLayer, downstreamLayer);
        // if (log.isTraceEnabled()) {
        //   log.trace("stepTwoOut:{}", downstreamLayer);
        // }
        //
        // stepThree(downstreamLayer);
        // if (log.isTraceEnabled()) {
        //   log.trace("stepThreeOut:{}", downstreamLayer);
        // }
        // EiglspergerUtil.fixIndices(downstreamLayer);
        //
        // stepFour(downstreamLayer, i + 1);
        // if (log.isTraceEnabled()) {
        //   log.trace("stepFourOut:{}", downstreamLayer);
        // }
        //
        // if (transpose) {
        //   crossCount += stepFive(currentLayer, downstreamLayer, i, i + 1);
        // }
        // stepSix(downstreamLayer);
        // Node pred = null;
        // for (var v in downstreamLayer) {
        //   if (v is Container) {
        //     Container<V> container = (Container<V>) v;
        //     List<Segment<V>> segments = container.segments();
        //     for (Segment<V> segment : segments) {
        //       compactionGraph.addVertex(segment);
        //       if (pred != null) {
        //         compactionGraph.addEdge(pred, segment);
        //       }
        //       pred = segment;
        //     }
        //   } else if (v is SegmentVertex) {
        //     SegmentVertex<V> segmentVertex = (SegmentVertex<V>) v;
        //     Segment<V> segment = segmentVertex.getSegment();
        //     compactionGraph.addVertex(segment);
        //     if (pred != null) {
        //       compactionGraph.addEdge(pred, segment);
        //     }
        //     pred = segment;
        //   } else {
        //     compactionGraph.addVertex(v);
        //     if (pred != null) {
        //       compactionGraph.addEdge(pred, v);
        //     }
        //     pred = v;
        //   }
        // }
        // if (log.isTraceEnabled()) {
        //   log.trace("stepSixOut:{}", downstreamLayer);
        // }
        //
        // Arrays.sort(layersArray[i], Comparator.comparingInt(LV::getIndex));
        // EiglspergerUtil.fixIndices(layersArray[i]);
        // Arrays.sort(layersArray[i + 1], Comparator.comparingInt(LV::getIndex));
        // EiglspergerUtil.fixIndices(layersArray[i + 1]);
        // layerEye = downstreamLayer;
      }


      // compact
      // check sweep count


      for (var i = 1; i < layers.length; i++) {
        var currentLayer = layers[i];
        var previousLayer = layers[i - 1];
        // get the positions of adjacent vertices in adj_rank
        final positions = graph.edges
            .where((element) => previousLayer.contains(element.source))
            .map((e) => previousLayer.indexOf(e.source))
            .toList();
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

        final positions = graph.edges
            .where((element) => previousLayer.contains(element.source))
            .map((e) => previousLayer.indexOf(e.source))
            .toList();
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

  bool transpose(List<List<Node?>> layers) {
    var changed = false;
    var improved = true;
    while (improved) {
      improved = false;
      for (var l = 0; l < layers.length - 1; l++) {
        final northernNodes = layers[l];
        final southernNodes = layers[l + 1];

        for (var i = 0; i < southernNodes.length - 1; i++) {
          final v = southernNodes[i];
          final w = southernNodes[i + 1];
          if (crossingCount(northernNodes, v, w) > crossingCount(northernNodes, w, v)) {
            improved = true;
            exchange(southernNodes, v, w);
            changed = true;
          }
        }
      }
    }
    return changed;
  }

  void exchange(List<Node?> nodes, Node? v, Node? w) {
    var i = nodes.indexOf(v);
    var j = nodes.indexOf(w);
    var temp = nodes[i];
    nodes[i] = nodes[j];
    nodes[j] = temp;
  }

  // counts the number of edge crossings if n2 appears to the left of n1 in their layer.;
  int crossingCount(List<Node?> northernNodes, Node? n1, Node? n2) {
    // Create a map that holds the index of every [Node]. Key is the [Node] and value is the index of the item.
    final indexMap = HashMap.of(northernNodes.asMap().map((key, value) => MapEntry(value, key)));
    final indexOf = (Node node) => indexMap[node]!;

    var crossing = 0;
    final Iterable<Node> parentNodesN1 = graph.predecessorsOf(n1);
    final Iterable<Node> parentNodesN2 = graph.predecessorsOf(n2);
    parentNodesN2.forEach((pn2) {
      final indexOfPn2 = indexOf(pn2);
      parentNodesN1.where((it) => indexOfPn2 < indexOf(it)).forEach((element) => crossing++);
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
        crossinga += crossingCount(northernNodes, v, w);
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

    // Precalculate predecessor and successor info that we require during the following processes.
    assignNeighboursInfo();

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
        horizontalCompactation(
            align[k],
            root[k],
            sink[k],
            shift[k],
            blockWidth[k],
            x[k],
            isLeftToRight,
            isDownward);
      }
    }

    balance(x, blockWidth);
  }

  void balance(List<Map<Node, double>> x, List<Map<Node?, double>> blockWidth) {
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
        if (value < minValue!) {
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
      var average = (values[1] + values[2]) * 0.5;
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

  void verticalAlignment(Map<Node?, Node?> root, Map<Node?, Node?> align, List<List<bool>> type1Conflicts,
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
      }
    }
  }

  void horizontalCompactation(Map<Node?, Node?> align, Map<Node?, Node?> root, Map<Node?, Node?> sink,
      Map<Node?, double> shift, Map<Node?, double> blockWidth, Map<Node?, double?> x, bool leftToRight, bool downward) {
    // calculate class relative coordinates for all roots;
    // If the layers are traversed from right to left, a reverse iterator is needed (note that this does not change the original list of layers)
    var layersa = leftToRight ? layers : layers.reversed;

    for (var layer in layersa) {
      // As with layers, we need a reversed iterator for blocks for different directions
      var nodes = downward ? layer : layer.reversed;
      // Do an initial placement for all blocks
      for (var v in nodes) {
        if (root[v] == v) {
          placeBlock(
              v,
              sink,
              shift,
              x,
              align,
              blockWidth,
              root,
              leftToRight);
        }
      }
    }

    var d = 0;
    for (var layer in layersa) {
      var nodes = downward ? layer : layer.reversed;
      for (var v in nodes) {
        if (v == sink[root[v]]) {
          final oldShift = shift[v]!;
          if (oldShift < double.infinity) {
            shift[v] = oldShift + d;
            d += oldShift.toInt();
          } else {
            shift[v] = 0;
          }
        }
      }
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

  void placeBlock(Node? v, Map<Node?, Node?> sink, Map<Node?, double> shift, Map<Node?, double?> x,
      Map<Node?, Node?> align, Map<Node?, double> blockWidth, Map<Node?, Node?> root, bool leftToRight) {
    if (x[v] == double.negativeInfinity) {
      var nodeSeparation = configuration.nodeSeparation;
      x[v] = 0;
      var currentNode = v;

      try {
        do {
          // if not first node on layer;
          if (leftToRight && positionOfNode(currentNode) > 0 ||
              !leftToRight && positionOfNode(currentNode) < layers[getLayerIndex(currentNode)].length - 1) {
            final pred = predecessor(currentNode, leftToRight);
            /* Get the root of u (proceeding all the way upwards in the block) */
            final u = root[pred];
            /* Place the block of u recursively */
            placeBlock(
                u,
                sink,
                shift,
                x,
                align,
                blockWidth,
                root,
                leftToRight);
            /* If v is its own sink yet, set its sink to the sink of u */
            if (sink[v] == v) {
              sink[v] = sink[u];
            }
            /* If v and u have different sinks (i.e. they are in different classes),
             * shift the sink of u so that the two blocks are separated by the
             * preferred gap
             */
            if (sink[v] != sink[u]) {
              if (leftToRight) {
                shift[sink[u]] = min(shift[sink[u]]!,
                    x[v]! - x[u]! - nodeSeparation - 0.5 * (blockWidth[u]! + blockWidth[v]!));
              } else {
                shift[sink[u]] = max(shift[sink[u]]!,
                    x[v]! - x[u]! + nodeSeparation + 0.5 * (blockWidth[u]! + blockWidth[v]!));
              }
            } else {
              /* v and u have the same sink, i.e. they are in the same class. Make sure
                 * that v is separated from u by at least gap.
                 */
              if (leftToRight) {
                x[v] = max(x[v]!, x[u]! + nodeSeparation + 0.5 * (blockWidth[u]! + blockWidth[v]!));
              } else {
                x[v] = min(x[v]!, x[u]! - nodeSeparation - 0.5 * (blockWidth[u]! + blockWidth[v]!));
              }
            }
          }
          currentNode = align[currentNode];
        } while (currentNode != v);
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

  void assignNeighboursInfo() {
    graph.edges.forEach((element) {
      nodeData[element.source]?.successorNodes.add(element.destination);
      nodeData[element.destination]?.predecessorNodes.add(element.source);
    });

    graph.nodes.asMap().forEach((i, value) {
      type1Conflicts.add([]);
      graph.edges.forEach((element) {
        type1Conflicts[i].add(false);
      });
    });
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
    for (var i = 0; i < k; i++) {
      var level = layers[i];
      var maxHeight = 0;
      level.forEach((node) {
        var h = nodeData[node]!.isDummy
            ? 0
            : isVertical()
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
          final sugiyamaEdgeData = EiglspergerEdgeData();
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

          final edgeData = EiglspergerEdgeData();
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
    initData();
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

  @override
  void step(Graph? graph) {
    reset();
    initData();
    cycleRemoval();
    layerAssignment();
    nodeOrdering(); //expensive operation
    coordinateAssignment(); //expensive operation
    // shiftCoordinates(shiftX, shiftY);
    final graphSize = calculateGraphSize(this.graph);
    denormalize();
    restoreCycle();
  }

  @override
  void setDimensions(double width, double height) {
    // graphWidth = width;
    // graphHeight = height;
  }

  /// "In the first step we append the segment s(v) for each p-node v in layer L i to the container
  /// preceding v. Then we join this container with the succeeding container. The result is again an
  /// alternating layer (p-nodes are omitted). for any PVertex (QVertex) that is in the list, take
  /// that node's segment and append it to the any prior Container in the list (creating the
  /// Container as needed), and do not append the PVertex (QVertex) in the list to be returned.
  /// Finally, scan the list to join any sequential Containers into one and to insert empty
  /// Containers between sequential nodes.
  ///
  /// @param currentLayer the rank of nodes to operate over
  /// @return layerI modified so that PVertices are gone (added to previous containers)
  void stepOne(List<Node> currentLayer) {
    if (kReleaseMode) log("stepOne currentLayer in", currentLayer);

    var outList = <Node>[];

    for (var v in currentLayer) {
      // for each PVertex/QVertex, add it to the list's adjacent container
      // if v is pVertex (for forward, but q node for backward)
      if (nodeData[v]!.isPNode) {
        // if (outList.isEmpty) {
        //   outList.add(Container());
        // }
        // var lastContainer =  outList[outList.length - 1] as Container;
        // SegmentVertex segmentVertex = v;
        // Segment segment = segmentVertex.getSegment();
        // lastContainer.append(segment);
      } else {
        outList.add(v);
      }
    }
    var scannedList = scan(outList);
    currentLayer.clear();
    currentLayer.addAll(scannedList);

    if (kReleaseMode)
    log("stepOne currentLayer out (merged pnodes into containers)",currentLayer);
  }

  void log(String s, dynamic a) {
    print(s);
  }


/**
 * "In the second step we compute the measure values for the elements in L i+1 . First we assign a
 * position value pos(v i j ) to all nodes v i j in L i . pos(v i 0 ) = size(S i 0 ) and pos(v
 * i j ) = pos(v i j−1 ) + size(S i j ) + 1. Note that the pos values are the same as they would
 * be in the median or barycenter heuristic if each segment was represented as dummy node. Each
 * non- empty container S i j has pos value pos(v i j −1 ) + 1. If container S i 0 is non- empty
 * it has pos value 0. Now we assign the measure to all non-q-nodes and containers in L i+1 .
 * The initial containers in L i+1 are the resulting containers of the first step. Recall that the
 * measure of a container in L i+1 is its position in L i ." Assign positions to the
 * currentLayerVertices and use those posisions to calculate the measure for nodes in the
 * downstreamLayer. The measure here is the median of the positions of neghbor nodes
 *
 * @param currentLayer
 * @param downstreamLayer
 */
void stepTwo(List<Node> currentLayer, List<Node> downstreamLayer) {
  if (kReleaseMode) log("stepTwo currentLayer in", currentLayer);
  if (kReleaseMode) log("stepTwo downstreamLayer in", downstreamLayer);

  // assignPositions(currentLayer);
  //
  // if (updatePositions(currentLayer)) {
  //   log.error("positions were off for {}", currentLayer);
  // }
  //
  // List<Container<V>> containersFromCurrentLayer =
  // currentLayer
  //     .stream()
  //     .filter(v -> v is Container)
  //     .map(v -> (Container<V>) v)
  //     .filter(c -> c.size() > 0)
  //     .collect(Collectors.toList());
  //
  // // add to downstreamLayer, any currentLayer containers that are not already present
  // containersFromCurrentLayer
  //     .stream()
  //     .filter(c -> !downstreamLayer.contains(c))
  //     .forEach(downstreamLayer::add);
  //
  // assignMeasures(downstreamLayer);
  // if (kReleaseMode)
  // log("stepTwo currentLayer out (computed pos for currentLayer)", currentLayer);
  // if (kReleaseMode)
  // log("stepTwo downstreamLayer out (computed measures for downstreamLayer)", downstreamLayer);
}


/**
 * "In the third step we calculate an initial ordering of L i+1 . We sort all non-q-nodes in L
 * i+1 according to their measure in a list L V . We do the same for the containers and store them
 * in a list L S . We use the following operations on these sorted lists:"
 *
 * <ul>
 *   <li>◦ l = pop(L) : Removes the first element l from list L and returns it.
 *   <li>◦ push(L, l) : Inserts element l at the head of list L.
 * </ul>
 *
 * We merge both lists in the following way: <code>
 * if m(head(L V )) ≤ pos(head(L S ))
 *    then v = pop(L V ), append(L i+1 , v)
 * if m(head(L V )) ≥ (pos(head(L S )) + size(head(L S )) − 1)
 *    then S = pop(L S ), append(L i+1 , S)
 * else S = pop(L S ), v = pop(L V ), k = ⌈m(v) − pos(S)⌉,
 *    (S 1 ,S 2 ) = split(S, k), append(L i+1 ,S 1 ), append(L i+1 , v),
 *    pos(S 2 ) = pos(S) + k, push(L S ,S 2 ).
 * </code>
 *
 * @param downstreamLayer
 */
// void stepThree(List<Node> downstreamLayer) {
//
//   if (kReleaseMode) log("stepThree downstreamLayer in", downstreamLayer);
//
//   List<Node> listV = new LinkedList<>();
//   List<Container<V>> listS = new LinkedList<>();
//
//   List<SegmentVertex<V>> segmentVertexList = [];
//   for (Node v : downstreamLayer) {
//     if (splitVertexPredicate.test(v)) { // skip any QVertex for top to bottom
//       segmentVertexList.add((SegmentVertex<V>) v);
//     } else if (v is Container) {
//       Container<V> container = (Container<V>) v;
//       if (container.size() > 0) {
//         listS.add(container);
//       }
//     } else {
//       listV.add(v);
//     }
//   }
//   // sort the list by elements measures
//   if (kReleaseMode) {
//     log.trace("listS measures: {}", listS);
//   }
//   if (kReleaseMode) {
//     log.trace("listV measures: {}", listV);
//   }
//   try {
//     listS.sort(Comparator.comparingDouble(Container::getMeasure));
//     listV.sort(Comparator.comparingDouble(LV::getMeasure));
//
//     if (kReleaseMode) {
//       StringBuilder sbuilder = new StringBuilder("S3 listS:\n");
//       listS.forEach(s -> sbuilder.append(s.toString()).append("\n"));
//   log.trace(sbuilder.toString());
//   StringBuilder vbuilder = new StringBuilder("S3 listV:\n");
//   listV.forEach(v -> vbuilder.append(v.toString()).append("\n"));
//   log.trace(vbuilder.toString());
//   }
//   } catch (Exception ex) {
//   log.error("listS: {}, listV: {} exception: {}", listS, listV, ex);
//   }
//   /*
//   if the measure of the head of the node list LV is <= position of the head of the container list LS,
//   then pop the node from the node list and append it to the Li+1 list
//
//   if the measure of the head of the node list is >= (position of the head of the container list + size of the head of the container list - 1)
//   then pop the head of the container list and append it to the Li+1 list
//
//   else
//      pop S the first container and v the first node from their lists
//      k = ceiling(measure(v)-pos(S))
//      split S at k into S1, S2
//      append S1 to the Li+1 list, append v to the L+1 list,
//      set pos(S2) to be pos(S) + k,
//      push S2 onto container list LS
//    */
//   List<Node> mergedList = [];
//   if (listS.isEmpty() || listV.isEmpty()) {
//   mergedList.addAll(listS);
//   mergedList.addAll(listV);
//   mergedList.sort(Comparator.comparingDouble(LV::getMeasure));
//   } else {
//   while (!listV.isEmpty() && !listS.isEmpty()) {
//   if (listV.get(0).getMeasure() <= listS.get(0).getPos()) {
//   Node v = listV.remove(0);
//   mergedList.add(v);
//   } else if (listV.get(0).getMeasure() >= (listS.get(0).getPos() + listS.get(0).size() - 1)) {
//   Container<V> container = listS.remove(0);
//   mergedList.add(container);
//   } else {
//   Container<V> container = listS.remove(0);
//   Node v = listV.remove(0);
//   int k = (int) Math.ceil(v.getMeasure() - container.getPos());
//   if (kReleaseMode) log.trace("will split {} at {}", container, k);
//   Pair<Container<V>> containerPair = Container.split(container, k);
//   if (kReleaseMode)
//   log.trace("got {} and {}", containerPair.first, containerPair.second);
//   mergedList.add(containerPair.first);
//   mergedList.add(v);
//   int pos = container.getPos() + k;
//   containerPair.second.setPos(pos);
//   listS.add(0, containerPair.second);
//   }
//   }
//   // add any leftovers to listPlusOne
//   mergedList.addAll(listV);
//   mergedList.addAll(listS);
//   }
//   mergedList.addAll(segmentVertexList);
//   if (kReleaseMode) {
//   StringBuilder builder = new StringBuilder("S3 mergedList:\n");
//   mergedList.forEach(v -> builder.append(v.toString()).append("\n"));
//   log.trace(builder.toString());
//   }
//
//   downstreamLayer.clear();
//   downstreamLayer.addAll(mergedList);
//
//   // fix the indices
//   updateIndices(downstreamLayer);
//
//   if (updatePositions(downstreamLayer)) {
//   log.trace("positions were updated for {}", downstreamLayer);
//   }
//   if (kReleaseMode)
//   log("stepThree downstreamLayer out (initial ordering for downstreamLayer)", downstreamLayer);
// }
//
/**
 * In the fourth step we place each q-node v of L i+1 according to the position of its
 * corresponding segment s(v). We do this by calling split(S, s(v)) for each q-node v in layer L
 * i+1 and placing v between the resulting containers (S denotes the container that includes
 * s(v)).
 *
 * @param downstreamLayer
 * @param downstreamRank
 */
// void stepFour(List<Node> downstreamLayer, int downstreamRank) {
//   if (kReleaseMode) log("stepFour downstreamLayer in", downstreamLayer);
//
//   // for each qVertex, get its Segment, find the segment in one of the containers in downstreamLayer
//
//   // gather the qVertices
//   List<SegmentVertex<V>> qVertices =
//   downstreamLayer
//       .stream()
//       .filter(v -> splitVertexPredicate.test(v)) // QVertices
//       .map(v -> (SegmentVertex<V>) v)
//       .collect(Collectors.toList());
//
//   for (SegmentVertex<V> q : qVertices) {
//   List<Container<V>> containerList =
//   downstreamLayer
//       .stream()
//       .filter(v -> v is Container)
//       .map(v -> (Container<V>) v)
//       .collect(Collectors.toList());
//   // find its container
//   Segment<V> segment = q.getSegment();
//   Optional<Container<V>> containerOpt =
//   containerList.stream().filter(c -> c.contains(segment)).findFirst();
//   if (containerOpt.isPresent()) {
//   Container<V> container = containerOpt.get();
//   int loserIdx = downstreamLayer.indexOf(container);
//   if (kReleaseMode) {
//   log.trace(
//   "found container {} at index {} with list index {} for qVertex {} with index {} and list index {}",
//   container,
//   container.getIndex(),
//   loserIdx,
//   q,
//   q.getIndex(),
//   downstreamLayer.indexOf(q));
//   log.trace("splitting on {} because of {}", segment, q);
//   }
//
//   Pair<Container<V>> containerPair = Container.split(container, segment);
//
//   if (kReleaseMode) {
//   log.trace(
//   "splitFound container into {} and {}", containerPair.first, containerPair.second);
//   log.trace(
//   "container pair is now {} and {}",
//   containerPair.first.printTree("\n"),
//   containerPair.second.printTree("\n"));
//   }
//
//   downstreamLayer.remove(q);
//   if (kReleaseMode) {
//   log.trace("removed container {}", container.printTree("\n"));
//   log.trace("adding container {}", containerPair.first.printTree("\n"));
//   log.trace("adding container {}", containerPair.second.printTree("\n"));
//   }
//   downstreamLayer.remove(container);
//   downstreamLayer.add(loserIdx, containerPair.first);
//   downstreamLayer.add(loserIdx + 1, q);
//   downstreamLayer.add(loserIdx + 2, containerPair.second);
//   } else {
//   log.error("container opt was empty for segment {}", segment);
//   }
//   }
//
//   updateIndices(downstreamLayer);
//   updatePositions(downstreamLayer);
//   //    IntStream.range(0, downstreamLayer.size()).forEach(i -> downstreamLayer.get(i).setIndex(i));
//   Arrays.sort(layers[downstreamRank], Comparator.comparingInt(LV::getIndex));
//   if (kReleaseMode)
//   log("stepFour downstreamLayer out (split containers for Q/PVertices)", downstreamLayer);
//   if (kReleaseMode)
//   log("layersArray[" + downstreamRank + "] out", layers[downstreamRank]);
// }
//
/**
 * In the fifth step we perform cross counting according to the scheme pro- posed by Barth et al
 * (see Section 1.2). During the cross counting step between layer L i and L i+1 we therefore
 * consider all layer elements as ver- tices. Beside the common edges between both layers, we also
 * have to handle virtual edges, which are imaginary edges between a container ele- ment in L i
 * and the resulting container elements or q-nodes in L i+1 (see Figure 5). In terms of the
 * common approach each virtual edge represents at least one edge between two dummy nodes. The
 * number of represented edges is equal to the size of the container element in L i+1 . We have to
 * consider this fact to get the right number of edge crossings. We therefore introduce edge
 * weights. The weight of a virtual edge ending with a con- tainer element S is equal to size(S).
 * The weight of the other edges is one. So a crossing between two edges e 1 and e 2 counts as
 * weight(e 1 )·weight(e 2 ) crossings.
 *
 * @param currentLayer the Li layer
 * @param downstreamLayer the Li+1 (or Li-1 for backwards) layer
 * @param currentRank the value of i for Li
 * @param downstreamRank the value of i+1 (or i-1 for backwards)
 * @return count of edge crossing weight
 */
// int stepFive(
//     List<Node> currentLayer, List<Node> downstreamLayer, int currentRank, int downstreamRank) {
//   return transpose(currentLayer, downstreamLayer, currentRank, downstreamRank);
// }
//
//  int transpose(
//     List<Node> currentLayer, List<Node> downstreamLayer, int currentRank, int downstreamRank) {
//
//   // gather all the graph edges between the currentRank and the downstreamRank
//   List<LE<V, E>> biLayerEdges =
//       svGraph
//           .edgeSet()
//           .stream()
//           .filter(
//           e ->
//           edgeSourceFunction.apply(e).getRank() == currentRank
//           && edgeTargetFunction.apply(e).getRank() == downstreamRank)
//       .collect(Collectors.toList());
//
//   // create virtual edges between non-empty containers in both ranks
//   // if the downstreamLayer has a QVertex/PVertex, create a virtual edge between a new dummy node
//   // in currentLayer and the QVertex/PVertex in the downstreamLayer
//   Set<LE<V, E>> virtualEdges = new HashSet<>();
//   for (Node v : downstreamLayer) {
//
//   if (v is Container) {
//   Container<V> container = (Container<V>) v;
//   if (container.size() > 0) {
//   virtualEdges.add(VirtualEdge.of(container, container));
//   }
//   } else if (splitVertexPredicate.test(v)) {
//   // downwards, this is a QVertex, upwards its a PVertex
//   SegmentVertex<V> qv = (SegmentVertex<V>) v;
//   DummyNode qvSource = DummyLV.of();
//   qvSource.setIndex(qv.getIndex());
//   qvSource.setPos(qv.getPos());
//   virtualEdges.add(VirtualEdge.of(qvSource, qv));
//   }
//   }
//
//   for (Iterator<Node> iterator = currentLayer.iterator(); iterator.hasNext(); ) {
//   if (isEmptyContainer(iterator.next())) {
//   iterator.remove();
//   }
//   }
//   updateIndices(currentLayer);
//   updatePositions(currentLayer);
//
//   // remove any empty containers from the downstreamLayer and reset the index metadata
//   // for the currentLayer nodes
//   for (Iterator<Node> iterator = downstreamLayer.iterator(); iterator.hasNext(); ) {
//   if (isEmptyContainer(iterator.next())) {
//   iterator.remove();
//   }
//   }
//   updateIndices(downstreamLayer);
//   updatePositions(downstreamLayer);
//
//   typeOneConflicts.addAll(this.getEdgesThatCrossVirtualEdge(virtualEdges, biLayerEdges));
//   biLayerEdges.addAll(virtualEdges);
//
//   // downwards, the function is a no-op, upwards the biLayerEdges endpoints are swapped
//   if (kReleaseMode) {
//   log.trace("for ranks {} and {} ....", currentRank, downstreamRank);
//   }
//   return processRanks(downstreamLayer, edgeEndpointSwapOrNot.apply(biLayerEdges));
// }
//
//  int processRanks(List<Node> downstreamLayer, List<LE<V, E>> biLayerEdges) {
//   int crossCount = Integer.MAX_VALUE;
//   // define a function that will get the edge weight from its target node
//   // in the downstream layer. If the target is a container, it's weight is
//   // the size of the container
//   Function<Integer, Integer> f =
//       i -> {
//   LE<V, E> edge = biLayerEdges.get(i);
//   Node target = edge.getTarget();
//   if (target is Container) {
//   return ((Container<V>) target).size();
//   }
//   return 1;
//   };
//   if (downstreamLayer.size() < 2) {
//   crossCount = 0;
//   }
//   for (int j = 0; j < downstreamLayer.size() - 1; j++) {
//
//   // if either of the adjacent nodes is a container, skip them
//   if (kReleaseMode) {
//   // runs the crossingCount (no weights) with the insertionSort method and the AccumulatorTree method
//   // these values should match and should both be <= to the crossingWeight
//   int vw2 = crossingCount(biLayerEdges);
//   int vw3 = AccumulatorTreeUtil.crossingCount(biLayerEdges);
//   if (kReleaseMode) {
//   log.trace("IS count:{}, AC count:{}", vw2, vw3);
//   }
//   }
//   int vw = AccumulatorTreeUtil.crossingWeight(biLayerEdges, f);
//   crossCount = Math.min(vw, crossCount);
//   if (kReleaseMode) {
//   log.trace("crossingWeight:{}", vw);
//   }
//   if (vw == 0) {
//   // can't do better than zero
//   break;
//   }
//   if (downstreamLayer.get(j).getMeasure() != downstreamLayer.get(j + 1).getMeasure()) {
//   continue;
//   }
//   // count with j and j+1 swapped
//   // first swap them
//   swap(downstreamLayer, j, j + 1);
//   if (kReleaseMode) {
//   // runs the crossingCount (no weights) with the insertionSort method and the AccumulatorTree method
//   // these values should match and should both be <= to the crossingWeight
//   int wv2 = crossingCount(biLayerEdges);
//   int wv3 = AccumulatorTreeUtil.crossingCount(biLayerEdges);
//   log.trace("IS count:{}, AC count:{}", wv2, wv3);
//   }
//   int wv = AccumulatorTreeUtil.crossingWeight(biLayerEdges, f);
//   crossCount = Math.min(wv, crossCount);
//   if (kReleaseMode) {
//   log.trace("swapped crossingWeight:{}", wv);
//   }
//   // put them back unswapped
//   swap(downstreamLayer, j, j + 1);
//
//   if (vw > wv) {
//   // if the swapped weight is lower, swap them and save off the better
//   swap(downstreamLayer, j, j + 1);
//   if (wv == 0) {
//   break;
//   }
//   }
//   }
//   log.trace("crossCount  {}", crossCount);
//   updatePositions(downstreamLayer);
//
//   return crossCount;
//   }
//
// Set<LE<V, E>> getEdgesThatCrossVirtualEdge(
//     Set<LE<V, E>> virtualEdges, List<LE<V, E>> biLayerEdges) {
//   Set<Integer> virtualEdgeIndices = new HashSet<>();
//   for (LE<V, E> edge : virtualEdges) {
//     virtualEdgeIndices.add(edge.getSource().getIndex());
//     virtualEdgeIndices.add(edge.getTarget().getIndex());
//   }
//   Set<LE<V, E>> typeOneConflictEdges = new HashSet<>();
//   for (LE<V, E> edge : biLayerEdges) {
//     if (edge is VirtualEdge) continue;
//     List<Integer> sortedIndices = [];
//     sortedIndices.add(edge.getSource().getIndex());
//     sortedIndices.add(edge.getTarget().getIndex());
//     Collections.sort(sortedIndices);
//     for (int virtualIndex : virtualEdgeIndices) {
//       int idxZero = sortedIndices.get(0);
//       int idxOne = sortedIndices.get(1);
//       if (idxZero <= virtualIndex && virtualIndex < idxOne) {
//         typeOneConflictEdges.add(edge);
//       }
//     }
//   }
//   return typeOneConflictEdges;
// }
//
//  bool isEmptyContainer(Node v) {
//   return v is Container && ((Container<V>) v).size() == 0;
// }
//
// <V, E> List<LE<V, E>> swapEdgeEndpoints(List<LE<V, E>> list) {
//   return list.stream()
//       .map(e -> LE.of(e.getEdge(), e.getTarget(), e.getSource()))
//       .collect(Collectors.toList());
//   //    return list.stream().map(LE::swapped).collect(Collectors.toList());
// }
//
//  int crossingCount(List<LE<V, E>> edges) {
//   edges.sort(Comparators.biLevelEdgeComparator());
//   List<Integer> targetIndices = [];
//   for (LE<V, E> edge : edges) {
//     targetIndices.add(edge.getTarget().getIndex());
//   }
//   return InsertionSortCounter.insertionSortCounter(targetIndices);
// }
//
//  <V> void swap(Node[] array, int i, int j) {
// Node temp = array[i];
// array[i] = array[j];
// array[j] = temp;
// array[i].setIndex(i);
// array[j].setIndex(j);
// }
//
//  <V> void swap(List<Node> array, int i, int j) {
//   Collections.swap(array, i, j);
//   array.get(i).setIndex(i);
//   array.get(j).setIndex(j);
//   updatePositions(array);
// }

/**
 * In the sixth step we perform a scan on L i+1 and insert empty containers between two
 * consecutive nodes, and call join(S 1 , S 2 ) on two consecutive containers in the list. This
 * ensures that L i+1 is an alternating layer.
 *
 * @param downstreamLayer
 */
// void stepSix(List<Node> downstreamLayer) {
//
//   if (kReleaseMode) log("stepSix downstreamLayer in", downstreamLayer);
//   List<Node> scanned = EiglspergerUtil.scan(downstreamLayer);
//   downstreamLayer.clear();
//   downstreamLayer.addAll(scanned);
//   if (kReleaseMode)
//     log("stepSix downstreamLayer out (padded with and compressed containers)", downstreamLayer);
// }
//
// /**
//  * return the segment to which v is incident, if v is a PVertex or a QVertex. Otherwise, return v
//  *
//  * @param v the node to get a segment for
//  * @param <V> node type
//  * @return the segment for v or else v
//  */
// <V> Node s(Node v) {
// if (v is SegmentVertex) {
// SegmentVertex<V> pVertex = (SegmentVertex<V>) v;
// return pVertex.getSegment();
// } else {
// return v;
// }
// }
//
// /**
//  * update the positions so that the preceding container size is used
//  *
//  * @param layer
//  */
// <V> bool updatePositions(List<Node> layer) {
// bool changed = false;
// int currentPos = 0;
// for (Node v : layer) {
// if (v is Container && ((Container<V>) v).size() == 0) {
// continue;
// }
// if (v.getPos() != currentPos) {
// changed = true;
// }
// v.setPos(currentPos);
// if (v is Container) {
// currentPos += ((Container<V>) v).size();
// } else {
// currentPos++;
// }
// }
// return changed;
// }
//
// void assignPositions(List<Node> currentLayer) {
// Node previousVertex = null;
// Container<V> previousContainer = null;
// for (int i = 0; i < currentLayer.size(); i++) {
// Node v = currentLayer.get(i);
//
// if (i % 2 == 0) {
// // this is a container
// Container<V> container = (Container<V>) v;
// if (container.size() > 0) {
// if (previousContainer == null) {
// // first container non empty
// container.setPos(0);
// } else {
// // there has to be a previousVertex
// int pos = previousVertex.getPos() + 1;
// container.setPos(pos);
// }
// }
// previousContainer = container;
// } else {
// // this is a node
// if (previousVertex == null) {
// // first node (position 1)
// int pos = previousContainer.size();
// v.setPos(pos);
// } else {
// int pos = previousVertex.getPos() + previousContainer.size() + 1;
// v.setPos(pos);
// }
// previousVertex = v;
// }
// }
// }
//
// void assignMeasures(List<Node> downstreamLayer) {
// downstreamLayer
//     .stream()
//     .filter(v -> v is Container)
//     .map(v -> (Container<V>) v)
//     .filter(c -> c.size() > 0)
//     .forEach(
// c -> {
// double measure = c.getPos();
// c.setMeasure(measure);
// });
//
// for (Node v : downstreamLayer) {
// if (splitVertexPredicate.test(v)) { // QVertex for top to bottom
// continue;
// }
// if (v is Container) {
// Container<V> container = (Container<V>) v;
// double measure = container.getPos();
// container.setMeasure(measure);
// } else {
// // not a container (nor QVertex for top to bottom)
// // measure will be related to the median of the pos of predecessor vert
// Set<Node> neighbors = neighborFunction.apply(v);
// int[] poses = new int[neighbors.size()];
// int i = 0;
// for (Node neighbor : neighbors) {
// poses[i++] = neighbor.getPos();
// }
// //        IntStream.range(0, poses.length).forEach(idx -> poses[idx] = neighbors.get(idx).getPos());
// if (poses.length > 0) {
// int measure = medianValue(poses); // poses will be sorted in medianValue method
// v.setMeasure(measure);
// } else {
// // leave the measure as as the current pos
// if (v.getPos() < 0) {
// log.debug("no pos for {}", v);
// }
// double measure = v.getPos();
// v.setMeasure(measure);
// }
// }
// }
// }
//
// /**
//  * return the median value in the array P (which is Sorted!)
//  *
//  * @param P a sorted array
//  * @return the median value
//  */
// int medianValue(int[] P) {
// if (P.length == 0) {
// return -1;
// } else if (P.length == 1) {
// return P[0];
// }
// Arrays.sort(P);
// int m = P.length / 2;
// if (P.length % 2 == 1) {
// return P[m];
// } else if (P.length == 2) {
// return (P[0] + P[1]) / 2;
// } else {
// int left = P[m - 1] - P[0];
// int right = P[P.length - 1] - P[m];
// if (left + right == 0) {
// return 0;
// }
// return (P[m - 1] * right + P[m] * left) / (left + right);
// }
// }
}
