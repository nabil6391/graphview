import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void main() {
  group('GraphView Controller Tests', () {
    testWidgets('animateToNode centers the target node',
        (WidgetTester tester) async {
      // Setup graph
      final graph = Graph();
      final targetNode = Node.Id('target');
      targetNode.key = const ValueKey('target');
      final otherNode = Node.Id('other');

      graph.addEdge(targetNode, otherNode);

      final transformationController = TransformationController();
      final controller = GraphViewController(
          transformationController: transformationController);
      final configuration = BuchheimWalkerConfiguration();
      final algorithm = BuchheimWalkerAlgorithm(
          configuration, TreeEdgeRenderer(configuration));

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
      final expectedTranslationX =
          200 - nodeCenter.dx; // viewport_center_x - node_center_x
      final expectedTranslationY =
          300 - nodeCenter.dy; // viewport_center_y - node_center_y

      expect(finalMatrix.getTranslation().x, closeTo(expectedTranslationX, 5));
      expect(finalMatrix.getTranslation().y, closeTo(expectedTranslationY, 5));
    });

    testWidgets('animateToNode handles non-existent node gracefully',
        (WidgetTester tester) async {
      final graph = Graph();
      final node = Node.Id('exists');
      graph.nodes.add(node);

      final transformationController = TransformationController();
      final controller = GraphViewController(
          transformationController: transformationController);
      final algorithm = BuchheimWalkerAlgorithm(BuchheimWalkerConfiguration(),
          TreeEdgeRenderer(BuchheimWalkerConfiguration()));

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

  group('Collapse Tests', () {
    late Graph graph;
    late GraphViewController controller;

    setUp(() {
      graph = Graph();
      controller = GraphViewController();
    });

    // Helper function to create a graph with multiple branches
    Graph createComplexGraph() {
      final g = Graph();

      final root = Node.Id(0);
      final branch1 = Node.Id(1);
      final branch2 = Node.Id(2);
      final leaf1 = Node.Id(3);
      final leaf2 = Node.Id(4);
      final leaf3 = Node.Id(5);
      final leaf4 = Node.Id(6);

      g.addEdge(root, branch1);
      g.addEdge(root, branch2);
      g.addEdge(branch1, leaf1);
      g.addEdge(branch1, leaf2);
      g.addEdge(branch2, leaf3);
      g.addEdge(branch2, leaf4);

      return g;
    }

    test('Complex graph - multiple branches', () {
      final g = createComplexGraph();
      final root = g.getNodeAtPosition(0);

      controller.collapseNode(g, root);

      final edges = controller.getCollapsingEdges(g);

      // Should get all 6 edges (root->branch1, root->branch2, branch1->leaf1, branch1->leaf2, branch2->leaf3, branch2->leaf4)
      expect(edges.length, 6);
    });

    test('Nested collapse preserves original hide relationships', () {
      final graph = Graph();
      final parent = Node.Id(0);
      final child = Node.Id(1);
      final grandchild = Node.Id(2);

      graph.addEdge(parent, child);
      graph.addEdge(child, grandchild);

      final controller = GraphViewController();

      // Step 1: Collapse child
      controller.collapseNode(graph, child);

      expect(controller.isNodeVisible(graph, parent), true);
      expect(controller.isNodeVisible(graph, child), true);
      expect(controller.isNodeVisible(graph, grandchild), false);
      expect(
          controller.hiddenBy[grandchild], child); // grandchild hidden by child

      // Step 2: Collapse parent
      controller.collapseNode(graph, parent);

      expect(controller.isNodeVisible(graph, parent), true);
      expect(controller.isNodeVisible(graph, child), false);
      expect(controller.isNodeVisible(graph, grandchild), false);
      expect(controller.hiddenBy[child], parent); // child hidden by parent
      expect(controller.hiddenBy[grandchild],
          child); // grandchild STILL hidden by child!

      // Step 3: Get collapsing edges for parent
      controller.collapsedNode = parent;
      final parentEdges = controller.getCollapsingEdges(graph);

      // Should only include parent -> child, NOT child -> grandchild
      expect(parentEdges.length, 1);
      expect(parentEdges.first.source, parent);
      expect(parentEdges.first.destination, child);

      // Step 4: Expand parent
      controller.expandNode(graph, parent);

      expect(controller.isNodeVisible(graph, parent), true);
      expect(controller.isNodeVisible(graph, child), true);
      expect(
          controller.isNodeVisible(graph, grandchild), false); // Still hidden!
      expect(controller.hiddenBy[grandchild], child); // Still hidden by child!

      // Step 5: Expand child
      controller.expandNode(graph, child);

      expect(controller.isNodeVisible(graph, parent), true);
      expect(controller.isNodeVisible(graph, child), true);
      expect(controller.isNodeVisible(graph, grandchild), true); // Now visible!
      expect(controller.hiddenBy.containsKey(grandchild), false);
    });
  });
}
