part of graphview;

class Graph {
  final List<Node> _nodes = [];
  final List<Edge> _edges = [];
  List<GraphObserver> graphObserver = [];

  List<Node> get nodes => _nodes; //  List<Node> nodes = _nodes;
  List<Edge> get edges => _edges;

  var isTree = false;

  int nodeCount() => _nodes.length;

  void addNode(Node node) {
    if (!_nodes.contains(node)) {
      _nodes.add(node);
      notifyGraphObserver();
    }
  }

  void addNodes(List<Node> nodes) => nodes.forEach((it) => addNode(it));

  void removeNode(Node node) {
    if (!_nodes.contains(node)) {
//            throw IllegalArgumentException("Unable to find node in graph.")
    }

    if (isTree) {
      successorsOf(node).forEach((element) => removeNode(element));
    }

    _nodes.remove(node);

    _edges.removeWhere((edge) => edge.source == node || edge.destination == node);

    notifyGraphObserver();
  }

  void removeNodes(List<Node> nodes) => nodes.forEach((it) => removeNode(it));

  Edge addEdge(Node source, Node destination) {
    final edge = Edge(source, destination);
    addEdgeS(edge);

    return edge;
  }

  void addEdgeS(Edge edge) {
    addNode(edge.source);
    addNode(edge.destination);

    if (!_edges.contains(edge)) {
      _edges.add(edge);
      notifyGraphObserver();
    }
  }

  void addEdges(List<Edge> edges) => edges.forEach((it) => addEdgeS(it));

  void removeEdge(Edge edge) => _edges.remove(edge);

  void removeEdges(List<Edge> edges) => edges.forEach((it) => removeEdge(it));

  void removeEdgeFromPredecessor(Node predecessor, Node current) {
    _edges.removeWhere((edge) => edge.source == predecessor && edge.destination == current);
  }

  bool hasNodes() => _nodes.isNotEmpty;

  Edge getEdgeBetween(Node source, Node destination) =>
      _edges.firstWhere((element) => element.source == source && element.destination == destination);

  bool hasSuccessor(Node node) => _edges.any((element) => element.source == node);

  List<Node> successorsOf(Node node) =>
      _edges.where((element) => element.source == node).map((e) => e.destination).toList();

  bool hasPredecessor(Node node) => _edges.any((element) => element.destination == node);

  List<Node> predecessorsOf(Node node) =>
      _edges.where((element) => element.destination == node).map((edge) => edge.source).toList();

  bool contains({Node node, Edge edge}) =>
      node != null && _nodes.contains(node) || edge != null && _edges.contains(edge);

//  bool contains(Edge edge) => _edges.contains(edge);

  bool containsData(data) => _nodes.any((element) => element.data == data);

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

  Node getNodeAtPositionUsingData(Widget data) => _nodes.firstWhere((element) => element.data == data);

  List<Edge> getOutEdges(Node node) => _edges.where((element) => element.source == node).toList();

  List<Edge> getInEdges(Node node) => _edges.where((element) => element.destination == node).toList();

  void notifyGraphObserver() => graphObserver.forEach((element) {
        element.notifyGraphInvalidated();
      });
}

class Node {
  Offset _position = Offset(0, 0);

  Key key;

  @required
  Widget data;

  Node(this.data, {this.key});

  Size _size = Size(0, 0);

  double get height => _size.height;

  double get width => _size.width;

  double get x => _position.dx;

  double get y => _position.dy;

  Offset get position => _position;

  set position(Offset value) {
    _position = value;
  }

  set y(double value) {
    _position = Offset(_position.dx, value);
  }

  set x(double value) {
    _position = Offset(value, _position.dy);
  }

  Size get size => _size;

  set size(Size value) {
    _size = value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Node && hashCode == other.hashCode;

  @override
  int get hashCode => key?.hashCode ?? data.hashCode;

  @override
  String toString() {
    return 'Node{_position: $_position, data: $data, _size: $_size}';
  }
}

class Edge {
  Node source;
  Node destination;

  Key key;

  Edge(this.source, this.destination, {this.key});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Edge && hashCode == other.hashCode;

  @override
  int get hashCode => key?.hashCode ?? source.hashCode ^ destination.hashCode;
}

abstract class GraphObserver {
  void notifyGraphInvalidated();
}
