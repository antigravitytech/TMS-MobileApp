import 'package:flutter/material.dart';

class DesignHeroGradient extends CustomPainter {
  const DesignHeroGradient();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    void drawEllipse(Offset center, Size radius, RadialGradient gradient) {
      canvas.save();
      canvas.translate(center.dx * size.width, center.dy * size.height);
      canvas.scale(radius.width * size.width, radius.height * size.height);
      // Draw out to the edges of the card so the last stop fills the corners.
      final fill = Rect.fromLTRB(
        -center.dx / radius.width,
        -center.dy / radius.height,
        (1 - center.dx) / radius.width,
        (1 - center.dy) / radius.height,
      );
      canvas.drawRect(
        fill,
        Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: Offset.zero, radius: .5),
          ),
      );
      canvas.restore();
    }

    canvas.drawRect(bounds, Paint()..color = const Color(0xff1b1e45));
    drawEllipse(
      const Offset(.9, -.1),
      const Size(1.3, .9),
      const RadialGradient(
        radius: 1,
        colors: [
          Color(0xff4a4fa8),
          Color(0xff353b80),
          Color(0xff262a60),
          Color(0xff1b1e45),
        ],
        stops: [0, .22, .48, .8],
      ),
    );
    drawEllipse(
      const Offset(.1, 1.1),
      const Size(.6, .5),
      const RadialGradient(
        radius: 1,
        colors: [Color(0x332bb3a3), Color(0x002bb3a3)],
        stops: [0, .7],
      ),
    );
  }

  @override
  bool shouldRepaint(DesignHeroGradient oldDelegate) => false;
}
