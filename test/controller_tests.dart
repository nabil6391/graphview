import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void main() {
  group('GraphView Controller Tests', () {
    testWidgets('animateToNode centers the target node', (WidgetTester tester) async {
      // Setup graph
      final graph = Graph();
      final targetNode = Node.Id('target');
      targetNode.key = const ValueKey('target');
      final otherNode = Node.Id('other');

      graph.addEdge(targetNode, otherNode);

      final transformationController = TransformationController();
      final controller = GraphViewController(transformationController: transformationController);
      final configuration = BuchheimWalkerConfiguration();
      final algorithm = BuchheimWalkerAlgorithm(configuration, TreeEdgeRenderer(configuration));

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: GraphView.builder(
                graph: graph,
                algorithm: algorithm,
                controller: controller,
                builder: (node) => Container(
                  width: 100,
                  height: 50,
                  color: Colors.blue,
                  child: Text(node.key?.value ?? ''),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get the actual position of target node after algorithm runs
      final actualNodePosition = targetNode.position;
      final nodeCenter = Offset(
        actualNodePosition.dx + targetNode.width / 2,
        actualNodePosition.dy + targetNode.height / 2,
      );

      // Get initial transformation
      final initialMatrix = transformationController.value;

      // Animate to target node
      controller.animateToNode(const ValueKey('target'));

      // Let animation complete
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify transformation changed
      final finalMatrix = transformationController.value;
      expect(finalMatrix, isNot(equals(initialMatrix)));

      // With viewport size 400x600, center should be at (200, 300)
      // Expected translation should center the node at viewport center
      final expectedTranslationX = 200 - nodeCenter.dx; // viewport_center_x - node_center_x
      final expectedTranslationY = 300 - nodeCenter.dy; // viewport_center_y - node_center_y

      expect(finalMatrix.getTranslation().x, closeTo(expectedTranslationX, 5));
      expect(finalMatrix.getTranslation().y, closeTo(expectedTranslationY, 5));
    });

    testWidgets('animateToNode handles non-existent node gracefully', (WidgetTester tester) async {
      final graph = Graph();
      final node = Node.Id('exists');
      graph.nodes.add(node);

      final transformationController = TransformationController();
      final controller = GraphViewController(transformationController: transformationController);
      final algorithm = BuchheimWalkerAlgorithm(
          BuchheimWalkerConfiguration(),
          TreeEdgeRenderer(BuchheimWalkerConfiguration())
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GraphView.builder(
            graph: graph,
            algorithm: algorithm,
            controller: controller,
            builder: (node) => Container(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialMatrix = transformationController.value;

      // Try to animate to non-existent node
      controller.animateToNode(const ValueKey('nonexistent'));
      await tester.pumpAndSettle();

      // Matrix should remain unchanged
      final finalMatrix = transformationController.value;
      expect(finalMatrix, equals(initialMatrix));
    });
  });
}