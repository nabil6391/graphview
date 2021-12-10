part of graphview;

class EiglspergerNodeData extends SugiyamaNodeData{
  bool isPNode = false;

  @override
  String toString() {
    return 'SugiyamaNodeData{reversed: $reversed, isDummy: $isDummy, median: $median, layer: $layer}';
  }
}
