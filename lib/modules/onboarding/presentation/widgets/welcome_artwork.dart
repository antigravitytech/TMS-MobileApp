import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../shared/design/tms_icons.dart';
import 'splash_artwork.dart';

class WelcomeLogo extends StatelessWidget {
  const WelcomeLogo({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xfff3f5fe),
    ),
    alignment: Alignment.center,
    child: SizedBox.square(
      dimension: 16,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final c in [0xff12132a, 0xff9184d9, 0xff9184d9, 0xff12132a])
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    ),
  );
}

class WelcomeMark extends StatelessWidget {
  const WelcomeMark({super.key, required this.ms});
  final double ms;
  @override
  Widget build(BuildContext context) {
    final entry = splashPhase(ms, 200, 900, const Cubic(.34, 1.56, .64, 1));
    return Transform.rotate(
      angle: (entry - 1) * math.pi * 2 / 3,
      child: Transform.scale(
        scale: entry,
        child: Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            color: const Color(0xfff3f5fe),
            borderRadius: BorderRadius.circular(34),
            boxShadow: const [
              BoxShadow(color: Color(0x08ffffff), spreadRadius: 20),
              BoxShadow(
                color: Color(0xaa9184d9),
                offset: Offset(0, 30),
                blurRadius: 70,
                spreadRadius: -16,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size.square(60),
            painter: BrandCheckPainter(
              splashPhase(ms, 900, 600, Curves.easeOut),
              color: const Color(0xff7b6dd9),
              width: 4.6,
            ),
          ),
        ),
      ),
    );
  }
}

typedef _Satellite = ({
  double size,
  double radius,
  int bg,
  String? portrait,
  IconData? icon,
  int fg,
  double delay,
});

class WelcomeOrbitArtwork extends StatelessWidget {
  const WelcomeOrbitArtwork({
    super.key,
    required this.ms,
    required this.wave,
    required this.core,
    required this.reduced,
  });
  final double ms, wave;
  final bool reduced;
  final Widget core;
  static const List<_Satellite> _tiles = [
    (
      size: 58,
      radius: 19,
      bg: 0xff86d6cb,
      portrait: 'tb',
      icon: null,
      fg: 0,
      delay: 500,
    ),
    (
      size: 44,
      radius: 15,
      bg: 0xff2b2d45,
      portrait: null,
      icon: TmsIcons.chat,
      fg: 0xffb3a8f2,
      delay: 600,
    ),
    (
      size: 54,
      radius: 18,
      bg: 0xffeeabb0,
      portrait: 'ae',
      icon: null,
      fg: 0,
      delay: 700,
    ),
    (
      size: 46,
      radius: 16,
      bg: 0xffa3c8f1,
      portrait: 'im',
      icon: null,
      fg: 0,
      delay: 800,
    ),
    (
      size: 50,
      radius: 17,
      bg: 0xffeccb84,
      portrait: null,
      icon: TmsIcons.flame,
      fg: 0xff12132a,
      delay: 900,
    ),
    (
      size: 56,
      radius: 19,
      bg: 0xffc4bdf6,
      portrait: 'sj',
      icon: null,
      fg: 0,
      delay: 1000,
    ),
    (
      size: 48,
      radius: 16,
      bg: 0xffbcd995,
      portrait: 'dm',
      icon: null,
      fg: 0,
      delay: 1100,
    ),
    (
      size: 44,
      radius: 15,
      bg: 0xff2b2d45,
      portrait: null,
      icon: TmsIcons.birthday,
      fg: 0xfff0a3b5,
      delay: 1200,
    ),
    (
      size: 46,
      radius: 15,
      bg: 0xff9184d9,
      portrait: null,
      icon: TmsIcons.checkSquare,
      fg: 0xff12132a,
      delay: 400,
    ),
    (
      size: 42,
      radius: 14,
      bg: 0xff2b2d45,
      portrait: null,
      icon: TmsIcons.clock,
      fg: 0xff5fd3c4,
      delay: 550,
    ),
    (
      size: 44,
      radius: 15,
      bg: 0xffd8b4ec,
      portrait: 'na',
      icon: null,
      fg: 0,
      delay: 650,
    ),
    (
      size: 42,
      radius: 14,
      bg: 0xff2b2d45,
      portrait: null,
      icon: TmsIcons.barChart,
      fg: 0xffeccb84,
      delay: 750,
    ),
  ];

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: SizedBox(
      width: 390,
      height: 420,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final inner in [false, true])
            Container(
              width: inner ? 220 : 312,
              height: inner ? 220 : 312,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(inner ? 0x09ffffff : 0x06ffffff),
                border: Border.all(
                  color: Color(inner ? 0x10ffffff : 0x0dffffff),
                ),
              ),
            ),
          for (final (i, tile) in _tiles.indexed) _satellite(i, tile),
          for (final delay in [0, 210, 430])
            if (wave * 1630 >= delay && wave * 1630 < delay + 1200)
              _wave(
                splashPhase(
                  wave * 1630,
                  delay.toDouble(),
                  1200,
                  Curves.easeOut,
                ),
              ),
          core,
        ],
      ),
    ),
  );

  Widget _wave(double progress) => Transform.scale(
    scale: 1 + 2 * progress,
    child: Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          width: 2,
          color: const Color(0xffb3a8f2).withValues(alpha: .9 * (1 - progress)),
        ),
      ),
    ),
  );

  Widget _satellite(int i, _Satellite tile) {
    final outer = i < 8;
    final initial = outer ? -90 + i * 45 : 20 + (i - 8) * 90;
    final angle =
        initial * math.pi / 180 +
        (reduced ? 0 : ms * 2 * math.pi / (outer ? 70000 : -46000));
    final offset =
        Offset(math.cos(angle), math.sin(angle)) * (outer ? 156.0 : 110.0);
    final entry = reduced
        ? 1.0
        : splashPhase(ms, tile.delay, 700, const Cubic(.34, 1.56, .64, 1));
    return Transform.translate(
      offset: offset,
      child: Transform.scale(
        scale: .2 + .8 * entry,
        child: Opacity(
          opacity: entry.clamp(0, 1),
          child: Container(
            width: tile.size,
            height: tile.size,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Color(tile.bg),
              borderRadius: BorderRadius.circular(tile.radius),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 14),
                  blurRadius: 26,
                  spreadRadius: -12,
                ),
              ],
            ),
            child: tile.portrait == null
                ? Icon(tile.icon, color: Color(tile.fg), size: 20)
                : Image.asset(
                    'assets/onboarding/portraits/${tile.portrait}.png',
                    excludeFromSemantics: true,
                  ),
          ),
        ),
      ),
    );
  }
}
