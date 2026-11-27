import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../../../shared/kit/dated_row.dart';
import '../../application/church_controller.dart';
import 'church_attendance_sheet.dart';

class ChurchServices extends StatelessWidget {
  const ChurchServices({super.key, required this.view, required this.actions});
  final ChurchView view;
  final ChurchController actions;
  @override
  Widget build(BuildContext c) {
    final next = view.nextService;
    final locale = c.locale.toString();
    final serve = [
      for (final line in (next?.fields['serve'] ?? '').split('\n'))
        if (line.contains('|')) line.split('|'),
    ];
    final trend = view.trend;
    final most = trend.fold(
      1,
      (m, s) => s.field('attendance') > m ? s.field('attendance') : m,
    );
    final isToday = next != null && DateUtils.isSameDay(next.date, view.today);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        if (view.services.isEmpty) const SpecialEmpty('services'),
        if (next != null)
          DesignEntrance(
            child: KitHero(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpecialHeroChip(
                    c.tr(
                      'church.next_service',
                      namedArgs: {
                        'when': isToday
                            ? c.tr('common.today')
                            : DateFormat.MMMEd(locale).format(next.date!),
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    next.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: specialLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      DateFormat.EEEE(locale).format(next.date!),
                      DateFormat.jm(locale).format(next.date!),
                      if (next.group.isNotEmpty) next.group,
                      if (next.person.isNotEmpty) next.person,
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12, color: specialSoft),
                  ),
                  if (next.notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      next.notes,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                        color: specialLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton(
                      onPressed: () => showAttendanceSheet(c, next, actions),
                      style: FilledButton.styleFrom(
                        backgroundColor: specialLight,
                        foregroundColor: DesignColor.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(c.tr('church.record_attendance')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (serve.isNotEmpty) ...[
          const SizedBox(height: 12),
          KitCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.tr('church.serving'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    KitStatus('${serve.length}/${serve.length}', KitColor.done),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: .95,
                  children: [
                    for (final [name, role] in serve)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: c.foreground.withValues(alpha: .04),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          spacing: 4,
                          children: [
                            DesignAvatar(
                              kitPerson(name).$1,
                              size: 28,
                              color: kitPerson(name).$2,
                            ),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              role,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (trend.isNotEmpty) ...[
          const SizedBox(height: 12),
          KitCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.tr('church.trend'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      c.plural('church.last_services', trend.length),
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
                SizedBox(
                  height: 118,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 10,
                    children: [
                      for (final (i, s) in trend.indexed)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            spacing: 6,
                            children: [
                              Text(
                                '${s.field('attendance')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: 70 * s.field('attendance') / most,
                                ),
                                duration: const Duration(milliseconds: 600),
                                curve: DesignMotion.curve,
                                builder: (_, h, _) => Container(
                                  height: h,
                                  decoration: BoxDecoration(
                                    color: i == trend.length - 1
                                        ? DesignColor.teal
                                        : DesignColor.purple.withValues(
                                            alpha: .85,
                                          ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                      bottom: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                DateUtils.isSameDay(s.date, view.today)
                                    ? c.tr('common.today')
                                    : DateFormat.MMMd(locale).format(s.date!),
                                style: TextStyle(fontSize: 12, color: c.muted),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (view.upcoming.length > 1) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
            child: Text(
              c.tr('church.coming_up').toUpperCase(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: c.muted,
              ),
            ),
          ),
          KitList(
            children: [
              for (final s in view.upcoming.skip(1))
                DatedRow(
                  key: ValueKey(s.id),
                  date: s.date!,
                  title: s.title,
                  meta: [
                    DateFormat.jm(locale).format(s.date!),
                    if (s.notes.isNotEmpty) s.notes,
                  ].join(' · '),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
