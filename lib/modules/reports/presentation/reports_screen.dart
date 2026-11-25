import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int tab = 0, project = 0;
  bool blocked = false;
  final nudged = <String>{};
  String report =
      'Shortlisted 6 backend candidates. Drafted the Q4 hiring budget.';
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspacePreviewProvider);
    return DesignPage(
      title: context.tr('common.reports'),
      actions: [
        DesignIcon(
          icon: TmsIcons.insights,
          label: context.tr('common.performance'),
          onPressed: () => TmsRoute.performance.open(context),
        ),
      ],
      children: [
        DesignChoices(
          items: [
            context.tr('reports.log_today'),
            context.tr('reports.team_summaries'),
          ],
          selected: tab,
          onChanged: (i) => setState(() => tab = i),
        ),
        if (tab == 0 && state.reportSent) ...[
          DesignEmpty(
            context.tr('reports.report_sent'),
            context.tr('reports.ibrahim_has_it_thats_4_of_6'),
          ),
          Center(
            child: DesignPill(
              context.tr('reports.10_points_on_time'),
              color: DesignColor.green,
            ),
          ),
          DesignButton(
            context.tr('common.done'),
            onPressed: () => TmsRoute.home.open(context),
          ),
        ] else if (tab == 0) ...[
          DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                DesignTitle(context.tr('common.daily_status_update')),
                DesignLabel(context.tr('reports.for_ibrahim_musa')),
                DesignPill(
                  context.tr('reports.due_5_00_pm'),
                  color: DesignColor.amber,
                ),
              ],
            ),
          ),
          DesignField(
            label: context.tr('reports.what_did_you_get_done_today'),
            initialValue: report,
            lines: 4,
            onChanged: (value) => setState(() => report = value),
          ),
          DesignField(label: context.tr('reports.whats_next'), lines: 3),
          DesignTitle(context.tr('reports.link_to_a_project')),
          DesignChoices(
            items: [
              context.tr('reports.none'),
              'Tech Team',
              'Customer Portal Revamp',
            ],
            selected: project,
            onChanged: (i) => setState(() => project = i),
          ),
          DesignCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: Text(context.tr('reports.im_blocked')),
              subtitle: DesignLabel(
                context.tr('reports.flags_it_to_ibrahim_straight_away'),
              ),
              value: blocked,
              onChanged: (value) => setState(() => blocked = value),
            ),
          ),
          if (blocked)
            DesignField(
              label: context.tr('reports.what_is_blocking_you'),
              lines: 3,
            ),
          DesignButton(
            context.tr('reports.send_report'),
            icon: TmsIcons.send,
            onPressed: report.trim().isEmpty ? null : state.sendReport,
          ),
        ] else ...[
          DesignTitle(context.tr('reports.today_tech_team')),
          DesignLabel(context.tr('common.2_of_5_sent_1_blocker')),
          DesignSection(
            children: [
              for (final (initials, name, received) in [
                ('TB', 'Tunde Bakare', true),
                ('AE', 'Amaka Eze', true),
                ('DM', 'David Martins', false),
                ('SJ', 'Sarah Johnson', false),
              ])
                DesignTile(
                  title: name,
                  subtitle: received
                      ? context.tr('common.submitted')
                      : context.tr('reports.waiting_for_report'),
                  leading: DesignAvatar(initials),
                  trailing: received
                      ? const Icon(
                          TmsIcons.checkCircleFilled,
                          color: DesignColor.green,
                        )
                      : TextButton(
                          onPressed: nudged.contains(name)
                              ? null
                              : () {
                                  setState(() => nudged.add(name));
                                  designToast(
                                    context,
                                    context.tr(
                                      'reports.reminder_sent_to_name',
                                      namedArgs: {'name': name},
                                    ),
                                  );
                                },
                          child: Text(
                            nudged.contains(name)
                                ? context.tr('reports.sent')
                                : context.tr('reports.nudge'),
                          ),
                        ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});
  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  int tab = 0, period = 1;
  @override
  Widget build(BuildContext context) => DesignPage(
    title: context.tr('common.performance'),
    children: [
      DesignChoices(
        items: [context.tr('common.me'), context.tr('reports.my_team')],
        selected: tab,
        onChanged: (i) => setState(() => tab = i),
      ),
      DesignChoices(
        items: [
          context.tr('reports.this_week'),
          context.tr('reports.this_month'),
          context.tr('reports.last_month'),
          context.tr('reports.this_quarter'),
        ],
        selected: period,
        onChanged: (i) => setState(() => period = i),
      ),
      DesignLabel(
        context.tr(
          'reports.compared_with_previous',
          namedArgs: {
            'period': context.tr(
              const [
                'reports.range_week',
                'reports.range_month',
                'reports.range_last_month',
                'reports.range_quarter',
              ][period],
            ),
          },
        ),
      ),
      DesignCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            DesignTitle(context.tr('reports.performance_thermometer')),
            DesignLabel(context.tr('reports.vs_original_targets')),
            Text(
              tab == 0
                  ? context.tr('reports.1_5_days')
                  : context.tr('reports.2_2_days'),
              style: TextStyle(
                color: tab == 0 ? DesignColor.rose : DesignColor.green,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            DesignLabel(
              tab == 0
                  ? context.tr(
                      'reports.time_lost_against_original_targets_this_month',
                    )
                  : context.tr(
                      'reports.time_saved_against_original_targets_this_month',
                    ),
            ),
            const _Thermometer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DesignLabel(context.tr('reports.lost')),
                DesignLabel(context.tr('reports.on_target')),
                DesignLabel(context.tr('reports.saved')),
              ],
            ),
          ],
        ),
      ),
      DesignCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            DesignTitle(context.tr('reports.completed_vs_returned')),
            DesignLabel(context.tr('reports.per_week')),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < 8; i++)
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 2,
                        children: [
                          _Bar(
                            height: 36 + (i * 13 + period * 7 + tab * 9) % 79,
                            color: DesignColor.green,
                          ),
                          _Bar(
                            height: 12 + i * 8 % 32,
                            color: DesignColor.rose,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(child: DesignLabel(context.tr('reports.5_oct'))),
                Expanded(
                  child: Center(
                    child: DesignLabel(context.tr('reports.19_oct')),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: DesignLabel(context.tr('reports.2_nov')),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: DesignLabel(context.tr('reports.16_nov')),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                DesignPill(
                  context.tr('common.completed'),
                  color: DesignColor.green,
                ),
                DesignPill(
                  context.tr('common.returned'),
                  color: DesignColor.rose,
                ),
              ],
            ),
          ],
        ),
      ),
      DesignTitle(context.tr('reports.needs_attention')),
      DesignSection(
        children: [
          DesignTile(
            title: 'Regression test plan for portal',
            subtitle: context.tr('reports.2_days_late_david'),
            icon: TmsIcons.warning,
            onTap: () => TmsRoute.task.open(context),
          ),
          DesignTile(
            title: 'Refactor auth middleware',
            subtitle: context.tr('reports.1_day_late_tunde'),
            icon: TmsIcons.clock,
            onTap: () => TmsRoute.task.open(context),
          ),
        ],
      ),
    ],
  );
}

class _Thermometer extends StatelessWidget {
  const _Thermometer();
  @override
  Widget build(BuildContext context) => Container(
    height: 12,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [DesignColor.red, DesignColor.amber, DesignColor.green],
      ),
    ),
  );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});
  final int height;
  final Color color;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: DesignMotion.duration(context, DesignMotion.object),
    height: height.toDouble(),
    width: 8,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(5),
    ),
  );
}
