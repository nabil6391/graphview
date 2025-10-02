import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void main() {
  group('GraphView Performance Tests', () {

    testWidgets('hitTest performance with 1000+ nodes less than 20s', (WidgetTester tester) async {
      final graph = _createLargeGraph(1000);

      final _configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150)
        ..subtreeSeparation = (150)
        ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

      var algorithm = BuchheimWalkerAlgorithm(
          _configuration, TreeEdgeRenderer(_configuration));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GraphView.builder(
            graph: graph,
            algorithm: algorithm,
            builder: (Node node) => Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(node.key.toString())),
            ),
          ),
        ),
      ));

      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<RenderCustomLayoutBox>(
          find.byType(GraphViewWidget)
      );

      final stopwatch = Stopwatch()..start();

      // Test multiple hit tests at different positions
      for (var i = 0; i < 10; i++) {
        final result = BoxHitTestResult();
        renderBox.hitTest(result, position: Offset(i * 10.0, i * 10.0));
      }

      stopwatch.stop();
      final hitTestTime = stopwatch.elapsedMilliseconds;

      print('HitTest time for 1000 nodes (10 tests): ${hitTestTime}ms');
      expect(hitTestTime, lessThan(20), reason: 'HitTest should complete in under 10ms');
    });

    testWidgets('paint performance with 1000+ nodes', (WidgetTester tester) async {
      final graph = _createLargeGraph(1000);

      final _configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150)
        ..subtreeSeparation = (150)
        ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

      var algorithm = BuchheimWalkerAlgorithm(
          _configuration, TreeEdgeRenderer(_configuration));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GraphView.builder(
            graph: graph,
            algorithm: algorithm,
            builder: (Node node) => Container(
              width: 30,
              height: 30,
              color: Colors.red,
            ),
          ),
        ),
      ));

      final stopwatch = Stopwatch()..start();

      // Trigger multiple repaints
      for (var i = 0; i < 10; i++) {
        await tester.pump();
      }

      stopwatch.stop();
      final paintTime = stopwatch.elapsedMilliseconds;

      print('Paint time for 1000 nodes (10 repaints): ${paintTime}ms');
      expect(paintTime, lessThan(50), reason: 'Paint should complete in under 50ms');
    });

    test('algorithm run performance with 1000+ nodes', () {
      final graph = _createLargeGraph(1000);

      final _configuration = BuchheimWalkerConfiguration()
        ..siblingSeparation = (100)
        ..levelSeparation = (150)
        ..subtreeSeparation = (150)
        ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

      var algorithm = BuchheimWalkerAlgorithm(
          _configuration, TreeEdgeRenderer(_configuration));

      final stopwatch = Stopwatch()..start();

      algorithm.run(graph, 0, 0);

      stopwatch.stop();
      final algorithmTime = stopwatch.elapsedMilliseconds;

      print('Algorithm run time for 1000 nodes: ${algorithmTime}ms');
      expect(algorithmTime, lessThan(10), reason: 'Algorithm should complete in under 10 milisecond');
    });

  });
}

/// Creates a large graph with connected nodes for performance testing
Graph _createLargeGraph(int n) {
  final graph = Graph();
  // Create nodes
  final nodes = List.generate(n, (i) => Node.Id(i + 1));

// Generate tree edges using a queue-based approach
  var currentChild = 1; // Start from node 1 (node 0 is root)

  for (var i = 0; i < n && currentChild < n; i++) {
    final children = (i < n ~/ 3) ? 3 : 2;

    for (var j = 0; j < children && currentChild < n; j++) {
      graph.addEdge(nodes[i], nodes[currentChild]);
      currentChild++;
    }
  }

  return graph;
}