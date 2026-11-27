import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';

class IndividualKpiGrid extends StatelessWidget {
  const IndividualKpiGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext c) => Column(
    spacing: 10,
    children: [
      for (var i = 0; i < children.length; i += 2)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Expanded(child: children[i]),
              Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox(),
              ),
            ],
          ),
        ),
    ],
  );
}

/// The prototype's on-time streak, shown for the demo workspace only.
class IndividualRhythm extends StatelessWidget {
  const IndividualRhythm({super.key});
  @override
  Widget build(BuildContext c) => KitCard(
    child: Column(
      children: [
        Row(
          spacing: 12,
          children: [
            const Icon(TmsIcons.flame, size: 26, color: Color(0xffee9a6a)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.tr('individual.streak_title'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    c.tr('individual.streak_body'),
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          spacing: 6,
          children: [
            for (var d = 1; d <= 5; d++)
              Expanded(
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: d <= 3 ? KitColor.done : c.raised,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    DateFormat.E(
                      c.locale.toString(),
                    ).format(DateTime(2024, 1, d)),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: d <= 3 ? const Color(0xff0f2418) : c.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class IndividualCount extends StatelessWidget {
  const IndividualCount(this.n, {super.key});
  final int n;
  @override
  Widget build(BuildContext c) => Container(
    constraints: const BoxConstraints(minWidth: 22),
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 7),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: c.raised,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      '$n',
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

/// `.ws-logo` square with the workspace's initials.
class IndividualLogo extends StatelessWidget {
  const IndividualLogo(this.name, {super.key});
  final String name;
  @override
  Widget build(BuildContext c) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: KitColor.avatar(5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      kitPerson(name).$1,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: DesignColor.ink,
      ),
    ),
  );
}

/// Profile avatar with the green online dot (`.on-dot`).
class IndividualOnlineAvatar extends StatelessWidget {
  const IndividualOnlineAvatar(this.name, {super.key});
  final String name;
  @override
  Widget build(BuildContext c) => SizedBox.square(
    dimension: 44,
    child: Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DesignAvatar(kitPerson(name).$1, size: 40, color: KitColor.avatar(5)),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: KitColor.done,
                shape: BoxShape.circle,
                border: Border.all(color: c.background, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
