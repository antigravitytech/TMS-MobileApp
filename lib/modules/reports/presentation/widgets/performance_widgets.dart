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

class _PerformanceMetrics extends StatelessWidget {
  const _PerformanceMetrics({required this.team});
  final bool team;
  @override
  Widget build(BuildContext context) {
    final labels = team
        ? [
            'tasks_completed',
            'on_time_rate',
            'first_time_right',
            'rework_rounds',
          ]
        : ['tasks_completed', 'on_time_streak', 'daily_reports', 'punctuality'];
    return Column(
      children: [
        for (var row = 0; row < 2; row++)
          Padding(
            padding: EdgeInsets.only(bottom: row == 0 ? 12 : 0),
            child: Row(
              spacing: 12,
              children: [
                for (var col = 0; col < 2; col++)
                  Expanded(
                    child: DesignCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              'reports.metric_${labels[row * 2 + col]}',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr(
                              'reports.metric_value_${team ? 'team' : 'me'}_${row * 2 + col}',
                            ),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr(
                              'reports.metric_caption_${team ? 'team' : 'me'}_${row * 2 + col}',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: team
                                  ? (row == 1 && col == 1
                                        ? DesignColor.red
                                        : DesignColor.green)
                                  : context.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
