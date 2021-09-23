import 'package:graphview/GraphView.dart';
import 'package:test/test.dart';

void main() {
  group('Graph', () {

    test('value should be incremented', () {
      final graph  = Graph();
      var node1 = Node.Id('One');
      var node2 = Node.Id('Two');
      var node3 = Node.Id('Three');
      var node4 = Node.Id('Four');
      var node5 = Node.Id('Five');
      var node6 = Node.Id('Six');
      var node7 = Node.Id('Seven');
      var node8 = Node.Id('Eight');
      var node9 = Node.Id('Nine');

      graph.addEdge(node1, node2);
      graph.addEdge(node1, node4);
      graph.addEdge(node2, node3);
      graph.addEdge(node2, node5);
      graph.addEdge(node3, node6);
      graph.addEdge(node4, node5);
      graph.addEdge(node4, node7);
      graph.addEdge(node5, node6);
      graph.addEdge(node5, node8);
      graph.addEdge(node6, node9);
      graph.addEdge(node7, node8);
      graph.addEdge(node8, node9);

      expect(graph.nodeCount(), 0);
    });


  });
}