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
    // if (!_nodes.contains(node)) {
      _nodes.add(node);
      notifyGraphObserver();
    // }
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

  Edge addEdge(Node source, Node destination, {Paint paint}) {
    final edge = Edge(source, destination, paint: paint);
    addEdgeS(edge);

    return edge;
  }

  void addEdgeS(Edge edge) {
    if (_nodes.contains(edge.source)) {
      edge.source = _nodes.firstWhere((element) => element == edge.source);
    } else {
      _nodes.add(edge.source);
    }
    if (_nodes.contains(edge.destination)) {
      edge.destination = _nodes.firstWhere((element) => element == edge.destination);
    } else {
      _nodes.add(edge.destination);
    }

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
      _edges.firstWhere((element) => element.source == source && element.destination == destination, orElse: ()=> null);

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

  Node getNodeAtUsingData(Widget data) => _nodes.firstWhere((element) => element.data == data);

  Node getNodeUsingKey(Key key) => _nodes.firstWhere((element) => element.key == key);

  List<Edge> getOutEdges(Node node) => _edges.where((element) => element.source == node).toList();

  List<Edge> getInEdges(Node node) => _edges.where((element) => element.destination == node).toList();

  void notifyGraphObserver() => graphObserver.forEach((element) {
        element.notifyGraphInvalidated();
      });

  static Graph lerp(Graph a, Graph b, double t) {
    if (b == null) {
      if (a == null) {
        return null;
      } else {
        a.nodes.forEach((n) {
          n.position = Offset.lerp(n.position, null, t);
        });
        return a;
      }
    } else {
      if (a == null) {
        b.nodes.forEach((n) {
          n.position = Offset.lerp(null, n.position, t);
        });
        return b;
      } else {
        a.nodes.asMap().forEach((position, value) {
          a.nodes[position].position = Offset.lerp(value.position, b.nodes[position].position, t);
        });
        return a;
      }
    }
  }

  List<Offset> getOffsets() {
    return nodes.map((e) => Offset(e.position.dx, e.position.dy)).toList();
  }

  // Graph.clone(Graph source) : this._edges = source.edges, this._nodes = source.nodes.map((e) => Node.clone(e).toList());
}

class Node {
  Key key;

  @required
  Widget data;

  Node(this.data, {this.key});

  Size size = Size(0, 0);

  Offset position = Offset(0, 0);

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
  bool operator ==(Object other) => identical(this, other) || other is Node && hashCode == other.hashCode;

  @override
  int get hashCode => key?.hashCode ?? data.hashCode;

  @override
  String toString() {
    return 'Node{position: $position, data: $data, _size: $size}';
  }

  Node.clone(Node randomObject) : data = randomObject.data, this.position = randomObject.position, this.size = randomObject.size, key = UniqueKey();
}

class Edge {
  Node source;
  Node destination;

  Key key;
  Paint paint;

  Edge(this.source, this.destination, {this.key, this.paint});

  @override
  bool operator ==(Object other) => identical(this, other) || other is Edge && hashCode == other.hashCode;

  @override
  int get hashCode => key?.hashCode ?? source.hashCode ^ destination.hashCode;
}

abstract class GraphObserver {
  void notifyGraphInvalidated();
}
