import 'package:flutter/widgets.dart';
import 'package:graphview/GraphView.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Graph', () {

    test('Graph Node counts are correct', () {
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

      expect(graph.nodeCount(), 9);

      graph.removeNode(Node.Id('One'));
      graph.removeNode(Node.Id('Ten'));

      expect(graph.nodeCount(), 8);

      graph.addNode(Node.Id('Ten'));

      expect(graph.nodeCount(), 9);
    });

    test('Node Hash Implementation is performant', () {
      final graph  = Graph();

      var rows = 1000000;

      var integerNode = Node.Id(1);
      var stringNode = Node.Id("123");
      var stringNode2 = Node.Id("G9Q84H1R9-1619338713.000900");
      var widgetNode = Node.Id(Text("Lovely"));
      var widgetNode2 = Node.Id(Text("Lovely"));
      var doubleNode = Node.Id(5.6);

      var edge = graph.addEdge(integerNode, Node.Id(4));

      var node = doubleNode;
      var stopwatch = Stopwatch()..start();
      for (var i = 1; i <= rows; i++) {
        var hash = node.hashCode;

      }

      var timeTaken = stopwatch.elapsed.inMilliseconds;

      print('Timetaken $timeTaken ${node}');

      expect(timeTaken < 100, true);
    });


  });

}