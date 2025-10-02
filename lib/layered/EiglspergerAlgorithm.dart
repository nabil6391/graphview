part of graphview;

class ContainerX {
  List<Segment> segments = [];
  int index = -1;
  int pos = -1;
  double measure = -1;

  ContainerX();

  void append(Segment segment) {
    segments.add(segment);
  }

  void join(ContainerX other) {
    segments.addAll(other.segments);
    other.segments.clear();
  }

  int size() => segments.length;

  bool contains(Segment segment) => segments.contains(segment);

  bool get isEmpty => segments.length == 0;

  static ContainerX createEmpty() => ContainerX();

  // Split container at segment position
  static ContainerPair split(ContainerX container, Segment key) {
    final index = container.segments.indexOf(key);
    if (index == -1) {
      return ContainerPair(container, ContainerX());
    }

    final leftSegments = container.segments.sublist(0, index);
    final rightSegments = container.segments.sublist(index + 1);

    final leftContainer = ContainerX();
    leftContainer.segments = leftSegments;

    final rightContainer = ContainerX();
    rightContainer.segments = rightSegments;

    return ContainerPair(leftContainer, rightContainer);
  }

  // Split container at position
  static ContainerPair splitAt(ContainerX container, int position) {
    if (position <= 0) {
      return ContainerPair(ContainerX(), container);
    }
    if (position >= container.size()) {
      return ContainerPair(container, ContainerX());
    }

    final leftSegments = container.segments.sublist(0, position);
    final rightSegments = container.segments.sublist(position);

    final leftContainer = ContainerX();
    leftContainer.segments = leftSegments;

    final rightContainer = ContainerX();
    rightContainer.segments = rightSegments;

    return ContainerPair(leftContainer, rightContainer);
  }

  @override
  String toString() => 'Container(${segments.length} segments, pos: $pos, measure: $measure)';
}

class ContainerPair {
  final ContainerX left;
  final ContainerX right;

  ContainerPair(this.left, this.right);
}

// Segment represents a vertical edge span between P and Q vertices
class Segment {
  final Node pVertex; // top vertex (P-vertex)
  final Node qVertex; // bottom vertex (Q-vertex)
  int index = -1;
  final int id;

  static int _nextId = 0;

  Segment(this.pVertex, this.qVertex) : id = _nextId++;

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => id;

  @override
  String toString() => 'Segment($id)';
}

class EiglspergerNodeData {
  bool isDummy = false;
  bool isPVertex = false;
  bool isQVertex = false;
  Segment? segment;
  int layer = -1;
  int position = -1;
  int rank = -1;
  double measure = -1;
  Set<Node> reversed = {};
  List<Node> predecessorNodes = [];
  List<Node> successorNodes = [];
  LineType lineType;

  EiglspergerNodeData(this.lineType);

  bool get isSegmentVertex => isPVertex || isQVertex;
  bool get isReversed => reversed.isNotEmpty;
}

class EiglspergerEdgeData {
  List<double> bendPoints = [];
}

// Virtual edge for container connections
class VirtualEdge {
  final dynamic source;
  final dynamic target;
  final int weight;

  VirtualEdge(this.source, this.target, this.weight);

  @override
  String toString() => 'VirtualEdge($source -> $target, weight: $weight)';
}

// Layer element that can be either a Node or Container
abstract class LayerElement {
  int index = -1;
  int pos = -1;
  double measure = -1;
}

// Node wrapper for layer elements
class NodeElement extends LayerElement {
  final Node node;
  NodeElement(this.node);

  @override
  String toString() => 'NodeElement(${node.toString()})';
}

// Container wrapper for layer elements
class ContainerElement extends LayerElement {
  final ContainerX container;
  ContainerElement(this.container);

  @override
  String toString() => 'ContainerElement(${container.toString()})';
}

class EiglspergerAlgorithm extends Algorithm {
  Map<Node, EiglspergerNodeData> nodeData = {};
  Map<Edge, EiglspergerEdgeData> _edgeData = {};
  Set<Node> stack = {};
  Set<Node> visited = {};
  List<List<Node>> layers = [];
  List<Segment> segments = [];
  Set<Edge> typeOneConflicts = {};
  late Graph graph;
  SugiyamaConfiguration configuration;

  @override
  EdgeRenderer? renderer;

  var nodeCount = 1;

  EiglspergerAlgorithm(this.configuration) {
    // renderer = SugiyamaEdgeRenderer(nodeData, edgeData, configuration.bendPointShape, configuration.addTriangleToEdge);
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
    initNodeData();
    cycleRemoval();
    layerAssignment();
    nodeOrdering(); // Eiglsperger 6-step process
    coordinateAssignment();
    shiftCoordinates(shiftX, shiftY);
    final graphSize = graph.calculateGraphSize();
    denormalize();
    restoreCycle();
    return graphSize;
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
    _edgeData.clear();
    segments.clear();
    typeOneConflicts.clear();
    nodeCount = 1;
  }

  void initNodeData() {
    graph.nodes.forEach((node) {
      node.position = Offset(0, 0);
      nodeData[node] = EiglspergerNodeData(node.lineType);
    });

    graph.edges.forEach((edge) {
      _edgeData[edge] = EiglspergerEdgeData();
    });

    graph.edges.forEach((edge) {
      nodeData[edge.source]?.successorNodes.add(edge.destination);
      nodeData[edge.destination]?.predecessorNodes.add(edge.source);
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

  void layerAssignment() {
    if (graph.nodes.isEmpty) {
      return;
    }

    // Build layers using topological sort
    final copiedGraph = copyGraph(graph);
    var roots = getRootNodes(copiedGraph);

    while (roots.isNotEmpty) {
      layers.add(roots);
      copiedGraph.removeNodes(roots);
      roots = getRootNodes(copiedGraph);
    }

    // Create segments for long edges
    createSegmentsForLongEdges();
  }

  void createSegmentsForLongEdges() {
    // Create segments for edges spanning more than one layer
    for (var i = 0; i < layers.length - 1; i++) {
      var currentLayer = layers[i];

      for (var node in List.from(currentLayer)) {
        final edges = graph.getOutEdges(node)
            .where((e) => (nodeData[e.destination]!.layer - nodeData[node]!.layer).abs() > 1)
            .toList();

        for (var edge in edges) {
          if (nodeData[edge.destination]!.layer - nodeData[node]!.layer == 2) {
            // Simple case: only one layer between source and target
            createSingleDummyVertex(edge, i + 1);
          } else {
            // Complex case: multiple layers between source and target
            createSegment(edge);
          }
          graph.removeEdge(edge);
        }
      }
    }
  }

  void createSingleDummyVertex(Edge edge, int dummyLayer) {
    final dummy = Node.Id(dummyId);

    final dummyData = EiglspergerNodeData(edge.source.lineType);
    dummyData.isDummy = true;
    dummyData.layer = dummyLayer;
    nodeData[dummy] = dummyData;

    dummy.size = Size(edge.source.width, 0);

    layers[dummyLayer].add(dummy);
    graph.addNode(dummy);

    final edge1 = graph.addEdge(edge.source, dummy);
    final edge2 = graph.addEdge(dummy, edge.destination);

    _edgeData[edge1] = EiglspergerEdgeData();
    _edgeData[edge2] = EiglspergerEdgeData();
  }

  void createSegment(Edge edge) {
    final sourceLayer = nodeData[edge.source]!.layer;
    final targetLayer = nodeData[edge.destination]!.layer;

    // Create P-vertex (top of segment)
    final pVertex = Node.Id(dummyId);
    final pData = EiglspergerNodeData(edge.source.lineType);
    pData.isDummy = true;
    pData.isPVertex = true;
    pData.layer = sourceLayer + 1;
    nodeData[pVertex] = pData;
    pVertex.size = Size(edge.source.width, 0);

    // Create Q-vertex (bottom of segment)
    final qVertex = Node.Id(dummyId);
    final qData = EiglspergerNodeData(edge.source.lineType);
    qData.isDummy = true;
    qData.isQVertex = true;
    qData.layer = targetLayer - 1;
    nodeData[qVertex] = qData;
    qVertex.size = Size(edge.source.width, 0);

    // Create segment and link vertices
    final segment = Segment(pVertex, qVertex);
    pData.segment = segment;
    qData.segment = segment;
    segments.add(segment);

    // Add to layers and graph
    layers[sourceLayer + 1].add(pVertex);
    layers[targetLayer - 1].add(qVertex);
    graph.addNode(pVertex);
    graph.addNode(qVertex);

    // Create edges
    final edgeToP = graph.addEdge(edge.source, pVertex);
    final segmentEdge = graph.addEdge(pVertex, qVertex);
    final edgeFromQ = graph.addEdge(qVertex, edge.destination);

    _edgeData[edgeToP] = EiglspergerEdgeData();
    _edgeData[segmentEdge] = EiglspergerEdgeData();
    _edgeData[edgeFromQ] = EiglspergerEdgeData();
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

    // Precalculate neighbor information


    var bestCrossCount = double.infinity;

    for (var i = 0; i < configuration.iterations; i++) {
      var crossCount = 0.0;

      if (i % 2 == 0) {
        crossCount = forwardSweep(layers);
      } else {
        crossCount = backwardSweep(layers);
      }

      if (crossCount < bestCrossCount) {
        bestCrossCount = crossCount;
        // Save best configuration
        for (var layerIndex = 0; layerIndex < layers.length; layerIndex++) {
          best[layerIndex] = List.from(layers[layerIndex]);
        }
      }

      if (crossCount == 0) break;
    }

    // Restore best configuration
    for (var layerIndex = 0; layerIndex < layers.length; layerIndex++) {
      layers[layerIndex] = best[layerIndex];
    }

    // Set final positions
    updateNodePositions();
  }

  double forwardSweep(List<List<Node>> layers) {
    var totalCrossings = 0.0;

    for (var i = 0; i < layers.length - 1; i++) {
      var currentLayer = layers[i];
      var nextLayer = layers[i + 1];

      // Convert to layer elements with containers
      var currentElements = createLayerElements(currentLayer);
      var nextElements = createLayerElements(nextLayer);

      // Eiglsperger 6-step process
      stepOne(currentElements, true); // Handle P-vertices
      stepTwo(currentElements, nextElements);
      stepThree(nextElements);
      stepFour(nextElements, i + 1);
      totalCrossings += stepFive(currentElements, nextElements, i, i + 1);
      stepSix(nextElements);

      // Convert back to node layer
      layers[i + 1] = extractNodes(nextElements);
    }

    return totalCrossings;
  }

  double backwardSweep(List<List<Node>> layers) {
    var totalCrossings = 0.0;

    for (var i = layers.length - 1; i > 0; i--) {
      var currentLayer = layers[i];
      var prevLayer = layers[i - 1];

      var currentElements = createLayerElements(currentLayer);
      var prevElements = createLayerElements(prevLayer);

      stepOne(currentElements, false); // Handle Q-vertices
      stepTwo(currentElements, prevElements);
      stepThree(prevElements);
      stepFour(prevElements, i - 1);
      totalCrossings += stepFive(currentElements, prevElements, i, i - 1);
      stepSix(prevElements);

      layers[i - 1] = extractNodes(prevElements);
    }

    return totalCrossings;
  }

  List<LayerElement> createLayerElements(List<Node> layer) {
    return layer.map((node) => NodeElement(node)).cast<LayerElement>().toList();
  }

  List<Node> extractNodes(List<LayerElement> elements) {
    var nodes = <Node>[];
    for (var element in elements) {
      if (element is NodeElement) {
        nodes.add(element.node);
      } else if (element is ContainerElement) {
        // Extract nodes from segments in container
        for (var segment in element.container.segments) {
          if (!nodes.contains(segment.pVertex)) {
            nodes.add(segment.pVertex);
          }
          if (!nodes.contains(segment.qVertex)) {
            nodes.add(segment.qVertex);
          }
        }
      }
    }
    return nodes;
  }

  // Eiglsperger Step 1: Handle P-vertices (forward) or Q-vertices (backward)
  void stepOne(List<LayerElement> layer, bool isForward) {
    var processedElements = <LayerElement>[];
    ContainerX? currentContainer;

    for (var element in layer) {
      if (element is NodeElement) {
        var node = element.node;
        var data = nodeData[node];

        bool shouldMerge = isForward ?
        (data?.isPVertex ?? false) :
        (data?.isQVertex ?? false);

        if (shouldMerge && data?.segment != null) {
          // Merge into container
          currentContainer ??= ContainerX();
          currentContainer.append(data!.segment!);

          if (!processedElements.any((e) => e is ContainerElement && e.container == currentContainer)) {
            processedElements.add(ContainerElement(currentContainer!));
          }
        } else {
          // Regular node
          processedElements.add(element);
          currentContainer = null;
        }
      } else {
        processedElements.add(element);
        currentContainer = null;
      }
    }

    layer.clear();
    layer.addAll(processedElements);
  }

  // Eiglsperger Step 2: Compute position values and measures
  void stepTwo(List<LayerElement> currentLayer, List<LayerElement> nextLayer) {
    // Assign positions to current layer
    assignPositions(currentLayer);

    // Compute measures for next layer based on current layer positions
    for (var element in nextLayer) {
      if (element is NodeElement) {
        var node = element.node;
        var predecessors = predecessorsOf(node);

        if (predecessors.isNotEmpty) {
          var positions = predecessors.map((p) => nodeData[p]?.position ?? 0).toList();
          positions.sort();
          element.measure = medianValue(positions).toDouble();
        } else {
          element.measure = element.pos.toDouble();
        }
      } else if (element is ContainerElement) {
        element.measure = element.pos.toDouble();
      }
    }
  }

  void assignPositions(List<LayerElement> layer) {
    var currentPos = 0;
    for (var element in layer) {
      element.pos = currentPos;

      if (element is NodeElement) {
        nodeData[element.node]?.position = currentPos;
        currentPos++;
      } else if (element is ContainerElement) {
        currentPos += element.container.size();
      }
    }
  }

  // Eiglsperger Step 3: Initial ordering based on measures
  void stepThree(List<LayerElement> layer) {
    var vertices = <LayerElement>[];
    var containers = <ContainerElement>[];

    // Separate vertices and containers
    for (var element in layer) {
      if (element is ContainerElement && element.container.size() > 0) {
        containers.add(element);
      } else if (element is NodeElement) {
        var data = nodeData[element.node];
        if (!(data?.isSegmentVertex ?? false)) {
          vertices.add(element);
        }
      }
    }

    // Sort by measure
    vertices.sort((a, b) => a.measure.compareTo(b.measure));
    containers.sort((a, b) => a.measure.compareTo(b.measure));

    // Merge lists according to Eiglsperger algorithm
    var merged = mergeSortedLists(vertices, containers);

    layer.clear();
    layer.addAll(merged);
  }

  List<LayerElement> mergeSortedLists(List<LayerElement> vertices, List<ContainerElement> containers) {
    var result = <LayerElement>[];
    var vIndex = 0;
    var cIndex = 0;

    while (vIndex < vertices.length && cIndex < containers.length) {
      var vertex = vertices[vIndex];
      var container = containers[cIndex];

      if (vertex.measure <= container.pos) {
        result.add(vertex);
        vIndex++;
      } else if (vertex.measure >= (container.pos + container.container.size() - 1)) {
        result.add(container);
        cIndex++;
      } else {
        // Split container
        var k = (vertex.measure - container.pos).ceil();
        var split = ContainerX.splitAt(container.container, k);

        if (split.left.size() > 0) {
          result.add(ContainerElement(split.left));
        }
        result.add(vertex);
        if (split.right.size() > 0) {
          split.right.pos = container.pos + k;
          containers.insert(cIndex + 1, ContainerElement(split.right));
        }
        vIndex++;
        cIndex++;
      }
    }

    // Add remaining elements
    while (vIndex < vertices.length) {
      result.add(vertices[vIndex++]);
    }
    while (cIndex < containers.length) {
      result.add(containers[cIndex++]);
    }

    return result;
  }

  // Eiglsperger Step 4: Place Q-vertices according to their segments
  void stepFour(List<LayerElement> layer, int layerIndex) {
    var segmentVertices = <NodeElement>[];

    // Find segment vertices in this layer
    for (var element in List.from(layer)) {
      if (element is NodeElement) {
        var data = nodeData[element.node];
        if (data?.isSegmentVertex ?? false) {
          segmentVertices.add(element);
          layer.remove(element);
        }
      }
    }

    // Place each segment vertex
    for (var segmentElement in segmentVertices) {
      var segmentNode = segmentElement.node;
      var data = nodeData[segmentNode];
      var segment = data?.segment;

      if (segment != null) {
        // Find container containing this segment
        ContainerElement? containerElement;
        for (var element in layer) {
          if (element is ContainerElement && element.container.contains(segment)) {
            containerElement = element;
            break;
          }
        }

        if (containerElement != null) {
          var containerIndex = layer.indexOf(containerElement);
          var split = ContainerX.split(containerElement.container, segment);

          layer.removeAt(containerIndex);

          if (split.left.size() > 0) {
            layer.insert(containerIndex, ContainerElement(split.left));
            containerIndex++;
          }

          layer.insert(containerIndex, segmentElement);
          containerIndex++;

          if (split.right.size() > 0) {
            layer.insert(containerIndex, ContainerElement(split.right));
          }
        } else {
          // No container found, just add the segment vertex
          layer.add(segmentElement);
        }
      }
    }

    updateIndices(layer);
  }

  void updateIndices(List<LayerElement> layer) {
    for (var i = 0; i < layer.length; i++) {
      layer[i].index = i;
      if (layer[i] is NodeElement) {
        var node = (layer[i] as NodeElement).node;
        nodeData[node]?.position = i;
      }
    }
  }

  // Eiglsperger Step 5: Cross counting with virtual edges
  double stepFive(List<LayerElement> currentLayer, List<LayerElement> nextLayer,
      int currentRank, int nextRank) {
    // Remove empty containers
    currentLayer.removeWhere((e) => e is ContainerElement && e.container.isEmpty);
    nextLayer.removeWhere((e) => e is ContainerElement && e.container.isEmpty);

    updateIndices(currentLayer);
    updateIndices(nextLayer);

    // Collect all edges including virtual edges
    var allEdges = <dynamic>[];

    // Add regular graph edges between these layers
    for (var edge in graph.edges) {
      if (nodeData[edge.source]?.layer == currentRank &&
          nodeData[edge.destination]?.layer == nextRank) {
        allEdges.add(edge);
      }
    }

    // Add virtual edges for containers
    for (var element in nextLayer) {
      if (element is ContainerElement && element.container.size() > 0) {
        var virtualEdge = VirtualEdge('virtual', element, element.container.size());
        allEdges.add(virtualEdge);
      } else if (element is NodeElement) {
        var data = nodeData[element.node];
        if (data?.isSegmentVertex ?? false) {
          var virtualEdge = VirtualEdge('virtual', element.node, 1);
          allEdges.add(virtualEdge);
        }
      }
    }

    // Count crossings with weights
    return countWeightedCrossings(allEdges, nextLayer);
  }

  double countWeightedCrossings(List<dynamic> edges, List<LayerElement> nextLayer) {
    var crossings = 0.0;

    for (var i = 0; i < edges.length - 1; i++) {
      for (var j = i + 1; j < edges.length; j++) {
        var edge1 = edges[i];
        var edge2 = edges[j];

        var weight1 = getEdgeWeight(edge1);
        var weight2 = getEdgeWeight(edge2);

        var pos1 = getTargetPosition(edge1, nextLayer);
        var pos2 = getTargetPosition(edge2, nextLayer);

        if (pos1 > pos2) {
          crossings += weight1 * weight2;
        }
      }
    }

    return crossings;
  }

  int getEdgeWeight(dynamic edge) {
    if (edge is VirtualEdge) {
      return edge.weight;
    }
    return 1;
  }

  int getTargetPosition(dynamic edge, List<LayerElement> nextLayer) {
    if (edge is VirtualEdge) {
      for (var i = 0; i < nextLayer.length; i++) {
        if ((nextLayer[i] is ContainerElement && nextLayer[i] == edge.target) ||
            (nextLayer[i] is NodeElement && (nextLayer[i] as NodeElement).node == edge.target)) {
          return i;
        }
      }
    } else if (edge is Edge) {
      for (var i = 0; i < nextLayer.length; i++) {
        if (nextLayer[i] is NodeElement &&
            (nextLayer[i] as NodeElement).node == edge.destination) {
          return i;
        }
      }
    }
    return 0;
  }

  // Eiglsperger Step 6: Scan and ensure alternating structure
  void stepSix(List<LayerElement> layer) {
    var scanned = <LayerElement>[];

    for (var i = 0; i < layer.length; i++) {
      var element = layer[i];

      if (scanned.isEmpty) {
        if (element is ContainerElement) {
          scanned.add(element);
        } else {
          scanned.add(ContainerElement(ContainerX.createEmpty()));
          scanned.add(element);
        }
      } else {
        var previous = scanned.last;

        if (previous is ContainerElement && element is ContainerElement) {
          // Join containers
          previous.container.join(element.container);
        } else if (previous is NodeElement && element is NodeElement) {
          // Insert empty container between nodes
          scanned.add(ContainerElement(ContainerX.createEmpty()));
          scanned.add(element);
        } else {
          scanned.add(element);
        }
      }
    }

    // Ensure ends with container
    if (scanned.isNotEmpty && scanned.last is NodeElement) {
      scanned.add(ContainerElement(ContainerX.createEmpty()));
    }

    layer.clear();
    layer.addAll(scanned);
    updateIndices(layer);
  }

  void updateNodePositions() {
    for (var layerIndex = 0; layerIndex < layers.length; layerIndex++) {
      for (var nodeIndex = 0; nodeIndex < layers[layerIndex].length; nodeIndex++) {
        var node = layers[layerIndex][nodeIndex];
        nodeData[node]?.position = nodeIndex;

        var data = nodeData[node];
        if (data != null) {
          data.rank = layerIndex;
        }
      }
    }
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
    // Simplified coordinate assignment - can be enhanced with full Brandes-Köpf algorithm
    var separation = configuration.nodeSeparation;
    var vertical = isVertical();

    for (var layerIndex = 0; layerIndex < layers.length; layerIndex++) {
      var layer = layers[layerIndex];
      var x = 0.0;

      for (var nodeIndex = 0; nodeIndex < layer.length; nodeIndex++) {
        var node = layer[nodeIndex];
        var width = vertical ? node.width + separation : node.height;
        node.x = x + width / 2;
        x += width + separation;
      }
    }
  }

  void assignXx() {
    // Existing implementation remains the same
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
      final type1Conflicts = <int, int>{};
      for (var leftToRight = 0; leftToRight <= 1; leftToRight++) {
        final k = 2 * downward + leftToRight;
        var isLeftToRight = leftToRight == 0;
        verticalAlignment(
            root[k], align[k], type1Conflicts, isDownward, isLeftToRight);
        graph.nodes.forEach((v) {
          final r = root[k][v]!;
          blockWidth[k][r] = max(
              blockWidth[k][r]!, vertical ? v.width + separation : v.height);
        });
        horizontalCompactation(align[k], root[k], sink[k], shift[k], blockWidth[k], x[k], isLeftToRight, isDownward, layers, separation);
      }
    }

    balance(x, blockWidth);
  }

  void balance(List<Map<Node, double>> x, List<Map<Node?, double>> blockWidth) {
    final coordinates = <Node, double>{};

    // switch (configuration.coordinateAssignment) {
    //   case CoordinateAssignment.Average:
    //     var minWidth = double.infinity;
    //
    //     var smallestWidthLayout = 0;
    //     final minArray = List.filled(4, 0.0);
    //     final maxArray = List.filled(4, 0.0);
    //
    //     // Get the layout with the smallest width and set minimum and maximum value for each direction;
    //     for (var i = 0; i < 4; i++) {
    //       minArray[i] = double.infinity;
    //       maxArray[i] = 0;
    //
    //       graph.nodes.forEach((v) {
    //         final bw = 0.5 * blockWidth[i][v]!;
    //         var xp = x[i][v]! - bw;
    //         if (xp < minArray[i]) {
    //           minArray[i] = xp;
    //         }
    //         xp = x[i][v]! + bw;
    //         if (xp > maxArray[i]) {
    //           maxArray[i] = xp;
    //         }
    //       });
    //
    //       final width = maxArray[i] - minArray[i];
    //       if (width < minWidth) {
    //         minWidth = width;
    //         smallestWidthLayout = i;
    //       }
    //     }
    //
    //     // Align the layouts to the one with the smallest width
    //     for (var layout = 0; layout < 4; layout++) {
    //       if (layout != smallestWidthLayout) {
    //         // Align the left to right layouts to the left border of the smallest layout
    //         var diff = 0.0;
    //         if (layout < 2) {
    //           diff = minArray[layout] - minArray[smallestWidthLayout];
    //         } else {
    //           // Align the right to left layouts to the right border of the smallest layout
    //           diff = maxArray[layout] - maxArray[smallestWidthLayout];
    //         }
    //         if (diff > 0) {
    //           x[layout].keys.forEach((n) {
    //             x[layout][n] = x[layout][n]! - diff;
    //           });
    //         } else {
    //           x[layout].keys.forEach((n) {
    //             x[layout][n] = x[layout][n]! + diff;
    //           });
    //         }
    //       }
    //     }
    //
    //     // Get the average median of each coordinate
    //     var values = List.filled(4, 0.0);
    //     graph.nodes.forEach((n) {
    //       for (var i = 0; i < 4; i++) {
    //         values[i] = x[i][n]!;
    //       }
    //       values.sort();
    //       var average = (values[1] + values[2]) * 0.5;
    //       coordinates[n] = average;
    //     });
    //     break;
    //   case CoordinateAssignment.DownRight:
    //     graph.nodes.forEach((n) {
    //       coordinates[n] = x[0][n] ?? 0.0;
    //     });
    //     break;
    //   case CoordinateAssignment.DownLeft:
    //     graph.nodes.forEach((n) {
    //       coordinates[n] = x[1][n] ?? 0.0;
    //     });
    //     break;
    //   case CoordinateAssignment.UpRight:
    //     graph.nodes.forEach((n) {
    //       coordinates[n] = x[2][n] ?? 0.0;
    //     });
    //     break;
    //   case CoordinateAssignment.UpLeft:
    //     graph.nodes.forEach((n) {
    //       coordinates[n] = x[3][n] ?? 0.0;
    //     });
    //     break;
    // }

    graph.nodes.forEach((n) {
      coordinates[n] = x[3][n] ?? 0.0;
    });
    // Get the minimum coordinate value
    var minValue = coordinates.values.reduce(min);

    // Set left border to 0
    if (minValue != 0) {
      coordinates.keys.forEach((n) {
        coordinates[n] = coordinates[n]! - minValue;
      });
    }

    // resolveOverlaps(coordinates);


    graph.nodes.forEach((v) {
      v.x = coordinates[v]!;
    });
  }

  void resolveOverlaps(Map<Node, double> coordinates) {
    for (var layer in layers) {
      var layerNodes = List<Node>.from(layer);
      layerNodes.sort(
              (a, b) => nodeData[a]!.position.compareTo(nodeData[b]!.position));

      var data = nodeData[layerNodes.first];
      if (data?.layer != 0) {
        var leftCoordinate = 0.0;
        for (var i = 1; i < layerNodes.length; i++) {
          var currentNode = layerNodes[i];
          if (!nodeData[currentNode]!.isDummy) {
            var previousNode = getPreviousNonDummyNode(layerNodes, i);

            if (previousNode != null) {
              leftCoordinate = coordinates[previousNode]! +
                  previousNode.width +
                  configuration.nodeSeparation;
            } else {
              leftCoordinate = 0.0;
            }

            if (leftCoordinate > coordinates[currentNode]!) {
              var adjustment = leftCoordinate - coordinates[currentNode]!;
              if (coordinates[currentNode] != null) {
                coordinates[currentNode] =
                    coordinates[currentNode]! + adjustment;
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

  // Map<int, int> markType1Conflicts(bool downward) {
  //   if (layers.length >= 4) {
  //     int upper;
  //     int lower; // iteration bounds;
  //     int k1; // node position boundaries of closest inner segments;
  //     if (downward) {
  //       lower = 1;
  //       upper = layers.length - 2;
  //     } else {
  //       lower = layers.length - 1;
  //       upper = 2;
  //     }
  //     /*;
  //            * iterate level[2..h-2] in the given direction;
  //            * available 1 levels to h;
  //            */
  //     for (var i = lower;
  //     downward ? i <= upper : i >= upper;
  //     i += downward ? 1 : -1) {
  //       var k0 = 0;
  //       var firstIndex = 0; // index of first node on layer;
  //       final currentLevel = layers[i];
  //       final nextLevel = downward ? layers[i + 1] : layers[i - 1];
  //
  //       // for all nodes on next level;
  //       for (var l1 = 0; l1 < nextLevel.length; l1++) {
  //         final virtualTwin = virtualTwinNode(nextLevel[l1], downward);
  //
  //         if (l1 == nextLevel.length - 1 || virtualTwin != null) {
  //           k1 = currentLevel.length - 1;
  //
  //           if (virtualTwin != null) {
  //             k1 = positionOfNode(virtualTwin);
  //           }
  //
  //           while (firstIndex <= l1) {
  //             final upperNeighbours = getAdjNodes(nextLevel[l1], downward);
  //
  //             for (var currentNeighbour in upperNeighbours) {
  //               /*;
  //               *  XXX< 0 in first iteration is still ok for indizes starting;
  //               * with 0 because no index can be smaller than 0;
  //                */
  //               final currentNeighbourIndex = positionOfNode(currentNeighbour);
  //
  //               if (currentNeighbourIndex < k0 || currentNeighbourIndex > k1) {
  //                 type1Conflicts[l1] = currentNeighbourIndex;
  //               }
  //             }
  //             firstIndex++;
  //           }
  //
  //           k0 = k1;
  //         }
  //       }
  //     }
  //   }
  //   return type1Conflicts;
  // }

  void verticalAlignment(Map<Node?, Node?> root, Map<Node?, Node?> align,
      Map<int, int> type1Conflicts, bool downward, bool leftToRight) {
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
              : [
            adjNodes[midLevelValue.toInt() - 1],
            adjNodes[midLevelValue.toInt()]
          ];

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

  void horizontalCompactation(
      Map<Node, Node> align,
      Map<Node, Node> root,
      Map<Node, Node> sink,
      Map<Node, double> shift,
      Map<Node, double> blockWidth,
      Map<Node, double> x,
      bool leftToRight,
      bool downward,
      List<List<Node>> layers,
      int separation) {
    // calculate class relative coordinates for all roots;
    // If the layers are traversed from right to left, a reverse iterator is needed (note that this does not change the original list of layers)
    var layersa = leftToRight ? layers : layers.reversed;

    for (var layer in layersa) {
      // As with layers, we need a reversed iterator for blocks for different directions
      var nodes = downward ? layer : layer.reversed;
      // Do an initial placement for all blocks
      for (var v in nodes) {
        if (root[v] == v) {
          placeBlock(v, sink, shift, x, align, blockWidth, root, leftToRight,
              layers, separation);
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

  void placeBlock(
      Node v,
      Map<Node, Node> sink,
      Map<Node, double> shift,
      Map<Node, double> x,
      Map<Node, Node> align,
      Map<Node, double> blockWidth,
      Map<Node, Node> root,
      bool leftToRight,
      List<List<Node>> layers,
      int separation) {
    if (x[v] == double.negativeInfinity) {
      x[v] = 0;
      var currentNode = v;

      try {
        do {
          // if not first node on layer;
          final hasPredecessor =
              leftToRight && positionOfNode(currentNode) > 0 ||
                  !leftToRight &&
                      positionOfNode(currentNode) <
                          layers[getLayerIndex(currentNode)].length - 1;
          // print("Pred  $hasPredecessor ${getLayerIndex(currentNode)>0} ${positionOfNode(currentNode)>0}");
          if (hasPredecessor) {
            final pred = predecessor(currentNode, leftToRight);
            /* Get the root of u (proceeding all the way upwards in the block) */
            final u = root[pred]!;
            /* Place the block of u recursively */
            placeBlock(u, sink, shift, x, align, blockWidth, root, leftToRight,
                layers, separation);
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
    return graph.successorsOf(node);
  }

  List<Node> predecessorsOf(Node? node) {
    return graph.predecessorsOf(node);
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
    return nodeData[v!]!.isDummy &&
        successors.length == 1 &&
        nodeData[successors[0]]!.isDummy;
  }

  void assignY() {
    var k = layers.length;
    var yPos = 0.0;
    var vertical = isVertical();

    for (var i = 0; i < k; i++) {
      var level = layers[i];
      var maxHeight = 0.0;

      level.forEach((node) {
        var h = nodeData[node]!.isDummy
            ? 0.0
            : vertical
            ? node.height
            : node.width;
        if (h > maxHeight) {
          maxHeight = h;
        }
        node.y = yPos;
      });

      if (i < k - 1) {
        yPos += configuration.levelSeparation + maxHeight;
      }
    }
  }

  void denormalize() {
    // Remove dummy vertices and create bend points for articulated edges
    for (var i = 1; i < layers.length - 1; i++) {
      final iterator = layers[i].iterator;

      while (iterator.moveNext()) {
        final current = iterator.current;
        if (nodeData[current]!.isDummy) {
          final predecessor = graph.predecessorsOf(current)[0];
          final successor = graph.successorsOf(current)[0];
          final bendPoints = _edgeData[graph.getEdgeBetween(predecessor, current)!]!.bendPoints;

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
          final edgeData = EiglspergerEdgeData();
          edgeData.bendPoints = bendPoints;
          this._edgeData[edge] = edgeData;

          graph.removeNode(current);
        }
      }
    }
  }

  void restoreCycle() {
    graph.nodes.forEach((n) {
      if (nodeData[n]!.isReversed) {
        nodeData[n]!.reversed.forEach((target) {
          final bendPoints = _edgeData[graph.getEdgeBetween(target, n)!]!.bendPoints;
          graph.removeEdgeFromPredecessor(target, n);
          final edge = graph.addEdge(n, target);

          final edgeData = EiglspergerEdgeData();
          edgeData.bendPoints = bendPoints;
          _edgeData[edge] = edgeData;
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

  static double medianValue(List<int> positions) {
    if (positions.isEmpty) return 0.0;
    if (positions.length == 1) return positions[0].toDouble();

    positions.sort();
    final mid = positions.length ~/ 2;

    if (positions.length % 2 == 1) {
      return positions[mid].toDouble();
    } else if (positions.length == 2) {
      return (positions[0] + positions[1]) / 2.0;
    } else {
      final left = positions[mid - 1] - positions[0];
      final right = positions[positions.length - 1] - positions[mid];
      if (left + right == 0) return 0.0;
      return (positions[mid - 1] * right + positions[mid] * left) / (left + right);
    }
  }

  @override
  void init(Graph? graph) {
    this.graph = copyGraph(graph!);
    reset();
    initNodeData();
    cycleRemoval();
    layerAssignment();
    nodeOrdering();
    coordinateAssignment();
    denormalize();
    restoreCycle();
  }

  @override
  void setDimensions(double width, double height) {
    // Can be used to set layout bounds if needed
  }
}