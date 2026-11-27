import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../tasks/presentation/tasks_screen.dart' show taskErrorMessage;
import '../application/reports_controller.dart';
import '../domain/report.dart';

part 'widgets/performance_widgets.dart';
part 'widgets/performance_charts.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});
  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen> {
  int tab = 0;
  ReportPeriod period = ReportPeriod.thisMonth;

  @override
  Widget build(BuildContext context) {
    final provider = performanceProvider((tab == 1, period));
    final async = ref.watch(provider);
    final data = async.value;
    final locale = context.locale.toString();
    return DesignPage(
      title: context.tr('common.performance'),
      actions: [
        DesignIcon(
          icon: TmsIcons.download,
          label: context.tr('reports.export_appraisal'),
          onPressed: () => TmsRoute.profile.open(context),
        ),
      ],
      children: [
        _PerformanceSegments(
          tab: tab,
          onChanged: (i) => setState(() => tab = i),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final p in ReportPeriod.values)
                _PeriodChip(
                  context.tr(
                    'reports.${p.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')}',
                  ),
                  selected: period == p,
                  onTap: () => setState(() => period = p),
                ),
            ],
          ),
        ),
        if (data == null && async.hasError) ...[
          DesignLabel(taskErrorMessage(context, async.error)),
          DesignButton(
            context.tr('workspaces.try_again'),
            secondary: true,
            onPressed: () => ref.invalidate(provider),
          ),
        ] else if (data == null)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          DesignLabel(
            context.tr(
              'reports.compared_with_previous',
              namedArgs: {
                'period':
                    '${DateFormat('d MMM', locale).format(data.from)} – ${DateFormat('d MMM', locale).format(data.to)}',
              },
            ),
          ),
          _PerformanceMetrics(
            team: tab == 1,
            metrics: [
              for (final key
                  in tab == 1
                      ? const [
                          'completed',
                          'on_time_rate',
                          'first_time_right_rate',
                          'average_rounds',
                        ]
                      : const [
                          'completed',
                          'on_time_streak',
                          'on_time_rate',
                          'recurring_compliance',
                          'punctuality',
                          'first_time_right_rate',
                        ])
                ?data.metric(key),
            ].take(4).toList(),
          ),
          if (data.level case final level? when tab == 0) ...[
            _LevelCard(level),
            DesignButton(
              context.tr('reports.badges_history'),
              secondary: true,
              onPressed: () => TmsRoute.profile.open(context),
            ),
          ],
          if (tab == 1) ...[
            if (data.metric('saved_days') case final saved?)
              _SavedDays(saved.value.toDouble()),
            if (data.weekly.isNotEmpty) _WeeklyBars(data.weekly),
            if (data.attention.isNotEmpty) ...[
              DesignTitle(context.tr('reports.needs_attention')),
              DesignSection(
                children: [
                  for (final (title, why) in data.attention)
                    DesignTile(
                      title: title,
                      subtitle: why,
                      icon: TmsIcons.warning,
                    ),
                ],
              ),
            ],
          ],
        ],
        OutlinedButton(
          onPressed: () => TmsRoute.profile.open(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            foregroundColor: context.foreground,
            side: BorderSide(color: context.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(TmsIcons.download, size: 17),
              const SizedBox(width: 8),
              Text(context.tr('reports.export_appraisal')),
            ],
          ),
        ),
      ],
    );
  }
}
