import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import 'widgets/splash_artwork.dart';

export 'widgets/splash_artwork.dart' show SplashBrandMark;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4400),
  );
  Timer? _timer;
  bool _leaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null) return;
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
    _timer = Timer(Duration(milliseconds: reduced ? 250 : 3700), _continue);
  }

  void _continue() {
    if (_leaving) return;
    _leaving = true;
    _timer?.cancel();
    TmsRoute.welcome.reset(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff0d0e18),
    body: Semantics(
      button: true,
      excludeSemantics: true,
      label: context.tr('welcome.splash_accessibility_label'),
      onTap: _continue,
      child: GestureDetector(
        onTap: _continue,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _intro,
          builder: (context, _) {
            final ms = _intro.value * 4400;
            final bottom = MediaQuery.viewPaddingOf(context).bottom;
            final load = splashPhase(ms, 0, 3300, const Cubic(.4, 0, .2, 1));
            final hint = splashPhase(ms, 3800, 600, Curves.easeOut);
            return Stack(
              fit: StackFit.expand,
              children: [
                SplashAtmosphere(ms: ms),
                Center(
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SplashBrandMark(size: 104, ms: ms),
                        const SizedBox(height: 26),
                        _SplashType(ms: ms),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: math.max(bottom + 12, 64),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      height: 4,
                      width: 120,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0x1affffff),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: load,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                            gradient: LinearGradient(
                              colors: [DesignColor.purple, DesignColor.teal],
                            ),
                          ),
                          child: SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: math.max(bottom, 30),
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: hint,
                    child: Transform.translate(
                      offset: Offset(0, (1 - hint) * 8),
                      child: Text(
                        context.tr('welcome.splash_skip'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xffa4a7bd),
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .26,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _SplashType extends StatelessWidget {
  const _SplashType({required this.ms});
  final double ms;

  @override
  Widget build(BuildContext context) {
    final letters = context.tr('welcome.sabi_pipu').characters;
    var count = 0;
    var accent = false;
    final wordmark = <Widget>[];
    for (final letter in letters) {
      if (letter == ' ') {
        accent = true;
        wordmark.add(const SizedBox(width: 10));
        continue;
      }
      final t = splashPhase(
        ms,
        2500 + 50.0 * count++,
        600,
        const Cubic(.34, 1.56, .64, 1),
      );
      wordmark.add(
        Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - t)),
            child: Transform.rotate(
              angle: (1 - t) * math.pi / 15,
              child: Text(
                letter,
                style: TextStyle(
                  color: accent
                      ? const Color(0xffb3a8f2)
                      : const Color(0xfff3f5fe),
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                  letterSpacing: -1.08,
                ),
              ),
            ),
          ),
        ),
      );
    }
    const tags = [
      'welcome.splash_team',
      'welcome.splash_rhythm',
      'welcome.splash_promise',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: wordmark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 7,
          children: [
            for (final (i, key) in tags.indexed)
              Builder(
                builder: (context) {
                  final t = splashPhase(
                    ms,
                    3000 + 150.0 * i,
                    500,
                    DesignMotion.curve,
                  );
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - t)),
                      child: Text(
                        context.tr(key),
                        style: TextStyle(
                          color: i == 2
                              ? DesignColor.teal
                              : const Color(0xffc9cbe0),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          letterSpacing: 0,
                          height: 1.45,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

// Reveal the live Welcome route around the shrinking splash circle.
Widget splashReveal(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondary,
  Widget child,
) {
  if (MediaQuery.disableAnimationsOf(context)) return child;
  return ClipPath(clipper: _SplashWipe(animation), child: child);
}

class _SplashWipe extends CustomClipper<Path> {
  _SplashWipe(this.animation) : super(reclip: animation);
  final Animation<double> animation;
  @override
  Path getClip(Size size) {
    final t = const Cubic(.7, 0, .3, 1).transform(animation.value);
    final diagonal = Offset(size.width, size.height).distance;
    final radius = 1.5 * diagonal / math.sqrt2 * (1 - t);
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height * .46),
          radius: radius,
        ),
      );
  }

  @override
  bool shouldReclip(_SplashWipe old) => animation != old.animation;
}
