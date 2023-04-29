part of graphview;

abstract class EdgeRenderer {
  void render(Canvas canvas, Graph graph, Paint paint);
}

void _drawDottedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
  var dottedPaint = Paint()
    ..color = paint.color
    ..strokeWidth = paint.strokeWidth
    ..style = PaintingStyle.stroke;

  var distance = (end - start).distance;
  var dashLength = 10;
  var gapLength = 10;
  var totalLength = dashLength + gapLength;

  final path = Path()..moveTo(start.dx, start.dy);
  for (var i = 0; i < distance; i += totalLength) {
    path.lineTo(start.dx + (i + dashLength) * (end.dx - start.dx) / distance,
        start.dy + (i + dashLength) * (end.dy - start.dy) / distance);
    path.moveTo(start.dx + (i + totalLength) * (end.dx - start.dx) / distance,
        start.dy + (i + totalLength) * (end.dy - start.dy) / distance);
  }

  canvas.drawPath(path, dottedPaint);
}
