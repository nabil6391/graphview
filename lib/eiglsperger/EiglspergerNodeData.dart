part of graphview;

class EiglspergerNodeData extends SugiyamaNodeData{
  bool isPNode = false;
  bool isQNode = false;
  bool isContainer = false;



  @override
  String toString() {
    return 'SugiyamaNodeData{reversed: $reversed, isDummy: $isDummy, median: $median, layer: $layer}';
  }
}
