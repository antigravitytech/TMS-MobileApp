import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../specials/presentation/widgets/special_hero.dart';
import '../../../workspace/presentation/widgets/workspace_ui.dart';
import '../../application/church_controller.dart';
import '../../data/church_reference.dart';

class ChurchOverview extends StatelessWidget {
  const ChurchOverview({super.key, required this.view, required this.onTab});
  final ChurchView view;
  final ValueChanged<ChurchTab> onTab;
  @override
  Widget build(BuildContext c) {
    final event = view.highlight;
    final demo = view.space.records.any(
      (r) => r.id.startsWith(churchRefPrefix),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        if (event != null)
          DesignEntrance(
            child: SpecialCountdownHero(
              days: daysUntil(event.date!, view.today),
              chip: view.space.kind.label(c),
              title: event.title,
              line: c.tr(
                'church.event_line',
                namedArgs: {
                  'date': DateFormat.MMMEd(
                    c.locale.toString(),
                  ).format(event.date!),
                  'members': '${view.members}',
                },
              ),
              intro: c.tr('church.intro'),
            ),
          ),
        const SizedBox(height: 12),
        DesignEntrance(
          order: 1,
          child: SpecialKpiGrid([
            (
              '${view.lastSunday}',
              c.tr('church.kpi.attendance'),
              TmsIcons.people,
              DesignColor.blue,
              () => onTab(ChurchTab.services),
            ),
            (
              specialMoney(c, view.givingTotal),
              c.tr('church.kpi.giving'),
              TmsIcons.giving,
              DesignColor.green,
              () => onTab(ChurchTab.giving),
            ),
            (
              '${view.openPrayers}',
              c.tr('church.kpi.prayer'),
              TmsIcons.heart,
              DesignColor.amber,
              () => onTab(ChurchTab.prayer),
            ),
            (
              '${view.notCalled}',
              c.tr('church.kpi.first_timers'),
              TmsIcons.addPerson,
              DesignColor.red,
              () => onTab(ChurchTab.firstTimers),
            ),
          ]),
        ),
        if (demo) ...[
          const SizedBox(height: 12),
          DesignEntrance(
            order: 2,
            child: SpecialWorkersCard(
              title: c.tr('church.workers_title'),
              blockers: c.tr('church.workers_blockers'),
            ),
          ),
        ],
      ],
    );
  }
}
