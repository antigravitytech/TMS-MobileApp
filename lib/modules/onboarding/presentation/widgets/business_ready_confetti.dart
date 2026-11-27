part of '../business_ready_screen.dart';

class _Confetti extends CustomPainter {
  const _Confetti(this.elapsed);
  final double elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    const pieces = [
      (.12, 40.0, 0, DesignColor.purple),
      (.28, 10.0, 200, Color(0xff2bb3a3)),
      (.46, 30.0, 100, DesignColor.amber),
      (.64, 0.0, 300, Color(0xffc2449b)),
      (.80, 36.0, 150, DesignColor.purple),
      (.90, 6.0, 350, DesignColor.blue),
    ];
    for (final (x, y, delay, color) in pieces) {
      final progress = ((elapsed - delay) / 2400).clamp(0.0, 1.0);
      if (progress == 0 || progress == 1) continue;
      final eased = DesignMotion.curve.transform(progress);
      final opacity = eased < .2 ? eased / .2 : (1 - eased) / .8;
      canvas.save();
      canvas.translate(size.width * x, y - 60 + 300 * eased);
      canvas.rotate(320 * math.pi / 180 * eased);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 9, 14),
          const Radius.circular(2),
        ),
        Paint()..color = color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti oldDelegate) => oldDelegate.elapsed != elapsed;
}
