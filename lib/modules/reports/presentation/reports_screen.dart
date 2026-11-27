import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../../shared/kit/kit.dart';
import '../../tasks/presentation/tasks_screen.dart' show taskErrorMessage;
import '../application/reports_controller.dart';
import '../domain/report.dart';

export 'performance_screen.dart';
part 'widgets/report_widgets.dart';
part 'widgets/report_form.dart';
part 'widgets/team_summaries.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int tab = 0;

  Widget _states<T>(
    AsyncValue<T> value,
    VoidCallback retry,
    Widget Function(T) data,
  ) => switch (value) {
    AsyncValue(hasValue: true, :final value) => data(value as T),
    AsyncValue(:final error?) => Column(
      spacing: 12,
      children: [
        DesignLabel(taskErrorMessage(context, error)),
        DesignButton(
          context.tr('workspaces.try_again'),
          secondary: true,
          onPressed: retry,
        ),
      ],
    ),
    _ => const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: CircularProgressIndicator()),
    ),
  };

  @override
  Widget build(BuildContext context) => DesignPage(
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
      if (tab == 0)
        _states(
          ref.watch(dailyReportProvider),
          () => ref.invalidate(dailyReportProvider),
          (report) => switch (report) {
            null => DesignEmpty(
              context.tr('common.nothing_here'),
              context.tr('reports.no_report_due'),
            ),
            final r when r.sent => _ReportSent(r),
            final r => _ReportForm(key: ValueKey(r.routineId), report: r),
          },
        )
      else
        _states(
          ref.watch(teamReportsProvider),
          () => ref.invalidate(teamReportsProvider),
          (team) => team == null
              ? DesignEmpty(
                  context.tr('common.nothing_here'),
                  context.tr('reports.no_team_reports'),
                )
              : _TeamSummaries(team),
        ),
    ],
  );
}

/// The "Report sent" view.
class _ReportSent extends StatelessWidget {
  const _ReportSent(this.report);
  final DailyReport report;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      const SizedBox(height: 44),
      const _ReportSuccessMark(),
      Text(
        context.tr('reports.report_sent'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
      Text(
        report.reviewer.isEmpty
            ? context.tr('reports.report_saved')
            : context.tr(
                'reports.reviewer_has_it',
                namedArgs: {'name': report.reviewer.split(' ').first},
              ),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: context.muted),
      ),
      if (report.points case final points?)
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
                      context.tr(
                        'reports.plus_points',
                        namedArgs: {'n': '$points'},
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (report.dueTime.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.tr(
                          'reports.on_time_before_time',
                          namedArgs: {'time': report.dueTime},
                        ),
                        style: TextStyle(color: context.muted, fontSize: 12),
                      ),
                    ],
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
    ],
  );
}
