import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class Graph {
  final List<Node> _nodes = [];
  final List<Edge> _edges = [];
  List<GraphObserver> observers = [];

  void addNode(Node node) {
    _nodes.add(node);
    notifyGraphInvalidated();
  }

  void addNodes(List<Node> nodes) {
    _nodes.addAll(nodes);
    notifyGraphInvalidated();
  }

  void removeNode(Node node) {
    _nodes.remove(node);
    _edges.removeWhere(
        (edge) => edge.source == node || edge.destination == node);
    notifyGraphInvalidated();
  }

  Edge addEdge(Node source, Node destination,
      {Paint? paint,
      LineType? lineType,
      Color? interactiveFillColor,
      Color? interactiveBorderColor}) {
    var edge = Edge(source, destination,
        paint: paint,
        lineType: lineType,
        interactiveFillColor: interactiveFillColor,
        interactiveBorderColor: interactiveBorderColor);
    _edges.add(edge);
    notifyGraphInvalidated();
    return edge;
  }

  void removeEdge(Edge edge) {
    _edges.remove(edge);
    notifyGraphInvalidated();
  }

  List<Node> get nodes => _nodes;

  List<Edge> get edges => _edges;

  int nodeCount() => _nodes.length;

  int edgeCount() => _edges.length;

  Node getNodeAtPosition(int index) => _nodes[index];

  Edge getEdgeAtPosition(int index) => _edges[index];

  List<Node> predecessorsOf(Node node) {
    return _edges
        .where((edge) => edge.destination == node)
        .map((edge) => edge.source)
        .toList();
  }

  List<Node> successorsOf(Node node) {
    return _edges
        .where((edge) => edge.source == node)
        .map((edge) => edge.destination)
        .toList();
  }

  void notifyGraphInvalidated() {
    observers.forEach((observer) => observer.notifyGraphInvalidated());
  }

  void addObserver(GraphObserver observer) {
    observers.add(observer);
  }

  void removeObserver(GraphObserver observer) {
    observers.remove(observer);
  }
}

class Node {
  ValueKey? key;

  @Deprecated('Please use the builder and id mechanism to build the widgets')
  Widget? data;

  @Deprecated('Please use the Node.Id')
  Node(this.data, {Key? key}) {
    this.key = ValueKey(key?.hashCode ?? data.hashCode);
  }

  Node.Id(dynamic id) {
    key = ValueKey(id);
  }

  Size size = Size(0, 0);

  Offset position = Offset(0, 0);

  /// Optional metadata for layout engines (e.g. ELK hints)
  Map<String, dynamic> metadata = {};

  LineType lineType = LineType.Default;

  double get height => size.height;

  double get width => size.width;

  double get x => position.dx;

  set x(double value) {
    position = Offset(value, position.dy);
  }

  double get y => position.dy;

  set y(double value) {
    position = Offset(position.dx, value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Node && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;
}

class Edge {
  Node source;
  Node destination;
  Paint? paint;
  LineType? lineType;
  EdgeAnimation? animation;

  /// Used by ELK and other algorithms for complex routing
  List<Offset>? sections;

  /// Interaction support
  bool interactive = false;
  Color? interactiveFillColor;
  Color? interactiveBorderColor;

  Edge(this.source, this.destination,
      {this.paint,
      this.lineType,
      this.interactiveFillColor,
      this.interactiveBorderColor});
}

enum LineType {
  Default,
  DashedLine,
  DottedLine,
}

class EdgeAnimation {
  final EdgeAnimationShape? shape;
  final TextPainter? icon;

  EdgeAnimation({this.shape, this.icon});
}

enum EdgeAnimationShape {
  circle,
  square,
  triangle;
}

abstract class GraphObserver {
  void notifyGraphInvalidated();
}
