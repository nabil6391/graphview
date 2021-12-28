import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:flutter_test/flutter_test.dart';

const itemHeight = 100.0;
const itemWidth = 100.0;

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

      expect(graph.getNodeAtPosition(0).position, Offset(585, 10));
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

    var  json = {"edges":[{"from":"7045321","to":"308264215"},{"from":"308264215","to":"205893853"},{"from":"205893853","to":"673966248"},{"from":"673966248","to":"358204164"},{"from":"358204164","to":"215888392"},{"from":"215888392","to":"403621992"},{"from":"215888392","to":"777909510"},{"from":"777909510","to":"100213815"},{"from":"100213815","to":"499504374"},{"from":"499504374","to":"855703404"},{"from":"499504374","to":"991104907"},{"from":"991104907","to":"374555325"},{"from":"991104907","to":"58236163"},{"from":"991104907","to":"1051662797"},{"from":"1051662797","to":"523457656"},{"from":"1051662797","to":"178236248"},{"from":"178236248","to":"403818044"},{"from":"403818044","to":"633692579"},{"from":"403818044","to":"326876433"},{"from":"178236248","to":"294992198"},{"from":"178236248","to":"207728643"},{"from":"207728643","to":"474861525"},{"from":"207728643","to":"704015142"},{"from":"704015142","to":"891912594"},{"from":"704015142","to":"93790829"},{"from":"704015142","to":"713878610"},{"from":"704015142","to":"568109301"},{"from":"100213815","to":"298138012"},{"from":"298138012","to":"1051662797"},{"from":"777909510","to":"344277619"},{"from":"344277619","to":"311541390"},{"from":"311541390","to":"761787449"},{"from":"761787449","to":"30973213"},{"from":"30973213","to":"523457656"},{"from":"30973213","to":"178236248"},{"from":"761787449","to":"259733602"},{"from":"311541390","to":"128821445"},{"from":"344277619","to":"1003131136"},{"from":"1003131136","to":"130000569"},{"from":"1003131136","to":"319536467"},{"from":"319536467","to":"299942125"},{"from":"299942125","to":"178926206"},{"from":"299942125","to":"675835322"},{"from":"299942125","to":"1000135767"},{"from":"319536467","to":"483940059"},{"from":"483940059","to":"497866879"},{"from":"483940059","to":"606660618"},{"from":"483940059","to":"841482899"},{"from":"358204164","to":"963021319"},{"from":"963021319","to":"130000569"},{"from":"963021319","to":"319536467"},{"from":"358204164","to":"803634418"},{"from":"803634418","to":"142291521"},{"from":"142291521","to":"525361131"},{"from":"525361131","to":"422007713"},{"from":"422007713","to":"184596308"},{"from":"422007713","to":"1020140270"},{"from":"422007713","to":"779910731"},{"from":"525361131","to":"859310299"},{"from":"859310299","to":"514613187"},{"from":"514613187","to":"680752017"},{"from":"680752017","to":"1058283666"},{"from":"680752017","to":"887688252"},{"from":"680752017","to":"717256682"},{"from":"717256682","to":"409719617"},{"from":"409719617","to":"1014464856"},{"from":"1014464856","to":"773448863"},{"from":"773448863","to":"988347957"},{"from":"773448863","to":"152738454"},{"from":"773448863","to":"338899146"},{"from":"1014464856","to":"629986173"},{"from":"629986173","to":"773448863"},{"from":"629986173","to":"835742723"},{"from":"1014464856","to":"835742723"},{"from":"409719617","to":"81570852"},{"from":"717256682","to":"136164004"},{"from":"136164004","to":"852978894"},{"from":"852978894","to":"344862780"},{"from":"344862780","to":"1001389664"},{"from":"1001389664","to":"404010795"},{"from":"1001389664","to":"644174136"},{"from":"644174136","to":"979597620"},{"from":"979597620","to":"267068484"},{"from":"979597620","to":"660658782"},{"from":"644174136","to":"1041729484"},{"from":"1041729484","to":"184754595"},{"from":"184754595","to":"564383463"},{"from":"564383463","to":"328736689"},{"from":"564383463","to":"371898357"},{"from":"371898357","to":"1035929373"},{"from":"1035929373","to":"619697312"},{"from":"619697312","to":"64229994"},{"from":"619697312","to":"865071585"},{"from":"619697312","to":"834626072"},{"from":"1035929373","to":"201892784"},{"from":"201892784","to":"160374239"},{"from":"201892784","to":"925759772"},{"from":"371898357","to":"601412432"},{"from":"184754595","to":"371898357"},{"from":"1041729484","to":"371898357"},{"from":"344862780","to":"409719617"},{"from":"852978894","to":"63704729"},{"from":"136164004","to":"293710340"},{"from":"514613187","to":"136164004"},{"from":"859310299","to":"81570852"},{"from":"859310299","to":"1014464856"},{"from":"142291521","to":"985700044"},{"from":"142291521","to":"756415350"},{"from":"803634418","to":"420237319"},{"from":"420237319","to":"450548638"},{"from":"420237319","to":"210548489"},{"from":"210548489","to":"809729654"},{"from":"210548489","to":"736196011"},{"from":"736196011","to":"763132131"},{"from":"763132131","to":"139733908"},{"from":"139733908","to":"141077435"},{"from":"139733908","to":"601580192"},{"from":"601580192","to":"29466216"},{"from":"601580192","to":"530702767"},{"from":"530702767","to":"1181832"},{"from":"530702767","to":"514613187"},{"from":"530702767","to":"1014464856"},{"from":"139733908","to":"530702767"},{"from":"763132131","to":"805599981"},{"from":"805599981","to":"596402985"},{"from":"805599981","to":"207631270"},{"from":"207631270","to":"528636695"},{"from":"207631270","to":"142291521"},{"from":"805599981","to":"148019367"},{"from":"148019367","to":"894038421"},{"from":"148019367","to":"544426319"},{"from":"148019367","to":"878212306"},{"from":"878212306","to":"94541671"},{"from":"878212306","to":"1007715424"},{"from":"1007715424","to":"258386700"},{"from":"1007715424","to":"546819439"},{"from":"546819439","to":"836825089"},{"from":"836825089","to":"16287329"},{"from":"836825089","to":"256254716"},{"from":"256254716","to":"631230382"},{"from":"631230382","to":"900886483"},{"from":"631230382","to":"133436503"},{"from":"256254716","to":"751624200"},{"from":"836825089","to":"716757473"},{"from":"546819439","to":"470041669"},{"from":"546819439","to":"180888016"},{"from":"736196011","to":"901547914"},{"from":"901547914","to":"425184961"},{"from":"425184961","to":"760673978"},{"from":"760673978","to":"825228914"},{"from":"760673978","to":"530702767"},{"from":"425184961","to":"955125232"},{"from":"955125232","to":"167653392"},{"from":"955125232","to":"530702767"},{"from":"901547914","to":"530702767"},{"from":"210548489","to":"640144001"},{"from":"640144001","to":"135966238"},{"from":"640144001","to":"959156288"},{"from":"803634418","to":"358204164"},{"from":"673966248","to":"803634418"},{"from":"308264215","to":"1039602752"},{"from":"1039602752","to":"673966248"}]
    };

    final graph  = Graph();

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

    var algorithm =  SugiyamaAlgorithm(_configuration);

    for(var i = 0 ; i < graph.nodeCount(); i++ ) {
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

  test('Sugiyama Performance for 100 nodes to be less than 2.5s', () {
    final graph  = Graph();

    int rows = 100;

    for(int i = 1; i <= rows; i++) {
      for(int j = 1; j <= i; j++) {
        graph.addEdge(Node.Id(i), Node.Id(j));
      }
    }

    final _configuration = SugiyamaConfiguration()
      ..nodeSeparation = 15
      ..levelSeparation = 15
      ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

    var algorithm =  SugiyamaAlgorithm(_configuration);

    for(var i = 0 ; i < graph.nodeCount(); i++ ) {
      graph.getNodeAtPosition(i).size = Size(itemWidth, itemHeight);
    }

    var stopwatch = Stopwatch()..start();
    var size = algorithm.run(graph, 10, 10);
    var timeTaken = stopwatch.elapsed.inMilliseconds;

    print('Timetaken $timeTaken ${graph.nodeCount()}');

    expect(timeTaken < 2500, true);
  });
}
