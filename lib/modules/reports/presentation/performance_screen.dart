import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';

part 'widgets/performance_widgets.dart';

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
    actions: [
      DesignIcon(
        icon: TmsIcons.download,
        label: context.tr('reports.export_appraisal'),
        onPressed: () => TmsRoute.profile.open(context),
      ),
    ],
    children: [
      _PerformanceSegments(tab: tab, onChanged: (i) => setState(() => tab = i)),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            for (var i = 0; i < 4; i++)
              _PeriodChip(
                context.tr(
                  [
                    'reports.this_week',
                    'reports.this_month',
                    'reports.last_month',
                    'reports.this_quarter',
                  ][i],
                ),
                selected: period == i,
                onTap: () => setState(() => period = i),
              ),
          ],
        ),
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
      _PerformanceMetrics(team: tab == 1),
      if (tab == 0) ...[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xff203750), Color(0xff424587)],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Row(
            children: [
              const Icon(TmsIcons.badge, size: 34),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('reports.level_points'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.tr('reports.next_level'),
                      style: TextStyle(color: context.lavender),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: .64,
                      color: context.foreground,
                      backgroundColor: Colors.white24,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DesignButton(
          context.tr('reports.badges_history'),
          secondary: true,
          onPressed: () => TmsRoute.profile.open(context),
        ),
      ],
      if (tab == 1) ...[
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              DesignTitle(context.tr('reports.performance_thermometer')),
              DesignLabel(context.tr('reports.vs_original_targets')),
              Text(
                context.tr('reports.1_5_days'),
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
