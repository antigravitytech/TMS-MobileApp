part of '../performance_screen.dart';

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

class _PerformanceSegments extends StatelessWidget {
  const _PerformanceSegments({required this.tab, required this.onChanged});
  final int tab;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: context.panel,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: context.outline),
    ),
    child: Row(
      children: [
        for (var i = 0; i < 2; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: DesignMotion.fast,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tab == i ? context.raised : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  context.tr(i == 0 ? 'common.me' : 'reports.my_team'),
                  style: TextStyle(
                    color: tab == i ? context.foreground : context.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? context.foreground : Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: context.outline),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? context.background : context.muted,
          ),
        ),
      ),
    ),
  );
}

/// The design's label for an overview metric.
const _metricLabels = {
  'completed': 'tasks_completed',
  'on_time_rate': 'on_time_rate',
  'first_time_right_rate': 'first_time_right',
  'average_rounds': 'rework_rounds',
  'recurring_compliance': 'daily_reports',
  'on_time_streak': 'on_time_streak',
  'punctuality': 'punctuality',
};

String _number(BuildContext context, num value) =>
    NumberFormat.decimalPattern(context.locale.toString()).format(
      value is int || value == value.roundToDouble()
          ? value.round()
          : double.parse(value.toStringAsFixed(1)),
    );

String _metricValue(BuildContext context, PerfMetric m) => switch (m.unit) {
  '%' => '${m.value.round()}%',
  'days' => context.plural('reports.days_count', m.value.round()),
  _ => _number(context, m.value),
};

/// "▲ 3", "▼ 2 pts" or "No change", unless the metric has its own note.
String _metricCaption(BuildContext context, PerfMetric m) {
  if (m.note case final note?) return note;
  if (m.delta == 0) return context.tr('reports.no_change');
  final arrow = m.delta > 0 ? '▲' : '▼';
  final size = _number(context, m.delta.abs());
  return m.unit == '%' ? '$arrow $size pts' : '$arrow $size';
}

class _PerformanceMetrics extends StatelessWidget {
  const _PerformanceMetrics({required this.team, required this.metrics});
  final bool team;
  final List<PerfMetric> metrics;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var row = 0; row * 2 < metrics.length; row++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            spacing: 12,
            children: [
              for (final m in metrics.skip(row * 2).take(2))
                Expanded(
                  child: DesignCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            'reports.metric_${_metricLabels[m.key] ?? m.key}',
                          ),
                          style: TextStyle(fontSize: 12, color: context.muted),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _metricValue(context, m),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _metricCaption(context, m),
                          style: TextStyle(
                            fontSize: 12,
                            color: m.note != null || m.delta == 0
                                ? context.muted
                                // Fewer rework rounds is better.
                                : (m.delta > 0) != (m.key == 'average_rounds')
                                ? DesignColor.green
                                : DesignColor.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (metrics.skip(row * 2).length == 1) const Spacer(),
            ],
          ),
        ),
    ],
  );
}
