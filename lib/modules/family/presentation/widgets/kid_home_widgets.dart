import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';

/// `.kid-hero`: points, a bobbing star and progress to the next reward.
class KidHero extends StatelessWidget {
  const KidHero({super.key, required this.points, this.next});
  final int points;
  final WorkspaceRecord? next;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const RadialGradient(
        center: Alignment.topRight,
        radius: 1.25,
        colors: [Color(0xfff0a3b5), Color(0xffc2449b), Color(0xff6d4bd4)],
        stops: [0, .3, .75],
      ),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 14,
            children: [
              const _BobbingStar(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: .85,
                      child: Text(
                        c.tr('family.star').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: DesignMotion.object,
                      transitionBuilder: (child, a) =>
                          ScaleTransition(scale: a, child: child),
                      child: Text.rich(
                        key: ValueKey(points),
                        TextSpan(
                          text: '$points ',
                          style: const TextStyle(
                            fontSize: 38,
                            height: 1.05,
                            letterSpacing: -1.3,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(
                              text: c.tr('family.pts_unit'),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.tr('family.next', namedArgs: {'name': next!.title}),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  c.tr(
                    'family.to_go_short',
                    namedArgs: {'n': '${next!.points - points}'},
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                height: 10,
                color: const Color(0x33ffffff),
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (points / next!.points).clamp(0, 1)),
                  duration: const Duration(milliseconds: 700),
                  curve: DesignMotion.curve,
                  builder: (_, v, _) => FractionallySizedBox(
                    heightFactor: 1,
                    widthFactor: v,
                    child: const ColoredBox(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// `.kid-star` with the 4s `floaty` bob.
class _BobbingStar extends StatefulWidget {
  const _BobbingStar();
  @override
  State<_BobbingStar> createState() => _BobbingStarState();
}

class _BobbingStarState extends State<_BobbingStar>
    with SingleTickerProviderStateMixin {
  late final _bob = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MediaQuery.disableAnimationsOf(context) ? _bob.stop() : _bob.repeat();
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => AnimatedBuilder(
    animation: _bob,
    builder: (_, child) => Transform.translate(
      offset: Offset(
        0,
        -8 * Curves.easeInOut.transform(1 - (2 * _bob.value - 1).abs()),
      ),
      child: child,
    ),
    child: Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0x2effffff),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(TmsIcons.starFilled, size: 36, color: Colors.white),
    ),
  );
}

/// `.arrive`: teal until tapped, then a quiet card with the time sent.
class KidArriveButton extends StatelessWidget {
  const KidArriveButton({super.key, required this.sentAt, required this.onTap});
  final DateTime? sentAt;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final sent = sentAt != null;
    final fg = sent ? c.foreground : const Color(0xff0d2a26);
    return GestureDetector(
      onTap: sent ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: DesignMotion.curve,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sent ? c.panel : KitColor.tick,
          border: Border.all(color: sent ? c.outline : Colors.transparent),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          spacing: 14,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x55ffffff),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(TmsIcons.location, color: fg),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.tr(sent ? 'family.arrived_title' : 'family.arrival'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  Opacity(
                    opacity: .8,
                    child: Text(
                      sent
                          ? c.tr(
                              'family.arrived_at',
                              namedArgs: {
                                'time': DateFormat.jm(
                                  c.locale.toString(),
                                ).format(sentAt!),
                              },
                            )
                          : c.tr('family.arrival_hint'),
                      style: TextStyle(fontSize: 12, color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.kchore`: a large tick, the chore and its points.
class KidChoreCard extends StatelessWidget {
  const KidChoreCard({super.key, required this.chore, required this.onTap});
  final WorkspaceRecord chore;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final done = chore.status == WorkspaceStatus.done;
    final key = chore.fields['dueKey'];
    final due = key != null ? c.tr('chores.dues.$key') : chore.fields['due'];
    return GestureDetector(
      onTap: onTap,
      child: KitCard(
        padding: const EdgeInsets.all(14),
        color: done
            ? Color.alphaBlend(KitColor.done.withValues(alpha: .1), c.panel)
            : null,
        border: done ? KitColor.done.withValues(alpha: .35) : null,
        child: Row(
          spacing: 14,
          children: [
            KitTick(
              size: 44,
              on: done,
              label: c.tr(done ? 'chores.mark_not_done' : 'chores.mark_done'),
              onTap: onTap,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: done ? .55 : 1,
                    child: Text(
                      chore.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: KitColor.tick,
                      ),
                    ),
                  ),
                  if (due != null && due.isNotEmpty)
                    Text(due, style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
            ),
            if (chore.points > 0) KitPoints(chore.points),
          ],
        ),
      ),
    );
  }
}
