part of '../attendance_screen.dart';

class _AttendanceHistory extends StatelessWidget {
  const _AttendanceHistory();
  @override
  Widget build(BuildContext context) => DesignCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final (date, time, duration, status, color) in [
          (20, '8:47 – 17:31', '8h 44m', 'attendance.early', DesignColor.green),
          (19, '—', 'No clock-in', 'attendance.absent', DesignColor.red),
          (18, '9:04 – 17:22', '8h 18m', 'common.on_time', DesignColor.green),
          (17, '9:10 – 17:40', '8h 30m', 'common.on_time', DesignColor.green),
          (16, '9:41 – 17:35', '7h 54m', 'attendance.late', DesignColor.amber),
          (13, '9:02 – 17:20', '8h 18m', 'common.on_time', DesignColor.green),
        ]) ...[
          if (date != 20) Divider(height: 1, color: context.outline),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      Text(
                        DateFormat.E(
                          context.locale.toString(),
                        ).format(DateTime(2026, 11, date)),
                        style: TextStyle(color: context.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$date',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        date == 19
                            ? context.tr('attendance.no_clock_in')
                            : duration,
                        style: TextStyle(fontSize: 12, color: context.muted),
                      ),
                    ],
                  ),
                ),
                _AttendanceTag(context.tr(status), color),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _AttendanceTeam extends StatelessWidget {
  const _AttendanceTeam();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.tr('attendance.team_in_count'),
        style: TextStyle(
          fontSize: 11,
          color: context.muted,
          fontWeight: FontWeight.w700,
          letterSpacing: .8,
        ),
      ),
      const SizedBox(height: 12),
      DesignCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final (initials, name, color, key, status) in [
              (
                'TB',
                'Tunde Bakare',
                DesignColor.teal,
                'attendance.tunde_arrival',
                'attendance.early',
              ),
              (
                'DM',
                'David Mensah',
                const Color(0xffbcd995),
                'attendance.david_arrival',
                'common.on_time',
              ),
              (
                'AE',
                'Amaka Eze',
                const Color(0xffeeabb0),
                'attendance.amaka_arrival',
                'attendance.late',
              ),
              (
                'SJ',
                'Sarah Johnson',
                DesignColor.amber,
                'attendance.not_in_yet',
                'attendance.expected',
              ),
            ]) ...[
              if (initials != 'TB') Divider(height: 1, color: context.outline),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    DesignAvatar(initials, color: color, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(key),
                            style: TextStyle(
                              fontSize: 11,
                              color: context.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _AttendanceTag(
                      context.tr(status),
                      initials == 'AE'
                          ? DesignColor.amber
                          : initials == 'SJ'
                          ? context.muted
                          : DesignColor.green,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
