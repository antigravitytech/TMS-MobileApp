import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';
import '../../application/committee_controller.dart';
import '../../data/committee_reference.dart';

class CommitteeOverview extends StatelessWidget {
  const CommitteeOverview({super.key, required this.view, required this.onTab});
  final CommitteeView view;
  final ValueChanged<CommitteeTab> onTab;
  @override
  Widget build(BuildContext c) {
    final locale = c.locale.toString();
    final term = view.term;
    final next = view.upcoming.firstOrNull;
    final poll = view.decision;
    final votes = poll?.votes ?? const <int>[];
    final lead = votes.isEmpty || votes.every((v) => v == 0)
        ? -1
        : votes.indexOf(votes.reduce((a, b) => a > b ? a : b));
    final demo = view.space.records.any(
      (r) => r.id.startsWith(committeeRefPrefix),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        if (term?.date != null)
          DesignEntrance(
            child: SpecialCountdownHero(
              days: daysUntil(term!.date!, view.today),
              chip: c.tr('committee.chip'),
              title: c.tr('committee.term_ends'),
              line: c.tr(
                'committee.term_line',
                namedArgs: {
                  'date': DateFormat.yMMMEd(locale).format(term.date!),
                  'n': '${view.members}',
                },
              ),
              intro: c.tr('committee.intro'),
            ),
          ),
        const SizedBox(height: 12),
        DesignEntrance(
          order: 1,
          child: SpecialKpiGrid([
            (
              next == null
                  ? '–'
                  : DateFormat('EEE d', locale).format(next.date!),
              next == null
                  ? c.tr('committee.kpi.no_meeting')
                  : '${next.title} · ${DateFormat.Hm(locale).format(next.date!)}',
              TmsIcons.calendar,
              DesignColor.blue,
              () => onTab(CommitteeTab.meetings),
            ),
            (
              '${view.openActions}',
              c.tr('committee.kpi.actions'),
              TmsIcons.checkSquare,
              DesignColor.amber,
              () => onTab(CommitteeTab.actions),
            ),
            (
              '${view.minutes.length}',
              c.tr('committee.kpi.minutes'),
              TmsIcons.file,
              null,
              () => onTab(CommitteeTab.minutes),
            ),
            (
              lead < 0 ? '–' : poll!.options[lead],
              poll == null
                  ? c.tr('committee.kpi.no_decision')
                  : c.tr('committee.kpi.leading'),
              TmsIcons.barChart,
              DesignColor.teal,
              () => onTab(CommitteeTab.decisions),
            ),
          ]),
        ),
        if (demo) ...[
          const SizedBox(height: 12),
          DesignEntrance(
            order: 2,
            child: SpecialWorkersCard(
              title: c.tr('committee.workers_title'),
              blockers: c.tr('committee.workers_blockers'),
            ),
          ),
        ],
      ],
    );
  }
}
