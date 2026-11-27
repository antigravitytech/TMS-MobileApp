import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/kit_controls.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/club_controller.dart';
import '../../data/club_reference.dart';

class ClubOverview extends StatelessWidget {
  const ClubOverview({super.key, required this.view, required this.onTab});
  final ClubView view;
  final ValueChanged<ClubTab> onTab;
  @override
  Widget build(BuildContext c) {
    final locale = c.locale.toString();
    final season = view.season;
    final next = view.upcoming.firstOrNull;
    final demo = view.space.records.any((r) => r.id.startsWith(clubRefPrefix));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        if (season?.date != null)
          DesignEntrance(
            child: SpecialCountdownHero(
              days: daysUntil(season!.date!, view.today),
              chip: c.tr('club.chip'),
              title: season.title,
              line: c.tr(
                'club.season_line',
                namedArgs: {
                  'date': DateFormat.MMMEd(locale).format(season.date!),
                  'n': '${view.members}',
                },
              ),
              intro: c.tr('club.intro'),
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
                  ? c.tr('club.kpi.no_session')
                  : '${next.title} · ${DateFormat.Hm(locale).format(next.date!)}',
              TmsIcons.calendar,
              DesignColor.blue,
              () => onTab(ClubTab.sessions),
            ),
            (
              specialMoney(c, view.collected),
              c.plural(
                'club.kpi.fees',
                view.owing,
                namedArgs: {'target': specialMoney(c, view.target)},
              ),
              TmsIcons.card,
              DesignColor.green,
              () => onTab(ClubTab.fees),
            ),
            (
              '${view.marked(0)}/${view.attendance.length}',
              c.tr('club.kpi.coming'),
              TmsIcons.people,
              DesignColor.amber,
              () => onTab(ClubTab.attendance),
            ),
            (
              '${view.notices.length}',
              view.notices.isEmpty
                  ? c.tr('club.kpi.no_notice')
                  : c.plural('club.kpi.notices', view.notices.length),
              TmsIcons.announcement,
              null,
              () => onTab(ClubTab.notices),
            ),
          ]),
        ),
        if (demo) ...[
          const SizedBox(height: 12),
          DesignEntrance(
            order: 2,
            child: SpecialWorkersCard(
              title: c.tr('club.workers_title'),
              blockers: c.tr('club.workers_blockers'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Attendance tab: counts per mark, then each member with a
/// Present / Maybe / Absent switch.
class ClubAttendance extends ConsumerWidget {
  const ClubAttendance({
    super.key,
    required this.workspace,
    required this.view,
    required this.actions,
  });
  final LocalWorkspace workspace;
  final ClubView view;
  final ClubController actions;
  static const _tones = [KitColor.done, KitColor.submitted, KitColor.overdue];

  @override
  Widget build(BuildContext c, WidgetRef ref) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
    children: [
      specialIntro(c, 'club.attendance_intro'),
      DesignEntrance(
        child: Row(
          spacing: 8,
          children: [
            for (final (i, m) in attendanceMarks.indexed)
              Expanded(
                child: KitCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${view.marked(i)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _tones[i],
                        ),
                      ),
                      Text(
                        c.tr('club.marks.$m'),
                        style: TextStyle(fontSize: 11.5, color: c.muted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (view.attendance.isEmpty)
        const SpecialEmpty('attendance')
      else
        DesignEntrance(
          order: 1,
          child: KitList(
            children: [
              for (final a in view.attendance)
                Padding(
                  key: ValueKey(a.id),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        spacing: 12,
                        children: [
                          DesignAvatar(
                            kitPerson(a.title).$1,
                            size: 40,
                            color: kitPerson(a.title).$2,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  [
                                    a.person,
                                    a.group,
                                  ].where((s) => s.isNotEmpty).join(' · '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      KitSegment<int>(
                        values: const [0, 1, 2],
                        selected: a.mark,
                        label: (i) => c.tr('club.marks.${attendanceMarks[i]}'),
                        onChanged: (i) async {
                          final ok = await actions.mark(a, i);
                          if (!ok && c.mounted) {
                            designToast(c, c.tr('workspaces.try_again'));
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      const SizedBox(height: 12),
      DesignButton(
        c.tr('club.add_member'),
        secondary: true,
        onPressed: () =>
            addSpecialRecord(c, ref, workspace, WorkspaceSection.attendance),
      ),
    ],
  );
}
