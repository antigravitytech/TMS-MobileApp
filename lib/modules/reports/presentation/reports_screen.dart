import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

export 'performance_screen.dart';
part 'widgets/report_widgets.dart';
part 'widgets/team_summaries.dart';

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
        TextButton(
          onPressed: () => TmsRoute.performance.open(context),
          child: Text(
            context.tr('common.performance'),
            style: TextStyle(
              color: context.lavender,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      children: [
        _ReportTabs(tab: tab, onChanged: (i) => setState(() => tab = i)),
        if (tab == 0 && state.reportSent) ...[
          const SizedBox(height: 60),
          const _ReportSuccessMark(),
          const SizedBox(height: 16),
          Text(
            context.tr('reports.report_sent'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          Text(
            context.tr('reports.ibrahim_has_it_thats_4_of_6'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.muted),
          ),
          const SizedBox(height: 16),
          DesignCard(
            child: Row(
              children: [
                const Icon(TmsIcons.flame, color: Color(0xfff59562)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('reports.points'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('reports.on_time_before'),
                        style: TextStyle(color: context.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => TmsRoute.home.open(context),
            style: OutlinedButton.styleFrom(
              backgroundColor: context.raised,
              foregroundColor: context.foreground,
              minimumSize: const Size(double.infinity, 52),
              side: BorderSide(color: context.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(context.tr('common.done')),
          ),
        ] else if (tab == 0) ...[
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DesignColor.teal.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: DesignColor.teal.withValues(alpha: .25),
                  ),
                ),
                child: const Icon(
                  TmsIcons.edit,
                  color: DesignColor.teal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('common.daily_status_update'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('reports.for_ibrahim_musa'),
                      style: TextStyle(color: context.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: DesignColor.amber.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '•  ${context.tr('reports.due_5_00_pm')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: DesignColor.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          DesignLabel(context.tr('reports.what_did_you_get_done_today')),
          _ReportInput(
            initialValue: report,
            lines: 3,
            onChanged: (v) => setState(() => report = v),
          ),
          DesignLabel(context.tr('reports.whats_next')),
          _ReportInput(hint: context.tr('reports.tomorrows_focus'), lines: 2),
          DesignLabel(context.tr('reports.link_to_a_project')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < 3; i++)
                _ReportChip(
                  i == 0
                      ? context.tr('common.standalone')
                      : ['', 'Customer Portal Revamp', 'Mobile App Launch'][i],
                  selected: project == i,
                  onTap: () => setState(() => project = i),
                ),
            ],
          ),
          DesignCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DesignColor.red.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: DesignColor.red.withValues(alpha: .3),
                    ),
                  ),
                  child: const Icon(
                    TmsIcons.warning,
                    color: DesignColor.red,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('reports.im_blocked'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        context.tr('reports.flags_it_to_ibrahim_straight_away'),
                        style: TextStyle(color: context.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => blocked = !blocked),
                  child: AnimatedContainer(
                    duration: DesignMotion.fast,
                    width: 52,
                    height: 32,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: blocked
                          ? DesignColor.purple
                          : context.foreground.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AnimatedAlign(
                      duration: DesignMotion.fast,
                      alignment: blocked
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: context.foreground,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (blocked)
            DesignField(
              label: context.tr('reports.what_is_blocking_you'),
              lines: 3,
            ),
          DesignButton(
            context.tr('reports.send_report'),
            onPressed: report.trim().isEmpty ? null : state.sendReport,
          ),
        ] else ...[
          _TeamSummaries(
            nudged: nudged,
            onNudge: (name) {
              setState(() => nudged.add(name));
              designToast(
                context,
                context.tr(
                  'reports.reminder_sent_to_name',
                  namedArgs: {'name': name},
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
