import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

const itemHeight = 100.0;
const itemWidth = 100.0;

void main() {
  group('Buchheim Graph', () {
    final graph = Graph();
    final node1 = Node.Id(1);
    final node2 = Node.Id(2);
    final node3 = Node.Id(3);
    final node4 = Node.Id(4);
    final node5 = Node.Id(5);
    final node6 = Node.Id(6);
    final node8 = Node.Id(7);
    final node7 = Node.Id(8);
    final node9 = Node.Id(9);
    final node10 = Node.Id(10);
    final node11 = Node.Id(11);
    final node12 = Node.Id(12);
    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3, paint: Paint()..color = Colors.red);
    graph.addEdge(node1, node4, paint: Paint()..color = Colors.blue);
    graph.addEdge(node2, node5);
    graph.addEdge(node2, node6);
    graph.addEdge(node6, node7, paint: Paint()..color = Colors.red);
    graph.addEdge(node6, node8, paint: Paint()..color = Colors.red);
    graph.addEdge(node4, node9);
    graph.addEdge(node4, node10, paint: Paint()..color = Colors.black);
    graph.addEdge(node4, node11, paint: Paint()..color = Colors.red);
    graph.addEdge(node11, node12);

    test('Buchheim Node positions are correct for Top_Bottom', () {
      final _configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150)
        ..subtreeSeparation = (150)
        ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

      var algorithm = BuchheimWalkerAlgorithm(
          _configuration, TreeEdgeRenderer(_configuration));

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Timetaken $timeTaken');

      expect(timeTaken < 1000, true);

      expect(graph.getNodeAtPosition(0).position, Offset(385, 10));
      expect(graph.getNodeAtPosition(6).position, Offset(110.0, 760.0));
      expect(graph.getNodeUsingId(3).position, Offset(385.0, 260.0));
      expect(graph.getNodeUsingId(4).position, Offset(660.0, 260.0));

      expect(size, Size(950.0, 850.0));
    });

    test('Buchheim Performance for 100 nodes to be less than 2.5s', () {


      final _configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150)
        ..subtreeSeparation = (150)
        ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

      var algorithm = BuchheimWalkerAlgorithm(
          _configuration, TreeEdgeRenderer(_configuration));

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();

      for (var i = 1; i <= 100; i++) {
        var size = algorithm.run(graph, 10, 10);
      }


      var timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Timetaken $timeTaken ${graph.nodeCount()}');

      expect(timeTaken < 100, true);
    });
  });
}
