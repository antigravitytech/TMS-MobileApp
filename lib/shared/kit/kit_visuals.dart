import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/design_widgets.dart';
import '../design/tms_icons.dart';
import 'kit.dart';

/// `.card` surface.
class KitCard extends StatelessWidget {
  const KitCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.border,
    this.radius = 22,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color, border;
  final double radius;
  @override
  Widget build(BuildContext c) => AnimatedContainer(
    duration: const Duration(milliseconds: 400),
    curve: DesignMotion.curve,
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? c.panel,
      border: Border.all(color: border ?? c.outline),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );
}

/// `.list`: one card whose rows are split by hairlines and rise in turn.
class KitList extends StatelessWidget {
  const KitList({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext c) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: c.panel,
      border: Border.all(color: c.outline),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0)
            Divider(height: 1, color: c.foreground.withValues(alpha: .08)),
          DesignEntrance(order: i * 2, child: child),
        ],
      ],
    ),
  );
}

/// `.hero` card with the indigo radial gradient and teal corner glow.
class KitHero extends StatelessWidget {
  const KitHero({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext c) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const RadialGradient(
        center: Alignment(.8, -1.2),
        radius: 1.3,
        colors: [
          Color(0xff4a4fa8),
          Color(0xff353b80),
          Color(0xff262a60),
          Color(0xff1b1e45),
        ],
        stops: [0, .22, .48, .8],
      ),
    ),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-.8, 1.2),
          radius: .7,
          colors: [Color(0x332bb3a3), Color(0x002bb3a3)],
        ),
      ),
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// Round `.tick`; turns teal and spins a full turn when [on].
class KitTick extends StatelessWidget {
  const KitTick({
    super.key,
    required this.on,
    required this.label,
    required this.onTap,
    this.size = 30,
  });
  final bool on;
  final String label;
  final VoidCallback onTap;

  /// 30px in lists, 44px on the kid's chore cards.
  final double size;
  @override
  Widget build(BuildContext c) => Semantics(
    button: true,
    toggled: on,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedRotation(
        turns: on ? 1 : 0,
        duration: const Duration(milliseconds: 350),
        curve: kitSpring,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: kitSpring,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? KitColor.tick : Colors.transparent,
            border: Border.all(
              width: 2,
              color: on ? KitColor.tick : c.foreground.withValues(alpha: .25),
            ),
          ),
          child: AnimatedScale(
            scale: on ? 1 : .2,
            duration: const Duration(milliseconds: 350),
            curve: kitSpring,
            child: AnimatedOpacity(
              opacity: on ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                TmsIcons.check,
                size: size / 2,
                color: Color(0xff0d2a26),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// `.ring2` progress ring with a centred label.
class KitRing extends StatelessWidget {
  const KitRing({
    super.key,
    required this.value,
    required this.label,
    this.size = 84,
    this.color = KitColor.done,
    this.track,
    this.inner,
  });
  final double value, size;
  final String label;
  final Color color;
  final Color? track, inner;
  @override
  Widget build(BuildContext c) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.clamp(0, 1)),
    duration: const Duration(milliseconds: 600),
    curve: DesignMotion.curve,
    builder: (_, v, _) => CustomPaint(
      painter: _RingPainter(
        v,
        color,
        track ?? (c.dark ? const Color(0xff3f424d) : const Color(0xffd5d8e6)),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Container(
            width: size * .78,
            height: size * .78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: inner ?? c.panel,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: size < 70 ? 14 : 17,
                fontWeight: FontWeight.w700,
                color: inner == null ? null : const Color(0xfff3f5fe),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.value, this.color, this.track);
  final double value;
  final Color color, track;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(rect, Paint()..color = track);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      true,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Amber `.pts-badge` with a star.
class KitPoints extends StatelessWidget {
  const KitPoints(this.points, {super.key, this.large = false});
  final int points;
  final bool large;
  @override
  Widget build(BuildContext c) => Container(
    height: large ? 40 : 26,
    padding: EdgeInsets.symmetric(horizontal: large ? 14 : 9),
    decoration: BoxDecoration(
      color: KitColor.submitted.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        const Icon(TmsIcons.starFilled, size: 13, color: KitColor.submitted),
        Text(
          '$points',
          style: TextStyle(
            fontSize: large ? 15 : 12.5,
            fontWeight: FontWeight.w700,
            color: KitColor.submitted,
          ),
        ),
      ],
    ),
  );
}

/// `.st` status pill tinted by [color].
class KitStatus extends StatelessWidget {
  const KitStatus(this.label, this.color, {super.key, this.dot = false});
  final String label;
  final Color color;
  final bool dot;
  @override
  Widget build(BuildContext c) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        if (dot) CircleAvatar(radius: 3, backgroundColor: color),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

/// `.tile` icon square; [color] null gives the neutral lavender tile.
class KitTile extends StatelessWidget {
  const KitTile(this.icon, {super.key, this.color, this.size = 44});
  final IconData icon;
  final Color? color;
  final double size;
  @override
  Widget build(BuildContext c) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color?.withValues(alpha: .13) ?? c.raised,
      border: Border.all(color: color?.withValues(alpha: .28) ?? c.outline),
      borderRadius: BorderRadius.circular(size * .31),
    ),
    child: Icon(icon, size: 20, color: color ?? c.lavender),
  );
}

/// `.bar` progress track (5px) that fills with the [DesignMotion] curve.
class KitBar extends StatelessWidget {
  const KitBar({super.key, required this.value, required this.color});
  final double value;
  final Color color;
  @override
  Widget build(BuildContext c) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: Container(
      height: 5,
      color: c.dark ? const Color(0xff3f424d) : const Color(0xffd5d8e6),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: DesignMotion.curve,
        builder: (_, v, _) => FractionallySizedBox(
          heightFactor: 1,
          widthFactor: v,
          child: ColoredBox(color: color),
        ),
      ),
    ),
  );
}
