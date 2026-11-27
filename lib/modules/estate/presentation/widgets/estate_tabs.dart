import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';
import '../../../../shared/kit/dated_row.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/estate_controller.dart';
import '../../data/estate_reference.dart';
import 'estate_pass_sheet.dart';

class EstateOverview extends StatelessWidget {
  const EstateOverview({super.key, required this.view, required this.onTab});
  final EstateView view;
  final ValueChanged<EstateTab> onTab;
  @override
  Widget build(BuildContext c) {
    final info = view.info;
    final poll = view.poll;
    final votes = poll?.votes ?? const <int>[];
    final lead = votes.isEmpty || votes.every((v) => v == 0)
        ? -1
        : votes.indexOf(votes.reduce((a, b) => a > b ? a : b));
    final demo = view.space.records.any(
      (r) => r.id.startsWith(estateRefPrefix),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        if (info?.date != null)
          DesignEntrance(
            child: SpecialCountdownHero(
              days: daysUntil(info!.date!, view.today),
              chip: c.tr('estate.chip'),
              title: info.fields['event'] ?? info.title,
              line: c.tr(
                'estate.event_line',
                namedArgs: {
                  'date': DateFormat.MMMEd(
                    c.locale.toString(),
                  ).format(info.date!),
                  'venue': info.fields['venue'] ?? '',
                  'n': '${view.houses}',
                },
              ),
              intro: c.tr('estate.intro'),
            ),
          ),
        const SizedBox(height: 12),
        DesignEntrance(
          order: 1,
          child: SpecialKpiGrid([
            (
              specialMoney(c, view.collected),
              c.plural(
                'estate.kpi.levies',
                view.owing,
                namedArgs: {'target': specialMoney(c, view.target)},
              ),
              TmsIcons.card,
              DesignColor.green,
              () => onTab(EstateTab.levies),
            ),
            (
              '${view.upcomingPasses.length}',
              c.tr('estate.kpi.passes'),
              TmsIcons.badge,
              DesignColor.amber,
              () => onTab(EstateTab.passes),
            ),
            (
              '${view.openIssues}',
              c.tr('estate.kpi.issues'),
              TmsIcons.edit,
              DesignColor.red,
              () => onTab(EstateTab.issues),
            ),
            (
              lead < 0 ? '–' : poll!.options[lead],
              poll?.title ?? c.tr('estate.kpi.no_poll'),
              TmsIcons.barChart,
              null,
              () => onTab(EstateTab.poll),
            ),
          ]),
        ),
        if (demo) ...[
          const SizedBox(height: 12),
          DesignEntrance(
            order: 2,
            child: SpecialWorkersCard(
              title: c.tr('estate.workers_title'),
              blockers: c.tr('estate.workers_blockers'),
            ),
          ),
        ],
      ],
    );
  }
}

class EstatePasses extends StatelessWidget {
  const EstatePasses({super.key, required this.view, required this.actions});
  final EstateView view;
  final EstateController actions;
  @override
  Widget build(BuildContext c) {
    final locale = c.locale.toString();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        specialIntro(c, 'estate.passes_intro'),
        if (view.upcomingPasses.isEmpty) const SpecialEmpty('passes'),
        for (final (i, p) in view.upcomingPasses.reversed.indexed)
          Padding(
            key: ValueKey(p.id),
            padding: const EdgeInsets.only(bottom: 10),
            child: DesignEntrance(
              order: i,
              child: KitCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    DatedRow(
                      date: p.date!,
                      title: p.title,
                      meta: [
                        DateUtils.isSameDay(p.date, view.today)
                            ? c.tr('common.today')
                            : DateFormat.MMMEd(locale).format(p.date!),
                        p.fields['anyTime'] == 'true'
                            ? c.tr('estate.any_time')
                            : DateFormat.Hm(locale).format(p.date!),
                      ].join(' · '),
                      trailing: KitStatus(
                        p.fields['new'] == 'true'
                            ? c.tr('estate.new')
                            : DateUtils.isSameDay(p.date, view.today)
                            ? c.tr('estate.soon')
                            : DateFormat.EEEE(locale).format(p.date!),
                        p.fields['new'] == 'true'
                            ? KitColor.done
                            : KitColor.progress,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: c.foreground.withValues(alpha: .04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: c.foreground.withValues(alpha: .25),
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.tr('estate.gate_code'),
                              style: TextStyle(fontSize: 12, color: c.muted),
                            ),
                          ),
                          SelectableText(
                            p.code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 2),
        DesignButton(
          c.tr('estate.new_pass'),
          onPressed: () => showPassSheet(c, actions),
        ),
      ],
    );
  }
}
