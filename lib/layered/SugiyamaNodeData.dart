part of graphview;

class SugiyamaNodeData {
  Set<Node> reversed = {};
  bool isDummy = false;
  int median = -1;
  int layer = -1;

  bool get isReversed => reversed.isNotEmpty;

  @override
  String toString() {
    return 'SugiyamaNodeData{reversed: $reversed, isDummy: $isDummy, median: $median, layer: $layer}';
  }
}
