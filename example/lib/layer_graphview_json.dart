import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class LayerGraphPageFromJson extends StatefulWidget {
  @override
  _LayerGraphPageFromJsonState createState() => _LayerGraphPageFromJsonState();
}

class _LayerGraphPageFromJsonState extends State<LayerGraphPageFromJson> {
  var  json =   {
    "edges": [
      {
        "from": "254022114",
        "to": "435737192"
      },
      {
        "from": "102061118",
        "to": "435737192"
      },
      {
        "from": "864374573",
        "to": "676874082"
      },
      {
        "from": "564905731",
        "to": "864374573"
      },
      {
        "from": "435737192",
        "to": "864374573"
      },
      {
        "from": "435737192",
        "to": "183014792"
      },
      {
        "from": "435737192",
        "to": "222855694"
      },
      {
        "from": "864342115",
        "to": "652678503"
      },
      {
        "from": "864342115",
        "to": "469600377"
      },
      {
        "from": "676874082",
        "to": "684761235"
      },
      {
        "from": "864374573",
        "to": "864342115"
      },
      {
        "from": "564905731",
        "to": "176177853"
      },
      {
        "from": "564905731",
        "to": "983393593"
      },
      {
        "from": "564905731",
        "to": "818531897"
      },
      {
        "from": "584192116",
        "to": "102061118"
      },
      {
        "from": "598554018",
        "to": "102061118"
      },
      {
        "from": "207392962",
        "to": "584192116"
      },
      {
        "from": "161904647",
        "to": "598554018"
      }
    ]
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
                Container(
                  width: 100,
                  child: Column(
                    children: [
                      Text('Alignment'),
                      DropdownButton<CoordinateAssignment>(
                        value: builder.coordinateAssignment,
                        items: CoordinateAssignment.values.map((coordinateAssignment) {
                          return DropdownMenuItem<CoordinateAssignment>(
                            value: coordinateAssignment,
                            child: Text(coordinateAssignment.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            builder.coordinateAssignment = value!;
                          });
                        },
                      ),
                    ],
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

