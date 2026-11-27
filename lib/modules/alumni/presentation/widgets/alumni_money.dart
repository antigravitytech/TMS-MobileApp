import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../application/alumni_controller.dart';
import '../../data/alumni_reference.dart';

class AlumniOverview extends StatelessWidget {
  const AlumniOverview({super.key, required this.view, required this.onTab});
  final AlumniView view;
  final ValueChanged<AlumniTab> onTab;
  @override
  Widget build(BuildContext c) {
    final info = view.info;
    final poll = view.poll;
    final votes = poll?.votes ?? const <int>[];
    final total = votes.fold(0, (a, b) => a + b);
    final lead = votes.isEmpty
        ? -1
        : votes.indexOf(votes.reduce((a, b) => a > b ? a : b));
    final demo = view.space.records.any(
      (r) => r.id.startsWith(alumniRefPrefix),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        if (info?.date != null)
          DesignEntrance(
            child: SpecialCountdownHero(
              days: daysUntil(info!.date!, view.today),
              chip: c.tr('alumni.chip'),
              title: info.fields['event'] ?? info.title,
              line: c.tr(
                'alumni.event_line',
                namedArgs: {
                  'date': DateFormat.yMMMEd(
                    c.locale.toString(),
                  ).format(info.date!),
                  'n': '${view.size}',
                },
              ),
              intro: c.tr('alumni.intro'),
            ),
          ),
        const SizedBox(height: 12),
        DesignEntrance(
          order: 1,
          child: SpecialKpiGrid([
            (
              specialMoney(c, view.collected),
              c.plural(
                'alumni.kpi.dues',
                view.owing.length,
                namedArgs: {'target': specialMoney(c, view.target)},
              ),
              TmsIcons.card,
              DesignColor.green,
              () => onTab(AlumniTab.dues),
            ),
            (
              '${view.committees.length}',
              c.plural('alumni.kpi.committees', view.openTodos),
              TmsIcons.people,
              DesignColor.teal,
              () => onTab(AlumniTab.committees),
            ),
            (
              total == 0 ? '–' : '${(votes[lead] * 100 / total).round()}%',
              poll == null || total == 0
                  ? c.tr('alumni.kpi.no_votes')
                  : c.tr(
                      'alumni.kpi.poll',
                      namedArgs: {
                        'option': poll.options[lead],
                        'poll': poll.title.toLowerCase(),
                      },
                    ),
              TmsIcons.barChart,
              null,
              () => onTab(AlumniTab.poll),
            ),
            (
              '${view.active}/${view.classmates.length}',
              c.tr('alumni.kpi.active'),
              TmsIcons.person,
              DesignColor.blue,
              () => onTab(AlumniTab.directory),
            ),
          ]),
        ),
        if (demo) ...[
          const SizedBox(height: 12),
          DesignEntrance(
            order: 2,
            child: SpecialWorkersCard(
              title: c.tr('alumni.workers_title'),
              blockers: c.tr('alumni.workers_blockers'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Dues & pledges, on the shared collection tab.
class AlumniDues extends StatelessWidget {
  const AlumniDues({super.key, required this.view});
  final AlumniView view;
  @override
  Widget build(BuildContext c) => SpecialCollectionTab(
    workspace: view.space,
    section: WorkspaceSection.dues,
    records: view.dues,
    target: view.target,
    intro: 'alumni.dues_intro',
    record: 'specials.record_payment',
    add: 'alumni.add_pledge',
  );
}
