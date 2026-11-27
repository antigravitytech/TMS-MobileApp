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
  const _AttendanceMonth();
  @override
  Widget build(BuildContext context) => DesignCard(
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
                  const SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: .8,
                      strokeWidth: 10,
                      color: DesignColor.purple,
                      backgroundColor: Color(0xff303241),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '80%',
                        style: TextStyle(
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
                        for (final col in [0, 1])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ['2', '10', '1', '2'][row * 2 + col],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: [
                                        DesignColor.teal,
                                        DesignColor.green,
                                        DesignColor.amber,
                                        DesignColor.red,
                                      ][row * 2 + col],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    context.tr(
                                      [
                                        'attendance.early',
                                        'common.on_time',
                                        'attendance.late',
                                        'attendance.absent',
                                      ][row * 2 + col],
                                    ),
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
        for (var week = 0; week < 3; week++)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              spacing: 6,
              children: [
                for (var day = 0; day < 5; day++)
                  Expanded(
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: [5, 16].contains(week * 7 + day + 2)
                            ? DesignColor.teal
                            : week * 7 + day + 2 == 10
                            ? DesignColor.amber
                            : [12, 20].contains(week * 7 + day + 2)
                            ? DesignColor.red
                            : DesignColor.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${week * 7 + day + 2}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: DesignColor.ink,
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
            '23',
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
            for (final (key, color) in [
              ('attendance.early', DesignColor.teal),
              ('common.on_time', DesignColor.green),
              ('attendance.late', DesignColor.amber),
              ('attendance.absent', DesignColor.red),
            ])
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

class _AttendanceMetrics extends StatelessWidget {
  const _AttendanceMetrics();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var row = 0; row < 2; row++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            spacing: 10,
            children: [
              for (var col = 0; col < 2; col++)
                Expanded(
                  child: DesignCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            [
                              'attendance.usual_arrival',
                              'attendance.usual_leaving',
                              'attendance.time_logged',
                              'attendance.late_arrivals',
                            ][row * 2 + col],
                          ),
                          style: TextStyle(fontSize: 12, color: context.muted),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          [
                            '9:01',
                            '17:25',
                            context.tr('attendance.109h_19m'),
                            context.tr('attendance.one_of_five'),
                          ][row * 2 + col],
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
