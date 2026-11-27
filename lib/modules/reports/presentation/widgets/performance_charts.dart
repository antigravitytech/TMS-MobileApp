part of '../performance_screen.dart';

class _LevelCard extends StatelessWidget {
  const _LevelCard(this.level);
  final ({int level, int points, int toNext, double progress}) level;
  @override
  Widget build(BuildContext context) => Container(
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
                context.tr(
                  'reports.level_points',
                  namedArgs: {
                    'level': '${level.level}',
                    'points': '${level.points}',
                  },
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.tr(
                  'reports.next_level',
                  namedArgs: {
                    'points': '${level.toNext}',
                    'level': '${level.level + 1}',
                  },
                ),
                style: TextStyle(color: context.lavender),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: level.progress,
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
  );
}

/// The thermometer: days saved (or lost) against original targets.
class _SavedDays extends StatelessWidget {
  const _SavedDays(this.days);
  final double days;
  @override
  Widget build(BuildContext context) {
    final saved = days >= 0;
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          DesignTitle(context.tr('reports.performance_thermometer')),
          DesignLabel(context.tr('reports.vs_original_targets')),
          Text(
            context.tr(
              'reports.days_signed',
              namedArgs: {
                'sign': saved ? '+' : '−',
                'n': _number(context, days.abs()),
              },
            ),
            style: TextStyle(
              color: saved ? DesignColor.green : DesignColor.rose,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          DesignLabel(
            context.tr(
              saved
                  ? 'reports.time_saved_against_original_targets'
                  : 'reports.time_lost_against_original_targets',
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
    );
  }
}

/// Completed and returned per week.
class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars(this.weeks);
  final List<(String, int, int)> weeks;
  @override
  Widget build(BuildContext context) {
    final top = weeks
        .expand((w) => [w.$2, w.$3])
        .fold(1, (a, b) => a > b ? a : b);
    int height(int n) => (n / top * 110).round().clamp(n == 0 ? 0 : 6, 110);
    return DesignCard(
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
                for (final (_, done, back) in weeks)
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 2,
                      children: [
                        _Bar(height: height(done), color: DesignColor.green),
                        _Bar(height: height(back), color: DesignColor.rose),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final i in {
                0,
                weeks.length ~/ 3,
                weeks.length * 2 ~/ 3,
                weeks.length - 1,
              })
                DesignLabel(weeks[i].$1),
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
    );
  }
}
