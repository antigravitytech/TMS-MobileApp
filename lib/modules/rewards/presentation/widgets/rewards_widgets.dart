import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/rewards_controller.dart';

const _light = Color(0xfff3f5fe);

/// "Star of the week" hero with a three-step podium and a floating crown.
class RewardsPodium extends StatelessWidget {
  const RewardsPodium({super.key, required this.people});
  final List<BoardPerson> people;
  @override
  Widget build(BuildContext c) {
    final top = people.take(3).toList();
    Widget pod(int rank, double height, Color color) {
      if (rank >= top.length) return const Expanded(child: SizedBox());
      final p = top[rank];
      final (initials, fill) = kitPerson(p.name);
      final first = rank == 0;
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            if (first) const _Crown(),
            Container(
              decoration: first
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: DesignColor.amber, width: 3),
                    )
                  : null,
              child: DesignAvatar(initials, size: first ? 52 : 36, color: fill),
            ),
            Text(
              '${p.name} · ${p.points}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _light,
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: height),
              duration: Duration(milliseconds: 600 + rank * 120),
              curve: DesignMotion.curve,
              builder: (_, h, _) => Container(
                height: h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                    bottom: Radius.circular(6),
                  ),
                ),
                child: h > 24
                    ? Text(
                        '${rank + 1}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: DesignColor.ink,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      );
    }

    return KitHero(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Text(
            c.tr('rewards.star').toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: .7,
              color: Color(0xffc9cbe0),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 10,
            children: [
              pod(1, 56, KitColor.avatar(1)),
              pod(0, 84, DesignColor.amber),
              pod(2, 40, const Color(0xff86d6cb)),
            ],
          ),
        ],
      ),
    );
  }
}

/// `floaty`: the crown bobs 8px over three seconds.
class _Crown extends StatefulWidget {
  const _Crown();
  @override
  State<_Crown> createState() => _CrownState();
}

class _CrownState extends State<_Crown> with SingleTickerProviderStateMixin {
  late final _bob = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
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
    child: const Icon(TmsIcons.crown, size: 28, color: DesignColor.amber),
  );
}

/// One `.prow` on the points board.
class RewardsPersonRow extends StatelessWidget {
  const RewardsPersonRow({
    super.key,
    required this.rank,
    required this.person,
    required this.cheered,
    required this.onCheer,
  });
  final int rank;
  final BoardPerson person;
  final bool cheered;
  final VoidCallback onCheer;
  @override
  Widget build(BuildContext c) {
    final (initials, color) = kitPerson(person.name);
    final p = person;
    final line = p.choresTotal + p.schoolTotal == 0
        ? c.tr('rewards.nothing')
        : [
            if (p.choresTotal > 0)
              c.tr(
                'rewards.chores_line',
                namedArgs: {
                  'done': '${p.choresDone}',
                  'total': '${p.choresTotal}',
                },
              ),
            if (p.schoolTotal > 0)
              c.tr(
                'rewards.school_line',
                namedArgs: {
                  'done': '${p.schoolDone}',
                  'total': '${p.schoolTotal}',
                },
              ),
          ].join(' · ');
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 58),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            SizedBox(
              width: 14,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  color: c.muted.withValues(alpha: .8),
                ),
              ),
            ),
            DesignAvatar(initials, size: 36, color: color),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: p.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: ' · ${c.tr('rewards.roles.${p.role}')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(line, style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
            ),
            KitPoints(p.points),
            AnimatedScale(
              scale: cheered ? 1.06 : 1,
              duration: const Duration(milliseconds: 250),
              curve: kitSpring,
              child: GestureDetector(
                onTap: onCheer,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cheered
                        ? DesignColor.amber.withValues(alpha: .18)
                        : Colors.transparent,
                    border: Border.all(
                      color: cheered ? DesignColor.amber : c.outline,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    c.tr(cheered ? 'rewards.cheered' : 'rewards.cheer'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: cheered ? DesignColor.amber : c.foreground,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.reward` card with an amber progress bar and a Give button when affordable.
class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.reward,
    required this.points,
    required this.onGive,
  });
  final WorkspaceRecord reward;
  final int points;
  final VoidCallback onGive;
  @override
  Widget build(BuildContext c) {
    final cost = reward.points;
    final can = cost > 0 && points >= cost;
    final (icon, color) = switch (reward.fields['rewardKind']) {
      'treat' => (TmsIcons.iceCream, DesignColor.red),
      'movie' => (TmsIcons.movie, null),
      'sport' => (TmsIcons.sportsBall, DesignColor.green),
      _ => (TmsIcons.monitor, DesignColor.blue),
    };
    return KitCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: can ? DesignColor.amber.withValues(alpha: .55) : null,
      child: Row(
        spacing: 12,
        children: [
          KitTile(icon, color: color),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                KitBar(
                  value: cost == 0 ? 1 : points / cost,
                  color: DesignColor.amber,
                ),
                const SizedBox(height: 6),
                Text(
                  can
                      ? c.tr(
                          'rewards.can_have',
                          namedArgs: {'cost': '$cost', 'name': rewardsChild},
                        )
                      : c.tr(
                          'rewards.more_needed',
                          namedArgs: {
                            'left': '${cost - points}',
                            'cost': '$cost',
                          },
                        ),
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ],
            ),
          ),
          if (can)
            KitMiniButton(
              c.tr('rewards.give'),
              primary: true,
              onPressed: onGive,
            ),
        ],
      ),
    );
  }
}
