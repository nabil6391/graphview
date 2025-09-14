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
    graph.edges.forEach((edge) {
      nodeData[edge.source]?.successorNodes.add(edge.destination);
      nodeData[edge.destination]?.predecessorNodes.add(edge.source);
    });

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
        var predecessors = graph.predecessorsOf(node);

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
