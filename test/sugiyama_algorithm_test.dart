import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:flutter_test/flutter_test.dart';

import 'example_trees.dart';

const itemHeight = 100.0;
const itemWidth = 100.0;

extension on Graph {
  void inflateWithJson(Map<String, Object> json) {
    var edges = json['edges']! as List;
    edges.forEach((element) {
      var fromNodeId = element['from'];
      var toNodeId = element['to'];
      addEdge(Node.Id(fromNodeId), Node.Id(toNodeId));
    });
  }
}

extension on Node {
  Rect toRect() => Rect.fromLTRB(x, y, x + width, y + height);
}

void main() {
  group('Sugiyama Graph', () {
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
    final node13 = Node.Id(13);
    final node14 = Node.Id(14);
    final node15 = Node.Id(15);
    final node16 = Node.Id(16);
    final node17 = Node.Id(17);
    final node18 = Node.Id(18);
    final node19 = Node.Id(19);
    final node20 = Node.Id(20);
    final node21 = Node.Id(21);
    final node22 = Node.Id(22);
    final node23 = Node.Id(23);

    graph.addEdge(node1, node13, paint: Paint()..color = Colors.red);
    graph.addEdge(node1, node21);
    graph.addEdge(node1, node4);
    graph.addEdge(node1, node3);
    graph.addEdge(node2, node3);
    graph.addEdge(node2, node20);
    graph.addEdge(node3, node4);
    graph.addEdge(node3, node5);
    graph.addEdge(node3, node23);
    graph.addEdge(node4, node6);
    graph.addEdge(node5, node7);
    graph.addEdge(node6, node8);
    graph.addEdge(node6, node16);
    graph.addEdge(node6, node23);
    graph.addEdge(node7, node9);
    graph.addEdge(node8, node10);
    graph.addEdge(node8, node11);
    graph.addEdge(node9, node12);
    graph.addEdge(node10, node13);
    graph.addEdge(node10, node14);
    graph.addEdge(node10, node15);
    graph.addEdge(node11, node15);
    graph.addEdge(node11, node16);
    graph.addEdge(node12, node20);
    graph.addEdge(node13, node17);
    graph.addEdge(node14, node17);
    graph.addEdge(node14, node18);
    graph.addEdge(node16, node18);
    graph.addEdge(node16, node19);
    graph.addEdge(node16, node20);
    graph.addEdge(node18, node21);
    graph.addEdge(node19, node22);
    graph.addEdge(node21, node23);
    graph.addEdge(node22, node23);
    graph.addEdge(node1, node22);
    graph.addEdge(node7, node8);

    test('Sugiyama Node positions are correct for Top_Bottom', () {
      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

      var algorithm = SugiyamaAlgorithm(_configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Timetaken $timeTaken');

      expect(timeTaken < 1000, true);

      expect(graph.getNodeAtPosition(0).position, Offset(660.0, 10));
      expect(graph.getNodeAtPosition(6).position, Offset(1045.0, 815.0));
      expect(graph.getNodeAtPosition(13).position, Offset(1045.0, 470.0));
      expect(graph.getNodeAtPosition(22).position, Offset(700, 930.0));
      expect(graph.getNodeUsingId(3).position, Offset(815.0, 125.0));
      expect(graph.getNodeUsingId(4).position, Offset(585.0, 240.0));

      expect(size, Size(1365.0, 1135.0));
    });

    test('Sugiyama Node positions correct for LEFT_RIGHT', () {
      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

      var algorithm = SugiyamaAlgorithm(_configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Timetaken $timeTaken');

      expect(timeTaken < 1000, true);

      expect(graph.getNodeAtPosition(0).position, Offset(10, 385.0));
      expect(graph.getNodeAtPosition(6).position, Offset(815.0, 745.0));
      expect(graph.getNodeAtPosition(13).position, Offset(470.0, 745.0));
      expect(graph.getNodeAtPosition(22).position, Offset(930, 500.0));
      expect(graph.getNodeUsingId(3).position, Offset(125.0, 465.0));
      expect(graph.getNodeUsingId(4).position, Offset(240.0, 342.5));

      expect(size, Size(1135.0, 865.0));
    });

    test('Sugiyama Performance for unconnected nodes', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(3));
      graph.addEdge(Node.Id(4), Node.Id(7));

      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

      var algorithm = SugiyamaAlgorithm(_configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      expect(graph.getNodeUsingId(1).position, Offset(10.0, 10.0));
      expect(graph.getNodeUsingId(3).position, Offset(125.0, 10.0));

      expect(size, Size(215.0, 215.0));
    });

    test('Sugiyama for a single directional graph', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(3));
      graph.addEdge(Node.Id(3), Node.Id(4));
      graph.addEdge(Node.Id(4), Node.Id(7));
      graph.addEdge(Node.Id(7), Node.Id(9));
      graph.addEdge(Node.Id(9), Node.Id(111));

      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

      var algorithm = SugiyamaAlgorithm(_configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      expect(graph.getNodeUsingId(1).position, Offset(10.0, 10.0));
      expect(graph.getNodeUsingId(3).position, Offset(125.0, 10.0));
      expect(graph.getNodeUsingId(9).position, Offset(470.0, 10.0));

      expect(size, Size(675.0, 100.0));
    });

    test('Sugiyama for a cyclic graph', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(3));
      graph.addEdge(Node.Id(3), Node.Id(4));
      graph.addEdge(Node.Id(4), Node.Id(7));
      graph.addEdge(Node.Id(7), Node.Id(9));
      graph.addEdge(Node.Id(9), Node.Id(1));

      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

      var algorithm = SugiyamaAlgorithm(_configuration);

      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();
      var size = algorithm.run(graph, 10, 10);
      var timeTaken = stopwatch.elapsed.inMilliseconds;

      expect(timeTaken < 1000, true);

      expect(graph.getNodeUsingId(1).position, Offset(10.0, 17.5));
      expect(graph.getNodeUsingId(3).position, Offset(125.0, 10.0));
      expect(graph.getNodeUsingId(9).position, Offset(470.0, 67.5));

      expect(size, Size(560.0, 157.5));
    });
  });

  test('Sugiyama for a complex graph with 140 nodes', () {
    final json = exampleTreeWith140Nodes;

    final graph = Graph();

    var edges = json['edges']!;
    edges.forEach((element) {
      var fromNodeId = element['from'];
      var toNodeId = element['to'];
      graph.addEdge(Node.Id(fromNodeId), Node.Id(toNodeId));
    });

    final _configuration = SugiyamaConfiguration()
      ..nodeSeparation = 15
      ..levelSeparation = 15
      ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

    final algorithm = SugiyamaAlgorithm(_configuration);

    for (var i = 0; i < graph.nodeCount(); i++) {
      graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
    }

    var stopwatch = Stopwatch()..start();
    var size = algorithm.run(graph, 10, 10);
    var timeTaken = stopwatch.elapsed.inMilliseconds;

    print('Timetaken $timeTaken ${graph.nodeCount()}');

    expect(graph.getNodeAtPosition(0).position, Offset(10.0, 397.5));
    expect(graph.getNodeAtPosition(6).position, Offset(700.0, 10.0));
    expect(graph.getNodeAtPosition(10).position, Offset(1045.0, 125.0));
    expect(graph.getNodeAtPosition(13).position, Offset(1160.0, 240.0));
    expect(graph.getNodeAtPosition(22).position, Offset(1505.0, 722.5));
    expect(graph.getNodeAtPosition(50).position, Offset(1620.0, 2432.5));
    expect(graph.getNodeAtPosition(67).position, Offset(2770, 2950.0));
    expect(graph.getNodeAtPosition(100).position, Offset(930.0, 1620.0));
    expect(graph.getNodeAtPosition(122).position, Offset(1850.0, 3252.5));
  });

  test('Sugiyama child nodes never overlaps', () {
    for (final json in exampleTrees) {
      final graph = Graph()..inflateWithJson(json);
      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      var stopwatch = Stopwatch()..start();

      SugiyamaAlgorithm(SugiyamaConfiguration())..run(graph, 10, 10);

      var timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Timetaken $timeTaken ${graph.nodeCount()}');

      for (var i = 0; i < graph.nodeCount(); i++) {
        final currentNode = graph.getNodeAtPosition(i);
        for (var j = 0; j < graph.nodeCount(); j++) {
          final otherNode = graph.getNodeAtPosition(j);

          if (currentNode.key == otherNode.key) continue;
          final currentRect = currentNode.toRect();
          final otherRect = otherNode.toRect();

          final overlaps = currentRect.overlaps(otherRect);
          expect(false, overlaps, reason: '$currentNode overlaps $otherNode');
        }
      }
    }
  });

  test('Sugiyama Performance for 100 nodes to be less than 2.5s', () {
    final graph = Graph();

    var rows = 100;

    for (var i = 1; i <= rows; i++) {
      for (var j = 1; j <= i; j++) {
        graph.addEdge(Node.Id(i), Node.Id(j));
      }
    }

    final _configuration = SugiyamaConfiguration()
      ..nodeSeparation = 15
      ..levelSeparation = 15
      ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

    var algorithm = SugiyamaAlgorithm(_configuration);

    for (var i = 0; i < graph.nodeCount(); i++) {
      graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
    }

    var stopwatch = Stopwatch()..start();
    var size = algorithm.run(graph, 10, 10);
    var timeTaken = stopwatch.elapsed.inMilliseconds;

    print('Timetaken $timeTaken ${graph.nodeCount()}');

    expect(timeTaken < 2500, true);
  });
}
