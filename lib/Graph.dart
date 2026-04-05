part of graphview;

/// A directed graph data structure composed of [Node]s connected by [Edge]s.
///
/// Maintains cached successor/predecessor lookups that are automatically
/// invalidated when the graph structure changes.
class Graph {
  final List<Node> _nodes = [];
  final List<Edge> _edges = [];

  /// Observers notified when the graph structure changes.
  List<GraphObserver> graphObserver = [];

  // Cache
  final Map<Node, List<Node>> _successorCache = {};
  final Map<Node, List<Node>> _predecessorCache = {};
  bool _cacheValid = false;

  /// All nodes in this graph.
  List<Node> get nodes => _nodes;

  /// All edges in this graph.
  List<Edge> get edges => _edges;

  /// Whether this graph represents a tree (enables recursive removal).
  var isTree = false;

  /// Returns the number of nodes in this graph.
  int nodeCount() => _nodes.length;

  /// Adds a [node] to the graph and invalidates caches.
  void addNode(Node node) {
    _nodes.add(node);
    _cacheValid = false;
    notifyGraphObserver();
  }

  /// Adds multiple [nodes] to the graph.
  void addNodes(List<Node> nodes) => nodes.forEach((it) => addNode(it));

  /// Removes a [node] and its connected edges. If [isTree], also removes successors.
  void removeNode(Node? node) {
    if (!_nodes.contains(node)) return;

    if (isTree) {
      successorsOf(node).forEach((element) => removeNode(element));
    }

    _nodes.remove(node);
    _edges
        .removeWhere((edge) => edge.source == node || edge.destination == node);
    _cacheValid = false;
    notifyGraphObserver();
  }

  /// Removes multiple [nodes] from the graph.
  void removeNodes(List<Node> nodes) => nodes.forEach((it) => removeNode(it));

  /// Creates and adds an edge from [source] to [destination] with optional [paint].
  Edge addEdge(Node source, Node destination, {Paint? paint}) {
    final edge = Edge(source, destination, paint: paint);
    addEdgeS(edge);
    return edge;
  }

  /// Adds an existing [edge] to the graph, auto-adding missing source/destination nodes.
  void addEdgeS(Edge edge) {
    var sourceSet = false;
    var destinationSet = false;
    for (var node in _nodes) {
      if (!sourceSet && node == edge.source) {
        edge.source = node;
        sourceSet = true;
      }

      if (!destinationSet && node == edge.destination) {
        edge.destination = node;
        destinationSet = true;
      }

      if (sourceSet && destinationSet) {
        break;
      }
    }
    if (!sourceSet) {
      _nodes.add(edge.source);
      sourceSet = true;
      if (!destinationSet && edge.destination == edge.source) {
        destinationSet = true;
      }
    }
    if (!destinationSet) {
      _nodes.add(edge.destination);
      destinationSet = true;
    }

    if (!_edges.contains(edge)) {
      _edges.add(edge);
      _cacheValid = false;
      notifyGraphObserver();
    }
  }

  /// Adds multiple [edges] to the graph.
  void addEdges(List<Edge> edges) => edges.forEach((it) => addEdgeS(it));

  /// Removes an [edge] from the graph.
  void removeEdge(Edge edge) {
    _edges.remove(edge);
    _cacheValid = false;
  }

  /// Removes multiple [edges] from the graph.
  void removeEdges(List<Edge> edges) => edges.forEach((it) => removeEdge(it));

  /// Removes the edge connecting [predecessor] to [current].
  void removeEdgeFromPredecessor(Node? predecessor, Node? current) {
    _edges.removeWhere(
        (edge) => edge.source == predecessor && edge.destination == current);
    _cacheValid = false;
  }

  /// Whether this graph contains any nodes.
  bool hasNodes() => _nodes.isNotEmpty;

  /// Returns the edge from [source] to [destination], or null if none exists.
  Edge? getEdgeBetween(Node source, Node? destination) =>
      _edges.firstWhereOrNull((element) =>
          element.source == source && element.destination == destination);

  /// Whether [node] has any successors (outgoing edges).
  bool hasSuccessor(Node? node) => successorsOf(node).isNotEmpty;

  /// Returns all successor nodes of [node] (nodes reachable via outgoing edges).
  List<Node> successorsOf(Node? node) {
    if (node == null) return [];
    if (!_cacheValid) _buildCache();
    return _successorCache[node] ?? [];
  }

  /// Whether [node] has any predecessors (incoming edges).
  bool hasPredecessor(Node node) => predecessorsOf(node).isNotEmpty;

  /// Returns all predecessor nodes of [node] (nodes with edges pointing to it).
  List<Node> predecessorsOf(Node? node) {
    if (node == null) return [];
    if (!_cacheValid) _buildCache();
    return _predecessorCache[node] ?? [];
  }

  void _buildCache() {
    _successorCache.clear();
    _predecessorCache.clear();

    for (var node in _nodes) {
      _successorCache[node] = [];
      _predecessorCache[node] = [];
    }

    for (var edge in _edges) {
      _successorCache[edge.source]!.add(edge.destination);
      _predecessorCache[edge.destination]!.add(edge.source);
    }

    _cacheValid = true;
  }

  /// Whether the graph contains the given [node] or [edge].
  bool contains({Node? node, Edge? edge}) =>
      node != null && _nodes.contains(node) ||
      edge != null && _edges.contains(edge);

  /// Whether any node in the graph has the given [data] widget.
  bool containsData(data) => _nodes.any((element) => element.data == data);

  /// Returns the node at the given list [position].
  Node getNodeAtPosition(int position) {
    if (position < 0) {
//            throw IllegalArgumentException("position can't be negative")
    }

    final size = _nodes.length;
    if (position >= size) {
//            throw IndexOutOfBoundsException("Position: $position, Size: $size")
    }

    return _nodes[position];
  }

  @Deprecated('Please use the builder and id mechanism to build the widgets')
  Node getNodeAtUsingData(Widget data) =>
      _nodes.firstWhere((element) => element.data == data);

  /// Returns the node matching the given [key].
  Node getNodeUsingKey(ValueKey key) =>
      _nodes.firstWhere((element) => element.key == key);

  /// Returns the node whose key wraps the given [id].
  Node getNodeUsingId(dynamic id) =>
      _nodes.firstWhere((element) => element.key == ValueKey(id));

  /// Returns all outgoing edges from [node].
  List<Edge> getOutEdges(Node node) =>
      _edges.where((element) => element.source == node).toList();

  /// Returns all incoming edges to [node].
  List<Edge> getInEdges(Node node) =>
      _edges.where((element) => element.destination == node).toList();

  /// Notifies all registered [graphObserver]s that the graph has changed.
  void notifyGraphObserver() => graphObserver.forEach((element) {
        element.notifyGraphInvalidated();
      });

  /// Serializes the graph to a JSON string with node hashes and edge mappings.
  String toJson() {
    var jsonString = {
      'nodes': [..._nodes.map((e) => e.hashCode.toString())],
      'edges': [
        ..._edges.map((e) => {
              'from': e.source.hashCode.toString(),
              'to': e.destination.hashCode.toString()
            })
      ]
    };

    return json.encode(jsonString);
  }

}

/// Extension methods for computing graph geometry.
extension GraphExtension on Graph {
  /// Returns the bounding rectangle that encloses all nodes.
  Rect calculateGraphBounds() {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final node in nodes) {
        minX = min(minX, node.x);
        minY = min(minY, node.y);
        maxX = max(maxX, node.x + node.width);
        maxY = max(maxY, node.y + node.height);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Returns the total size of the graph based on its bounding rectangle.
  Size calculateGraphSize() {
    final bounds = calculateGraphBounds();
    return bounds.size;
  }
}

/// Visual style for edge and connection lines.
enum LineType {
  /// Solid continuous line.
  Default,
  /// Dotted line with small circle segments.
  DottedLine,
  /// Dashed line with alternating segments.
  DashedLine,
  /// Sine wave pattern line.
  SineLine,
}

/// A vertex in a [Graph], identified by a [ValueKey].
///
/// Use [Node.Id] to create nodes with a unique identifier.
/// The layout algorithm sets [position] and [size] during execution.
class Node {
  /// Unique identifier for this node. Two nodes with the same key value are equal.
  ValueKey? key;

  @Deprecated('Please use the builder and id mechanism to build the widgets')
  Widget? data;

  @Deprecated('Please use the Node.Id')
  Node(this.data, {Key? key}) {
    this.key = ValueKey(key?.hashCode ?? data.hashCode);
  }

  /// Creates a node with the given [id] as its identity key.
  Node.Id(dynamic id) {
    key = ValueKey(id);
  }

  /// The measured size of this node's widget, set during layout.
  Size size = Size(0, 0);

  /// The computed position of this node, set by the layout algorithm.
  Offset position = Offset(0, 0);

  /// The visual line style used when rendering edges to this node.
  LineType lineType = LineType.Default;

  double get height => size.height;

  double get width => size.width;

  double get x => position.dx;

  double get y => position.dy;

  set y(double value) {
    position = Offset(position.dx, value);
  }

  set x(double value) {
    position = Offset(value, position.dy);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Node && hashCode == other.hashCode;

  @override
  int get hashCode {
    return key?.value.hashCode ?? key.hashCode;
  }

  @override
  String toString() {
    return 'Node{position: $position, key: $key, _size: $size, lineType: $lineType}';
  }
}

/// A directed connection between two [Node]s in a [Graph].
class Edge {
  /// The origin node of this edge.
  Node source;

  /// The target node of this edge.
  Node destination;

  /// Optional key for identity comparison (overrides hash-based equality).
  Key? key;

  /// Optional custom paint for rendering this edge with specific colors or stroke width.
  Paint? paint;

  /// Creates an edge from [source] to [destination].
  Edge(this.source, this.destination, {this.key, this.paint});

  @override
  bool operator ==(Object? other) =>
      identical(this, other) || other is Edge && hashCode == other.hashCode;

  @override
  int get hashCode => key?.hashCode ?? Object.hash(source, destination);
}

/// Observer interface for receiving notifications when a [Graph] structure changes.
abstract class GraphObserver {
  /// Called when the graph's node or edge structure has been modified.
  void notifyGraphInvalidated();
}
