import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../shared/design/brand_check_painter.dart';
import '../../../../shared/design/design_tokens.dart';

double splashPhase(double ms, double start, double length, Curve curve) =>
    curve.transform(((ms - start) / length).clamp(0.0, 1.0));

class SplashAtmosphere extends StatelessWidget {
  const SplashAtmosphere({super.key, required this.ms});
  final double ms;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      LayoutBuilder(
        builder: (context, bounds) {
          return OverflowBox(
            alignment: Alignment.center,
            minWidth: 980,
            maxWidth: 980,
            minHeight: 980,
            maxHeight: 980,
            child: Transform.translate(
              offset: Offset(0, -.04 * bounds.maxHeight),
              child: Transform.rotate(
                angle: ms / 9000 * 2 * math.pi,
                child: Opacity(
                  opacity: .55 * splashPhase(ms, 0, 1200, Curves.ease),
                  child: const RepaintBoundary(
                    child: CustomPaint(
                      painter: _AtmospherePainter(),
                      size: Size.square(980),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      const RepaintBoundary(child: CustomPaint(painter: _GrainPainter())),
      CustomPaint(painter: _OrbitPainter(ms)),
    ],
  );
}

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.saveLayer(
      null,
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
    );
    final bounds = Rect.fromCircle(center: center, radius: 310);
    canvas.drawCircle(
      center,
      310,
      Paint()
        ..shader = const SweepGradient(
          transform: GradientRotation(-math.pi / 2),
          colors: [
            DesignColor.purple,
            Color(0xff2bb3a3),
            Color(0xffc2449b),
            Color(0xff353b80),
            DesignColor.purple,
          ],
        ).createShader(bounds),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AtmospherePainter old) => false;
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / 4).ceil(), rows = (size.height / 4).ceil();
    final points = Float32List(cols * rows * 2);
    var i = 0;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        points[i++] = x * 4 + 2;
        points[i++] = y * 4 + 2;
      }
    }
    canvas.drawRawPoints(
      ui.PointMode.points,
      points,
      Paint()
        ..color = const Color(0x08ffffff)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false;
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter(this.ms);
  final double ms;
  static const dots = [
    (Offset(0, -120), DesignColor.purple),
    (Offset(120, 0), DesignColor.teal),
    (Offset(0, 120), DesignColor.amber),
    (Offset(-120, 0), DesignColor.rose),
    (Offset(85, -85), DesignColor.blue),
    (Offset(-85, 85), DesignColor.green),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    if (ms >= 2400) return;
    const curve = Cubic(.6, 0, .3, 1);
    final scale =
        splashPhase(ms, 0, 600, curve) - splashPhase(ms, 1800, 600, curve);
    canvas.save();
    canvas.translate(size.width / 2, size.height * .46);
    canvas.rotate(
      2 * math.pi * splashPhase(ms, 0, 2400, const Cubic(.5, 0, .5, 1)),
    );
    for (final (index, dot) in dots.indexed) {
      final shift = index < 4 ? Offset.zero : const Offset(-2.5, -2.5);
      canvas.drawCircle(
        dot.$1 * scale + shift,
        (index < 4 ? 7 : 4.5) * scale,
        Paint()..color = dot.$2,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.ms != ms;
}

class SplashBrandMark extends StatelessWidget {
  const SplashBrandMark({super.key, required this.size, this.ms = 4400});
  final double size, ms;

  @override
  Widget build(BuildContext context) {
    final entry = splashPhase(ms, 1700, 900, const Cubic(.34, 1.56, .64, 1));
    final ripple = splashPhase(ms, 2500, 1400, Curves.easeOut);
    final radius = BorderRadius.circular(
      size * (0.5 + (34 / 104 - .5) * entry),
    );
    return Transform.rotate(
      angle: (entry - 1) * 200 * math.pi / 180,
      child: Transform.scale(
        scale: entry,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment(-.7, -1),
              end: Alignment(.7, 1),
              stops: [0, .55, 1],
              colors: [
                Color(0xffb3a8f2),
                DesignColor.purple,
                Color(0xff6d5fc0),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: DesignColor.purple,
                offset: Offset(0, 30),
                blurRadius: 70,
                spreadRadius: -20,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: const Border(
                    top: BorderSide(color: Color(0x70ffffff), width: 2),
                  ),
                ),
              ),
              if (ms >= 2500 && ripple < 1)
                Transform.scale(
                  scale: 1 + 1.4 * ripple,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        width: 2,
                        color: const Color(
                          0xffb3a8f2,
                        ).withValues(alpha: .9 * (1 - ripple)),
                      ),
                    ),
                  ),
                ),
              Center(
                child: CustomPaint(
                  size: Size.square(size * 58 / 104),
                  painter: BrandCheckPainter(
                    splashPhase(ms, 2350, 500, Curves.easeOut),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
