part of '../attendance_screen.dart';

class _AttendanceTabs extends StatelessWidget {
  const _AttendanceTabs(this.tab, this.onChanged);
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
        for (var i = 0; i < 3; i++)
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
                  context.tr(
                    ['common.today', 'attendance.history', 'common.team'][i],
                  ),
                  style: TextStyle(
                    color: tab == i ? context.foreground : context.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _AttendanceTag extends StatelessWidget {
  const _AttendanceTag(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      '•  $label',
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
    ),
  );
}

class _AttendanceMonth extends StatelessWidget {
  const _AttendanceMonth(this.stats);
  final AttendanceStats stats;

  /// Weekday cells by week, Monday first; null where the month hasn't
  /// reached yet.
  List<List<(DateTime, DayStatus)?>> get _weeks {
    final weeks = <List<(DateTime, DayStatus)?>>[];
    for (final day in stats.days) {
      final (date, _) = day;
      if (date.weekday > DateTime.friday) continue;
      if (weeks.isEmpty || date.weekday == DateTime.monday) {
        weeks.add(List.filled(5, null));
      }
      weeks.last[date.weekday - 1] = day;
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final counts = [
      (stats.early, 'attendance.early', DesignColor.teal),
      (stats.onTime, 'common.on_time', DesignColor.green),
      (stats.late, 'attendance.late', DesignColor.amber),
      (stats.absent, 'attendance.absent', DesignColor.red),
    ];
    return DesignCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: stats.punctuality / 100,
                        strokeWidth: 10,
                        color: DesignColor.purple,
                        backgroundColor: const Color(0xff303241),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${stats.punctuality}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          context.tr('common.on_time'),
                          style: TextStyle(fontSize: 12, color: context.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  children: [
                    for (final row in [0, 1])
                      Row(
                        children: [
                          for (final (value, key, color)
                              in counts.skip(row * 2).take(2))
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$value',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      context.tr(key),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (final week in _weeks)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                spacing: 6,
                children: [
                  for (final cell in week)
                    Expanded(
                      child: Container(
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cell == null
                              ? Colors.transparent
                              : switch (cell.$2) {
                                  DayStatus.early => DesignColor.teal,
                                  DayStatus.onTime => DesignColor.green,
                                  DayStatus.late => DesignColor.amber,
                                  DayStatus.absent => DesignColor.red,
                                  _ => context.raised,
                                },
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: cell == null
                            ? null
                            : Text(
                                '${cell.$1.day}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      cell.$2.present ||
                                          cell.$2 == DayStatus.absent
                                      ? DesignColor.ink
                                      : context.muted,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${DateTime.now().day}',
              style: TextStyle(
                color: context.lavender,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            children: [
              for (final (_, key, color) in counts)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr(key),
                      style: TextStyle(fontSize: 11, color: context.muted),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceMetrics extends StatelessWidget {
  const _AttendanceMetrics(this.stats);
  final AttendanceStats stats;
  @override
  Widget build(BuildContext context) {
    final cards = [
      ('attendance.usual_arrival', stats.avgIn ?? '–'),
      ('attendance.usual_leaving', stats.avgOut ?? '–'),
      ('attendance.time_logged', _duration(context, stats.minutesWorked)),
      (
        'attendance.late_arrivals',
        stats.lateLimit == null
            ? '${stats.late}'
            : context.tr(
                'attendance.late_of_limit',
                namedArgs: {
                  'n': '${stats.late}',
                  'limit': '${stats.lateLimit}',
                },
              ),
      ),
    ];
    return Column(
      children: [
        for (var row = 0; row < 2; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              spacing: 10,
              children: [
                for (final (label, value) in cards.skip(row * 2).take(2))
                  Expanded(
                    child: DesignCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(label),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.muted,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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
