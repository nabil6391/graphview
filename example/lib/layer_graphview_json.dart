import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class LayerGraphPageFromJson extends StatefulWidget {
  @override
  _LayerGraphPageFromJsonState createState() => _LayerGraphPageFromJsonState();
}

class _LayerGraphPageFromJsonState extends State<LayerGraphPageFromJson> {
  var  json =   {
    "edges": [
      {"from": "651372822", "to": "780273411"},
      {"from": "780273411", "to": "347969226"},
      {"from": "347969226", "to": "157648240"},
      {"from": "157648240", "to": "676569359"},
      {"from": "676569359", "to": "91606809"},
      {"from": "676569359", "to": "154477528"},
      {"from": "676569359", "to": "843017499"},
      {"from": "843017499", "to": "983981562"},
      {"from": "843017499", "to": "504040588"},
      {"from": "504040588", "to": "446062329"},
      {"from": "446062329", "to": "622974985"},
      {"from": "622974985", "to": "1044667060"},
      {"from": "622974985", "to": "556331086"},
      {"from": "556331086", "to": "995470137"},
      {"from": "995470137", "to": "1056219149"},
      {"from": "1056219149", "to": "239427950"},
      {"from": "995470137", "to": "239427950"},
      {"from": "995470137", "to": "175942639"},
      {"from": "175942639", "to": "239427950"},
      {"from": "995470137", "to": "914018177"},
      {"from": "914018177", "to": "239427950"},
      {"from": "556331086", "to": "776412718"},
      {"from": "776412718", "to": "311423239"},
      {"from": "311423239", "to": "71054174"},
      {"from": "71054174", "to": "436868910"},
      {"from": "436868910", "to": "86163114"},
      {"from": "86163114", "to": "876219077"},
      {"from": "436868910", "to": "385178969"},
      {"from": "385178969", "to": "18115125"},
      {"from": "71054174", "to": "869070735"},
      {"from": "776412718", "to": "71054174"},
      {"from": "776412718", "to": "978694637"},
      {"from": "978694637", "to": "71054174"},
      {"from": "776412718", "to": "481786088"},
      {"from": "481786088", "to": "71054174"},
      {"from": "622974985", "to": "657744632"},
      {"from": "657744632", "to": "995470137"},
      {"from": "657744632", "to": "776412718"},
      {"from": "622974985", "to": "398317434"},
      {"from": "843017499", "to": "441827615"},
      {"from": "843017499", "to": "345074369"},
      {"from": "345074369", "to": "983981562"},
      {"from": "345074369", "to": "504040588"},
      {"from": "345074369", "to": "441827615"},
      {"from": "843017499", "to": "1038969179"},
      {"from": "1038969179", "to": "983981562"},
      {"from": "1038969179", "to": "504040588"},
      {"from": "1038969179", "to": "441827615"},
      {"from": "1038969179", "to": "345074369"},
      {"from": "676569359", "to": "582216004"},
      {"from": "582216004", "to": "983981562"},
      {"from": "582216004", "to": "853366903"},
      {"from": "853366903", "to": "549040211"},
      {"from": "549040211", "to": "438987595"},
      {"from": "438987595", "to": "1044667060"},
      {"from": "438987595", "to": "927647245"},
      {"from": "927647245", "to": "995470137"},
      {"from": "927647245", "to": "286211157"},
      {"from": "286211157", "to": "466182692"},
      {"from": "466182692", "to": "724424756"},
      {"from": "724424756", "to": "739317534"},
      {"from": "739317534", "to": "315526883"},
      {"from": "724424756", "to": "869070735"},
      {"from": "286211157", "to": "724424756"},
      {"from": "286211157", "to": "175042175"},
      {"from": "175042175", "to": "724424756"},
      {"from": "286211157", "to": "567113513"},
      {"from": "567113513", "to": "724424756"},
      {"from": "438987595", "to": "625227999"},
      {"from": "625227999", "to": "995470137"},
      {"from": "625227999", "to": "286211157"},
      {"from": "438987595", "to": "398317434"},
      {"from": "582216004", "to": "441827615"},
      {"from": "582216004", "to": "306330186"},
      {"from": "306330186", "to": "983981562"},
      {"from": "306330186", "to": "853366903"},
      {"from": "306330186", "to": "441827615"},
      {"from": "582216004", "to": "476307185"},
      {"from": "476307185", "to": "983981562"},
      {"from": "476307185", "to": "853366903"},
      {"from": "476307185", "to": "441827615"},
      {"from": "157648240", "to": "1031140514"},
      {"from": "1031140514", "to": "983981562"},
      {"from": "1031140514", "to": "329379632"},
      {"from": "1031140514", "to": "441827615"},
      {"from": "1031140514", "to": "722519336"},
      {"from": "722519336", "to": "983981562"},
      {"from": "722519336", "to": "329379632"},
      {"from": "722519336", "to": "441827615"},
      {"from": "722519336", "to": "431136131"},
      {"from": "431136131", "to": "329379632"},
      {"from": "1031140514", "to": "431136131"},
      {"from": "347969226", "to": "91606809"},
      {"from": "347969226", "to": "154477528"},
      {"from": "347969226", "to": "843017499"},
      {"from": "347969226", "to": "582216004"},
      {"from": "780273411", "to": "383221931"}
    ],
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Wrap(
              children: [
                Container(
                  width: 100,
                  child: TextFormField(
                    initialValue: builder.nodeSeparation.toString(),
                    decoration: InputDecoration(labelText: 'Node Separation'),
                    onChanged: (text) {
                      builder.nodeSeparation = int.tryParse(text) ?? 100;
                      this.setState(() {});
                    },
                  ),
                ),
                Container(
                  width: 100,
                  child: TextFormField(
                    initialValue: builder.levelSeparation.toString(),
                    decoration: InputDecoration(labelText: 'Level Separation'),
                    onChanged: (text) {
                      builder.levelSeparation = int.tryParse(text) ?? 100;
                      this.setState(() {});
                    },
                  ),
                ),
                Container(
                  width: 100,
                  child: TextFormField(
                    initialValue: builder.orientation.toString(),
                    decoration: InputDecoration(labelText: 'Orientation'),
                    onChanged: (text) {
                      builder.orientation = int.tryParse(text) ?? 100;
                      this.setState(() {});
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                  constrained: false,
                  boundaryMargin: EdgeInsets.all(100),
                  minScale: 0.01,
                  maxScale: 5.6,
                  child: GraphView(
                    graph: graph,
                    algorithm: SugiyamaAlgorithm(builder),
                    paint: Paint()
                      ..color = Colors.green
                      ..strokeWidth = 1
                      ..style = PaintingStyle.stroke,
                    builder: (Node node) {
                      // I can decide what widget should be shown here based on the id
                      var a = node.key!.value;
                      return rectangleWidget(a, node);
                    },
                  )),
            ),
          ],
        ));
  }

  Widget rectangleWidget(String? a, Node node) {
    return Container(
      color: Colors.amber,
      child: InkWell(
        onTap: () {
          print('clicked');
        },
        child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: Colors.blue[100]!, spreadRadius: 1),
              ],
            ),
            child: Text('${a}')),
      ),
    );
  }

  final Graph graph = Graph()
    ..isTree = true;
  @override
  void initState() {
    var edges = json['edges']!;
    edges.forEach((element) {
      var fromNodeId = element['from'];
      var toNodeId = element['to'];
      graph.addEdge(Node.Id(fromNodeId), Node.Id(toNodeId));
    });

    builder
      ..nodeSeparation = (15)
      ..levelSeparation = (15)
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;
    }

  }

  var builder = SugiyamaConfiguration();

