import 'package:flutter/material.dart';

class BrandCheckPainter extends CustomPainter {
  const BrandCheckPainter(
    this.progress, {
    this.color = const Color(0xff0f2a28),
    this.width = 4,
  });
  final Color color;
  final double width;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final path = Path()
      ..moveTo(5, 12)
      ..lineTo(10, 17)
      ..lineTo(19, 6);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, 40 * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(BrandCheckPainter old) =>
      old.progress != progress || old.color != color || old.width != width;
}
