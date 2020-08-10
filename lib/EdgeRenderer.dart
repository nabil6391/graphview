library graphview;

import 'dart:ui';

import 'Graph.dart';

abstract class EdgeRenderer {
  void render(Canvas canvas, Graph graph, Paint paint);
}
