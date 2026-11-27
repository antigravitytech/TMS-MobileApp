part of '../home_screen.dart';

class _DailyReport extends StatelessWidget {
  const _DailyReport({required this.sent});
  final bool sent;
  @override
  Widget build(BuildContext context) => DesignCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Row(
          spacing: 12,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DesignColor.teal.withValues(alpha: .12),
                border: Border.all(
                  color: DesignColor.teal.withValues(alpha: .22),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                TmsIcons.edit,
                color: DesignColor.teal,
                size: 20,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('common.daily_status_update'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _HomeCaption(context.tr('home.for_ibrahim_musa_weekdays')),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            for (final (index, key) in const [
              'home.t',
              'home.w',
              'home.t',
              'home.f',
              'home.f',
              'common.today',
            ].indexed)
              Expanded(
                child: Column(
                  spacing: 6,
                  children: [
                    _ReportDay(
                      missed: index == 0 || index == 3,
                      pending: index == 5 && !sent,
                    ),
                    Text(
                      context.tr(key),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: context.muted),
                    ),
                  ],
                ),
              ),
          ],
        ),
        _CardButton(
          context.tr(
            sent ? 'home.view_daily_report' : 'home.log_todays_report',
          ),
          color: context.foreground,
          background: context.raised,
          border: context.outline,
          onPressed: () => TmsRoute.reports.open(context),
        ),
      ],
    ),
  );
}

class _ReportDay extends StatelessWidget {
  const _ReportDay({required this.missed, required this.pending});
  final bool missed, pending;
  @override
  Widget build(BuildContext context) {
    if (pending) {
      return const CustomPaint(size: Size.square(26), painter: _DashedDay());
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: missed ? null : DesignColor.green,
        border: missed ? Border.all(color: DesignColor.red, width: 1.6) : null,
      ),
      child: missed
          ? null
          : const Icon(TmsIcons.check, size: 14, color: DesignColor.ink),
    );
  }
}

class _DashedDay extends CustomPainter {
  const _DashedDay();
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = DesignColor.purple
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final ring = (Offset.zero & size).deflate(1);
    for (var i = 0; i < 10; i++) {
      canvas.drawArc(ring, 2 * math.pi * i / 10, .39, false, pen);
    }
  }

  @override
  bool shouldRepaint(_DashedDay oldDelegate) => false;
}

class _LiveDailyReport extends StatelessWidget {
  const _LiveDailyReport({
    required this.report,
    required this.actions,
    required this.busy,
  });

  final DashboardJson report;
  final LiveHomeActions actions;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final routine = dashboardObject(report['routine']);
    final occurrence = dashboardObject(report['current_occurrence']);
    final dateFormat = DateFormat.E(context.locale.toString());
    final history = dashboardRows(report['occurrences']);
    final due = dashboardText(routine['due_time']);
    final sent = occurrence['log'] != null;
    final routineId = routine['id'];
    final occurrenceDate = occurrence['date'];
    final canLog =
        occurrence['can_log'] == true &&
        routineId is String &&
        occurrenceDate is String &&
        occurrence['log'] == null;
    return DesignCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 12,
            children: [
              const Icon(TmsIcons.edit, color: DesignColor.teal),
              Expanded(
                child: Text(
                  dashboardText(routine['title']),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (sent || due.isNotEmpty)
            _HomeCaption(
              sent
                  ? context.tr('home.sent_today')
                  : context.tr('home.live_due_by', namedArgs: {'time': due}),
            ),
          if (history.isNotEmpty)
            Row(
              children: [
                for (final entry in history.take(7))
                  if (dashboardDate(entry['date']) case final day?)
                    Expanded(
                      child: Column(
                        spacing: 6,
                        children: [
                          _ReportDay(
                            missed: entry['state'] == 'missed',
                            pending:
                                entry['log'] == null &&
                                entry['state'] != 'missed',
                          ),
                          _HomeCaption(dateFormat.format(day)),
                        ],
                      ),
                    ),
              ],
            ),
          if (canLog)
            _CardButton(
              context.tr('home.log_todays_report'),
              color: context.foreground,
              background: context.raised,
              border: context.outline,
              onPressed: busy
                  ? null
                  : () => _openReportForm(
                      context,
                      actions,
                      routineId,
                      occurrenceDate,
                    ),
            ),
        ],
      ),
    );
  }
}
