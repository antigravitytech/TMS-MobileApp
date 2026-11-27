import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../router/tms_routes.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../individual/presentation/widgets/individual_home_widgets.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';

/// Text colours on the indigo `.hero`.
const specialLight = Color(0xfff3f5fe);
const specialSoft = Color(0xffc9cbe0);

/// Compact naira, e.g. ₦2.58m or ₦650k.
String specialMoney(BuildContext c, int kobo) => NumberFormat.compactCurrency(
  locale: c.locale.toString(),
  symbol: '₦',
  decimalDigits: kobo >= 100000000 ? 2 : 0,
).format(kobo / 100).toLowerCase();

/// Whole days from [today] until [date].
int daysUntil(DateTime date, DateTime today) =>
    DateTime(date.year, date.month, date.day).difference(today).inDays;

/// A translucent chip on the hero (`.ws-chip` on indigo).
class SpecialHeroChip extends StatelessWidget {
  const SpecialHeroChip(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext c) => Container(
    height: 26,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0x1fffffff),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: .5,
        color: specialLight,
      ),
    ),
  );
}

/// The Overview hero: a big countdown, the event and an intro line.
class SpecialCountdownHero extends StatelessWidget {
  const SpecialCountdownHero({
    super.key,
    required this.days,
    required this.chip,
    required this.title,
    required this.line,
    required this.intro,
  });
  final int days;
  final String chip, title, line, intro;
  @override
  Widget build(BuildContext c) => KitHero(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 14,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$days',
                  style: const TextStyle(
                    fontSize: 56,
                    height: .95,
                    letterSpacing: -2.5,
                    fontWeight: FontWeight.w800,
                    color: specialLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.plural('specials.days_to_go', days).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .7,
                    color: specialSoft,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SpecialHeroChip(chip),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: specialLight,
                    ),
                  ),
                  Text(
                    line,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12, color: specialSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(intro, style: const TextStyle(fontSize: 13.5, color: specialSoft)),
      ],
    ),
  );
}

/// One Overview card: value, label, icon tint and what tapping does.
typedef SpecialKpi = (
  String value,
  String label,
  IconData icon,
  Color? color,
  VoidCallback onTap,
);

/// Two-column grid of `.kpi` cards with equal heights per row.
class SpecialKpiGrid extends StatelessWidget {
  const SpecialKpiGrid(this.cards, {super.key});
  final List<SpecialKpi> cards;
  @override
  Widget build(BuildContext c) => Column(
    spacing: 10,
    children: [
      for (var i = 0; i < cards.length; i += 2)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              for (final (value, label, icon, color, onTap)
                  in cards.skip(i).take(2))
                Expanded(
                  child: IndividualKpi(
                    icon: icon,
                    color: color,
                    value: value,
                    label: label,
                    onTap: onTap,
                  ),
                ),
              if (i + 1 >= cards.length) const Expanded(child: SizedBox()),
            ],
          ),
        ),
    ],
  );
}

/// "N of M sent today's summary" with faces and a Reports button.
/// Demo workspaces only: nothing tracks daily summaries yet.
class SpecialWorkersCard extends StatelessWidget {
  const SpecialWorkersCard({
    super.key,
    required this.title,
    required this.blockers,
  });
  final String title, blockers;
  @override
  Widget build(BuildContext c) => KitCard(
    child: Row(
      spacing: 12,
      children: [
        SizedBox(
          width: 72,
          height: 28,
          child: Stack(
            children: [
              for (final (i, (who, color)) in [
                ('DC', KitColor.avatar(2)),
                ('CE', KitColor.avatar(4)),
                ('+3', c.raised),
              ].indexed)
                Positioned(
                  left: i * 20.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.panel, width: 2),
                    ),
                    child: DesignAvatar(who, size: 28, color: color),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                blockers,
                style: const TextStyle(fontSize: 12, color: Color(0xffee9a6a)),
              ),
            ],
          ),
        ),
        KitMiniButton(
          c.tr('specials.reports'),
          onPressed: () => TmsRoute.reports.open(c),
        ),
      ],
    ),
  );
}

/// Money hero: an amount, its target, a ring and three small stats.
class SpecialMoneyHero extends StatelessWidget {
  const SpecialMoneyHero({
    super.key,
    required this.label,
    required this.amount,
    required this.trio,
    this.sub = '',
    this.ratio,
  });
  final String label, amount, sub;

  /// Progress shown in the ring; null hides the ring.
  final double? ratio;
  final List<(String, String)> trio;
  @override
  Widget build(BuildContext c) => KitHero(
    child: Column(
      children: [
        Row(
          spacing: 14,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: specialSoft,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 34,
                        height: 1,
                        letterSpacing: -1.2,
                        fontWeight: FontWeight.w800,
                        color: specialLight,
                      ),
                    ),
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: const TextStyle(fontSize: 12, color: specialSoft),
                    ),
                  ],
                ],
              ),
            ),
            if (ratio case final r?)
              KitRing(
                value: r,
                label: '${(r * 100).round()}%',
                color: DesignColor.teal,
                track: const Color(0x22ffffff),
                inner: const Color(0xff232532),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          spacing: 8,
          children: [
            for (final (k, v) in trio)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0x10ffffff),
                    border: Border.all(color: const Color(0x14ffffff)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        k,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: specialSoft,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          v,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: specialLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
