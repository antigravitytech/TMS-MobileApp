import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import 'kit.dart';

/// Radial confetti burst (`burst2`) with a floating "+N pts" (`ptsUp`).
class KitBurst extends StatelessWidget {
  const KitBurst({super.key, required this.label});
  final String label;
  static const _colors = [
    DesignColor.purple,
    DesignColor.teal,
    DesignColor.amber,
    DesignColor.rose,
    DesignColor.blue,
    Color(0xfff3f5fe),
  ];
  @override
  Widget build(BuildContext c) => IgnorePointer(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1600),
      builder: (_, t, _) {
        final burst = DesignMotion.curve.transform((t / .69).clamp(0, 1));
        final rise = (t * 1.6).clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _BurstPainter(burst, _colors)),
            ),
            Positioned(
              right: 28,
              top: 120 - 40 * DesignMotion.curve.transform(t),
              child: Opacity(
                opacity: t < .3 ? t / .3 : 1 - (t - .3) / .7,
                child: Transform.scale(
                  scale: .6 + .5 * Curves.easeOut.transform(rise),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: KitColor.submitted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.t, this.colors);
  final double t;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final origin = Offset(size.width / 2, size.height * .4);
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2, r = 70.0 + (i % 3) * 28;
      canvas.save();
      canvas.translate(
        origin.dx + math.cos(a) * r * t,
        origin.dy + math.sin(a) * r * t,
      );
      canvas.rotate((160 + i * 41) * math.pi / 180 * t);
      canvas.scale(.4 + .6 * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4.5, -7, 9, 14),
          const Radius.circular(2),
        ),
        Paint()..color = colors[i % colors.length].withValues(alpha: 1 - t),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
