import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

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

    test('Sugiyama for unconnected nodes', () {
      final graph = Graph();

      graph.addEdge(Node.Id(1), Node.Id(3));
      graph.addEdge(Node.Id(4), Node.Id(7));

      final _configuration = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
        ..postStraighten = true;

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
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
        ..postStraighten = true;

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
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
        ..postStraighten = true;

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

    group('Layering Strategy Tests', () {
      test('TopDown Strategy - Node Positioning TOP_BOTTOM', () {
        final _configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..layeringStrategy = LayeringStrategy.topDown
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
          ..postStraighten = true;

        var algorithm = SugiyamaAlgorithm(_configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print(
            'TopDown Strategy TOP_BOTTOM - Time: ${timeTaken}ms, Size: $size');

        expect(timeTaken < 1000, true);

        expect(graph.getNodeAtPosition(0).position, Offset(660.0, 10));
        expect(graph.getNodeAtPosition(6).position, Offset(1180.0, 815.0));
        expect(graph.getNodeAtPosition(13).position, Offset(1180.0, 470.0));
        expect(graph.getNodeAtPosition(22).position, Offset(790, 930.0));
        expect(graph.getNodeAtPosition(3).position, Offset(660.0, 240.0));
        expect(graph.getNodeAtPosition(4).position, Offset(920.0, 125.0));

        expect(size, Size(1530.0, 1135.0));
      });

      test('TopDown Strategy - Node Positioning LEFT_RIGHT', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..layeringStrategy = LayeringStrategy.topDown
          ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
          ..postStraighten = true;

        var algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print(
            'TopDown Strategy LEFT_RIGHT - Time: ${timeTaken}ms, Size: $size');

        expect(timeTaken < 1000, true);

        expect(graph.getNodeAtPosition(0).position, Offset(10, 385.0));
        expect(graph.getNodeAtPosition(6).position, Offset(815.0, 745.0));
        expect(graph.getNodeAtPosition(13).position, Offset(470.0, 745.0));
        expect(graph.getNodeAtPosition(22).position, Offset(930, 500.0));
        expect(graph.getNodeUsingId(3).position, Offset(125.0, 465.0));
        expect(graph.getNodeUsingId(4).position, Offset(240.0, 342.5));

        expect(size, Size(1135.0, 865.0));
      });

      test('LongestPath Strategy - Node Positioning', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..layeringStrategy = LayeringStrategy.longestPath
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
          ..postStraighten = true;

        final algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('LongestPath Strategy - Time: ${timeTaken}ms, Size: $size');

        expect(graph.getNodeAtPosition(0).position, Offset(140.0, 10));

        expect(graph.getNodeAtPosition(6).position, Offset(1505.0, 1045.0));
        expect(graph.getNodeAtPosition(13).position, Offset(1700.0, 815.0));
        expect(graph.getNodeAtPosition(22).position, Offset(985.0, 930.0));
        expect(graph.getNodeAtPosition(3).position, Offset(725.0, 240.0));
        expect(graph.getNodeAtPosition(4).position, Offset(1115.0, 125.0));

        expect(timeTaken < 1000, true);
        expect(size, Size(2050.0, 1135.0));
      });

      test('CoffmanGraham Strategy - Node Positioning', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..layeringStrategy = LayeringStrategy.coffmanGraham
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
          ..postStraighten = true;

        final algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('CoffmanGraham Strategy - Time: ${timeTaken}ms, Size: $size');

        // Test exact positions
        expect(graph.getNodeAtPosition(0).position, Offset(1245.0, 10.0));
        expect(graph.getNodeAtPosition(6).position, Offset(400.0, 1045.0));
        expect(graph.getNodeAtPosition(13).position, Offset(140.0, 470.0));
        expect(graph.getNodeAtPosition(22).position, Offset(465.0, 930.0));
        expect(graph.getNodeAtPosition(3).position, Offset(1180.0, 240.0));
        expect(graph.getNodeAtPosition(4).position, Offset(985.0, 125.0));

        expect(timeTaken < 1000, true);
        expect(size, Size(2375.0, 1135.0));
      });

      test('NetworkSimplex Strategy - Node Positioning', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..layeringStrategy = LayeringStrategy.networkSimplex
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
          ..postStraighten = true;

        final algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('NetworkSimplex Strategy - Time: ${timeTaken}ms, Size: $size');

        // Test exact positions
        expect(graph.getNodeAtPosition(0).position, Offset(140.0, 10.0));
        expect(graph.getNodeAtPosition(6).position, Offset(1505.0, 1045.0));
        expect(graph.getNodeAtPosition(13).position, Offset(1700.0, 815.0));
        expect(graph.getNodeAtPosition(22).position, Offset(985.0, 930.0));
        expect(graph.getNodeAtPosition(3).position, Offset(725.0, 240.0));
        expect(graph.getNodeAtPosition(4).position, Offset(1115.0, 125.0));

        expect(timeTaken < 1000, true);
        expect(size, Size(2050.0, 1135.0));
      });
    });

    group('Cross Minimization Strategy Tests', () {
      test('Simple CrossMinimization - Positioning', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..crossMinimizationStrategy = CrossMinimizationStrategy.simple
          ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
          ..postStraighten = true;

        final algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('Simple CrossMin - Time: ${timeTaken}ms, Size: $size');

        // Test exact positions
        expect(graph.getNodeAtPosition(6).position, Offset(815.0, 745.0));
        expect(graph.getNodeAtPosition(13).position, Offset(470.0, 745.0));
        expect(graph.getNodeAtPosition(22).position, Offset(930.0, 500.0));
        expect(graph.getNodeAtPosition(3).position, Offset(240.0, 342.5));
        expect(graph.getNodeAtPosition(4).position, Offset(125.0, 465.0));

        expect(timeTaken < 1000, true);
        expect(size, Size(1135.0, 865.0));
      });

      test('AccumulatorTree CrossMinimization - Positioning', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..crossMinimizationStrategy =
              CrossMinimizationStrategy.accumulatorTree
          ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
          ..postStraighten = true;

        final algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('AccumulatorTree CrossMin - Time: ${timeTaken}ms, Size: $size');

        // Test exact positions
        expect(graph.getNodeAtPosition(0).position, Offset(10.0, 385.0));
        expect(graph.getNodeAtPosition(6).position, Offset(815.0, 715.0));
        expect(graph.getNodeAtPosition(13).position, Offset(470.0, 715.0));
        expect(graph.getNodeAtPosition(22).position, Offset(930.0, 470.0));
        expect(graph.getNodeAtPosition(3).position, Offset(240.0, 342.5));
        expect(graph.getNodeAtPosition(4).position, Offset(125.0, 465.0));

        expect(timeTaken < 1000, true);
        expect(size, Size(1135.0, 865.0));
      });
    });

    // Test Cycle Removal Strategies
    group('Cycle Removal Strategy Tests', () {
      final graph = Graph();
      final node1 = Node.Id(1);
      final node2 = Node.Id(2);
      final node3 = Node.Id(3);
      final node4 = Node.Id(4);
      final node5 = Node.Id(5);

      // Create a cyclic graph
      graph.addEdge(node1, node2);
      graph.addEdge(node2, node3);
      graph.addEdge(node3, node4);
      graph.addEdge(node4, node1); // Creates cycle
      graph.addEdge(node2, node5);

      test('DFS Cycle Removal - Positioning', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..cycleRemovalStrategy = CycleRemovalStrategy.dfs
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
          ..postStraighten = true;

        final algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('DFS Cycle Removal - Time: ${timeTaken}ms, Size: $size');

        // Test exact positions - layout should be acyclic
        expect(graph.getNodeAtPosition(1).position, Offset(75.0, 125.0));
        expect(graph.getNodeAtPosition(2).position, Offset(10.0, 240.0));
        expect(graph.getNodeAtPosition(3).position, Offset(140.0, 355.0));
        expect(timeTaken < 1000, true);
        expect(size, Size(360, 445.0));
      });

      test('Greedy Cycle Removal - Positioning', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..cycleRemovalStrategy = CycleRemovalStrategy.greedy
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
          ..postStraighten = true;

        final algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('Greedy Cycle Removal - Time: ${timeTaken}ms, Size: $size');

        // Test exact positions - layout should be acyclic
        expect(graph.getNodeAtPosition(1).position, Offset(75.0, 240.0));
        expect(graph.getNodeAtPosition(2).position, Offset(140.0, 355.0));
        expect(graph.getNodeAtPosition(3).position, Offset(75.0, 10.0));
        expect(timeTaken < 1000, true);
        expect(size, Size(295.0, 445.0));
      });
    });

    group('Coordinate Assignment Strategy Tests', () {
      test('DownRight Coordinate Assignment', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..coordinateAssignment = CoordinateAssignment.DownRight
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
          ..postStraighten = true;

        final algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('DownRight Assignment - Time: ${timeTaken}ms, Size: $size');

        // Test exact positions
        expect(graph.getNodeAtPosition(1).position, Offset(790.0, 700.0));
        expect(graph.getNodeAtPosition(2).position, Offset(1050.0, 930.0));
        expect(graph.getNodeAtPosition(3).position, Offset(530.0, 240.0));

        expect(timeTaken < 1000, true);
        expect(size, Size(2050.0, 1135.0));
      });

      test('DownLeft Coordinate Assignment', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..coordinateAssignment = CoordinateAssignment.DownLeft
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
          ..postStraighten = true;

        final algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('DownLeft Assignment - Time: ${timeTaken}ms, Size: $size');

        // Test exact positions
        expect(graph.getNodeAtPosition(0).position, Offset(1310.0, 10.0));
        expect(graph.getNodeAtPosition(6).position, Offset(1180.0, 815.0));
        expect(graph.getNodeAtPosition(22).position, Offset(530.0, 930.0));
        expect(graph.getNodeUsingId(3).position, Offset(1310.0, 125.0));
        expect(graph.getNodeUsingId(4).position, Offset(920.0, 240.0));

        expect(timeTaken < 1000, true);
        expect(size, Size(1530.0, 1135.0));
      });

      test('Average Coordinate Assignment', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..coordinateAssignment = CoordinateAssignment.Average
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
          ..postStraighten = true;

        final algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('Average Assignment - Time: ${timeTaken}ms, Size: $size');

        // Test exact positions
        expect(graph.getNodeAtPosition(0).position, Offset(660.0, 10.0));
        expect(graph.getNodeAtPosition(13).position, Offset(1180.0, 470.0));
        expect(graph.getNodeAtPosition(22).position, Offset(790, 930.0));
        expect(graph.getNodeUsingId(3).position, Offset(920.0, 125.0));
        expect(graph.getNodeUsingId(4).position, Offset(660.0, 240.0));

        expect(timeTaken < 1000, true);
        expect(size, Size(1530.0, 1135.0));
      });

      test('UpRight Coordinate Assignment', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..coordinateAssignment = CoordinateAssignment.UpRight
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
          ..postStraighten = true;

        final algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('UpRight Assignment - Time: ${timeTaken}ms, Size: $size');

        // Test exact positions
        expect(graph.getNodeAtPosition(0).position, Offset(140.0, 10.0));
        expect(graph.getNodeAtPosition(6).position, Offset(1050.0, 815.0));
        expect(graph.getNodeAtPosition(13).position, Offset(1050.0, 470.0));
        expect(graph.getNodeAtPosition(22).position, Offset(400.0, 930.0));
        expect(graph.getNodeAtPosition(3).position, Offset(400.0, 240.0));
        expect(graph.getNodeAtPosition(4).position, Offset(1050.0, 125.0));

        expect(timeTaken < 1000, true);
        expect(size, Size(1400.0, 1135.0));
      });

      test('UpLeft Coordinate Assignment', () {
        final configuration = SugiyamaConfiguration()
          ..nodeSeparation = 15
          ..levelSeparation = 15
          ..coordinateAssignment = CoordinateAssignment.UpLeft
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
          ..postStraighten = true;

        final algorithm = SugiyamaAlgorithm(configuration);

        for (var i = 0; i < graph.nodeCount(); i++) {
          graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
        }

        var stopwatch = Stopwatch()..start();
        var size = algorithm.run(graph, 10, 10);
        var timeTaken = stopwatch.elapsed.inMilliseconds;

        print('UpLeft Assignment - Time: ${timeTaken}ms, Size: $size');

        // Test exact positions
        expect(graph.getNodeAtPosition(0).position, Offset(140.0, 10.0));
        expect(graph.getNodeAtPosition(6).position, Offset(1440.0, 815.0));
        expect(graph.getNodeAtPosition(13).position, Offset(1440.0, 470.0));
        expect(graph.getNodeAtPosition(22).position, Offset(1310.0, 930.0));
        expect(graph.getNodeAtPosition(3).position, Offset(270.0, 240.0));
        expect(graph.getNodeAtPosition(4).position, Offset(1440.0, 125.0));

        expect(timeTaken < 1000, true);
        expect(size, Size(1790.0, 1135.0));
      });
    });

    // Performance Tests for 140 Node Graph
    group('140 Node Graph Performance Tests', () {
      test('Layering Strategy Performance Comparison - 140 Nodes', () {
        print('\n=== 140 Node Graph - Layering Strategy Performance ===');

        final strategies = [
          {'strategy': LayeringStrategy.topDown, 'name': 'TopDown'},
          {'strategy': LayeringStrategy.longestPath, 'name': 'LongestPath'},
          {'strategy': LayeringStrategy.coffmanGraham, 'name': 'CoffmanGraham'},
          {
            'strategy': LayeringStrategy.networkSimplex,
            'name': 'NetworkSimplex'
          },
        ];

        for (final strategy in strategies) {
          final graph = Graph();
          graph.inflateWithJson(exampleTreeWith140Nodes);

          for (var i = 0; i < graph.nodeCount(); i++) {
            graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
          }

          final configuration = SugiyamaConfiguration()
            ..nodeSeparation = 15
            ..levelSeparation = 15
            ..layeringStrategy = strategy['strategy'] as LayeringStrategy
            ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
            ..postStraighten = true;

          final algorithm = SugiyamaAlgorithm(configuration);

          final stopwatch = Stopwatch()..start();
          final size = algorithm.run(graph, 10, 10);
          final timeTaken = stopwatch.elapsed.inMilliseconds;

          print(
              '${strategy['name']}: ${timeTaken}ms - Layout size: $size - Nodes: ${graph.nodeCount()}');

          expect(timeTaken < 3000, true,
              reason:
                  '${strategy['name']} should complete within 3 seconds for 140 nodes');
        }
      });

      test('CrossMinimization Strategy Performance - 140 Nodes', () {
        print('\n=== 140 Node Graph - Cross Minimization Performance ===');

        final strategies = [
          {'strategy': CrossMinimizationStrategy.simple, 'name': 'Simple'},
          {
            'strategy': CrossMinimizationStrategy.accumulatorTree,
            'name': 'AccumulatorTree'
          },
        ];

        for (final strategy in strategies) {
          final graph = Graph();
          graph.inflateWithJson(exampleTreeWith140Nodes);

          for (var i = 0; i < graph.nodeCount(); i++) {
            graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
          }

          final configuration = SugiyamaConfiguration()
            ..nodeSeparation = 15
            ..levelSeparation = 15
            ..crossMinimizationStrategy =
                strategy['strategy'] as CrossMinimizationStrategy
            ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
            ..postStraighten = true;

          final algorithm = SugiyamaAlgorithm(configuration);

          final stopwatch = Stopwatch()..start();
          final size = algorithm.run(graph, 10, 10);
          final timeTaken = stopwatch.elapsed.inMilliseconds;

          print(
              '${strategy['name']}: ${timeTaken}ms - Layout size: $size - Nodes: ${graph.nodeCount()}');

          expect(timeTaken < 3000, true,
              reason: '${strategy['name']} should complete within 3 seconds');
        }
      });

      test('Cycle Removal Strategy Performance - 140 Nodes', () {
        print('\n=== 140 Node Graph - Cycle Removal Performance ===');

        final strategies = [
          {'strategy': CycleRemovalStrategy.dfs, 'name': 'DFS'},
          {'strategy': CycleRemovalStrategy.greedy, 'name': 'Greedy'},
        ];

        for (final strategy in strategies) {
          final graph = Graph();
          graph.inflateWithJson(exampleTreeWith140Nodes);

          for (var i = 0; i < graph.nodeCount(); i++) {
            graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
          }

          final configuration = SugiyamaConfiguration()
            ..nodeSeparation = 15
            ..levelSeparation = 15
            ..cycleRemovalStrategy =
                strategy['strategy'] as CycleRemovalStrategy
            ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
            ..postStraighten = true;

          final algorithm = SugiyamaAlgorithm(configuration);

          final stopwatch = Stopwatch()..start();
          final size = algorithm.run(graph, 10, 10);
          final timeTaken = stopwatch.elapsed.inMilliseconds;

          print(
              '${strategy['name']}: ${timeTaken}ms - Layout size: $size - Nodes: ${graph.nodeCount()}');

          expect(timeTaken < 3000, true,
              reason: '${strategy['name']} should complete within 3 seconds');
        }
      });

      test('Coordinate Assignment Performance - 140 Nodes', () {
        print('\n=== 140 Node Graph - Coordinate Assignment Performance ===');

        final strategies = [
          {'strategy': CoordinateAssignment.DownRight, 'name': 'DownRight'},
          {'strategy': CoordinateAssignment.DownLeft, 'name': 'DownLeft'},
          {'strategy': CoordinateAssignment.UpRight, 'name': 'UpRight'},
          {'strategy': CoordinateAssignment.UpLeft, 'name': 'UpLeft'},
          {'strategy': CoordinateAssignment.Average, 'name': 'Average'},
        ];

        for (final strategy in strategies) {
          final graph = Graph();
          graph.inflateWithJson(exampleTreeWith140Nodes);

          for (var i = 0; i < graph.nodeCount(); i++) {
            graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
          }

          final configuration = SugiyamaConfiguration()
            ..nodeSeparation = 15
            ..levelSeparation = 15
            ..coordinateAssignment =
                strategy['strategy'] as CoordinateAssignment
            ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
            ..postStraighten = true;

          final algorithm = SugiyamaAlgorithm(configuration);

          final stopwatch = Stopwatch()..start();
          final size = algorithm.run(graph, 10, 10);
          final timeTaken = stopwatch.elapsed.inMilliseconds;

          print(
              '${strategy['name']}: ${timeTaken}ms - Layout size: $size - Nodes: ${graph.nodeCount()}');

          expect(timeTaken < 3000, true,
              reason: '${strategy['name']} should complete within 3 seconds');
        }
      });
    });

    test('PostStraighten Effect on Node Positioning', () {
      // Test with PostStraighten ON
      for (var i = 0; i < graph.nodeCount(); i++) {
        graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
      }

      final configurationOn = SugiyamaConfiguration()
        ..nodeSeparation = 15
        ..levelSeparation = 15
        ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
        ..postStraighten = false;

      final algorithmOn = SugiyamaAlgorithm(configurationOn);
      algorithmOn.run(graph, 10, 10);

      expect(graph.getNodeAtPosition(0).position, Offset(660.0, 10));
      expect(graph.getNodeAtPosition(6).position, Offset(1180.0, 815.0));
      expect(graph.getNodeUsingId(3).position, Offset(920.0, 125.0));
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
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
        ..postStraighten = true;

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

        SugiyamaAlgorithm(SugiyamaConfiguration()..postStraighten = true)
          ..run(graph, 10, 10);

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
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
        ..postStraighten = true;

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
  });
}
