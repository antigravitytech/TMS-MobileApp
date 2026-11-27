part of '../attendance_screen.dart';

/// Clock-ins newest first, with this month's absent days among them.
class _AttendanceHistory extends StatelessWidget {
  const _AttendanceHistory({required this.records, required this.absent});
  final List<AttendanceRecord> records;
  final List<DateTime> absent;

  @override
  Widget build(BuildContext context) {
    final rows = <(DateTime, AttendanceRecord?)>[
      for (final r in records) (r.date, r),
      for (final day in absent)
        if (!records.any((r) => DateUtils.isSameDay(r.date, day))) (day, null),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    if (rows.isEmpty) {
      return DesignEmpty(
        context.tr('common.nothing_here'),
        context.tr('attendance.no_history'),
      );
    }
    final locale = context.locale.toString();
    return DesignCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, (date, record)) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, color: context.outline),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        Text(
                          DateFormat.E(locale).format(date),
                          style: TextStyle(color: context.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
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
                          record == null
                              ? '—'
                              : [
                                  _hm(context, record.clockIn),
                                  if (record.clockOut case final out?)
                                    _hm(context, out),
                                ].join(' – '),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          record == null
                              ? context.tr('attendance.no_clock_in')
                              : record.minutesWorked == null
                              ? context.tr('attendance.still_in')
                              : _duration(context, record.minutesWorked!),
                          style: TextStyle(fontSize: 12, color: context.muted),
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final (label, color) = _statusLook(
                        context,
                        record?.status ?? DayStatus.absent,
                      );
                      return _AttendanceTag(label, color);
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Who is in today.
class _AttendanceTeam extends StatelessWidget {
  const _AttendanceTeam(this.board);
  final List<BoardEntry> board;
  @override
  Widget build(BuildContext context) {
    final inCount = board.where((e) => e.status.present).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context
              .tr(
                'attendance.team_in',
                namedArgs: {'n': '$inCount', 'total': '${board.length}'},
              )
              .toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            color: context.muted,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 12),
        if (board.isEmpty)
          DesignEmpty(
            context.tr('common.nothing_here'),
            context.tr('attendance.no_team'),
          )
        else
          DesignCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, entry) in board.indexed) ...[
                  if (i > 0) Divider(height: 1, color: context.outline),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        DesignAvatar(
                          kitPerson(entry.name).$1,
                          color: kitPerson(entry.name).$2,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                switch (entry.record) {
                                  final r? => [
                                    context.tr(
                                      'attendance.in_at',
                                      namedArgs: {
                                        'time': _hm(context, r.clockIn),
                                      },
                                    ),
                                    if (r.place.isNotEmpty) r.place,
                                  ].join(' · '),
                                  null => context.tr('attendance.not_in_yet'),
                                },
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final (label, color) = _statusLook(
                              context,
                              entry.status,
                            );
                            return _AttendanceTag(label, color);
                          },
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
}
