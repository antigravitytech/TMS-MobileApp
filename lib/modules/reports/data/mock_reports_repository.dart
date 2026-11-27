part of 'reports_repository.dart';

/// The prototype's reports and performance figures. Sending is kept in the
/// shared preview state so Home sees it.
class MockReportsRepository implements ReportsRepository {
  const MockReportsRepository(this._preview);
  final WorkspacePreview _preview;

  static String _short(DateTime d) =>
      '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]}';

  static const _fields = [
    ReportField(
      id: 'done',
      label: 'What did you get done today?',
      type: 'long',
      required: true,
    ),
    ReportField(id: 'next', label: "What's next?", type: 'long'),
    ReportField(id: 'block', label: 'What is blocking you?', type: 'long'),
  ];

  @override
  Future<DailyReport?> dailyReport() async {
    final report = DailyReport(
      routineId: 'mock-daily',
      title: 'Daily status update',
      date: DateTime.now().toIso8601String().substring(0, 10),
      fields: _fields,
      dueTime: '17:00',
      reviewer: 'Ibrahim Musa',
      draft: const {
        'done':
            'Shortlisted 6 backend candidates. Drafted the Q4 hiring budget.',
      },
      projects: const ['Customer Portal Revamp', 'Mobile App Launch'],
      points: 10,
    );
    return _preview.reportSent ? report.asSent() : report;
  }

  @override
  Future<void> send(DailyReport report, Map<String, Object> answers) async =>
      _preview.sendReport();

  @override
  Future<TeamReports?> team() async => const TeamReports(
    title: 'Tech Team',
    canNudge: true,
    people: [
      TeamReport(
        name: 'Tunde',
        sent: true,
        done: 'Wrote tests for the payment flow',
        blockers: 'Blocked on sandbox keys again',
        detail: '100% this month · 10-day streak',
      ),
      TeamReport(
        name: 'David',
        sent: true,
        late: true,
        done: 'Fixed the login redirect bug; reviewed 2 pull requests',
        detail: '90% this month · 7-day streak',
      ),
      TeamReport(name: 'Amaka', sent: false),
      TeamReport(name: 'Sarah', sent: false),
    ],
  );

  @override
  Future<Performance> performance({
    required bool team,
    required ReportPeriod period,
  }) async {
    final now = DateTime.now();
    final (from, to) = switch (period) {
      ReportPeriod.thisWeek => (
        now.subtract(Duration(days: now.weekday - 1)),
        now,
      ),
      ReportPeriod.thisMonth => (DateTime(now.year, now.month), now),
      ReportPeriod.lastMonth => (
        DateTime(now.year, now.month - 1),
        DateTime(now.year, now.month, 0),
      ),
      ReportPeriod.thisQuarter => (
        DateTime(now.year, (now.month - 1) ~/ 3 * 3 + 1),
        DateTime(now.year, (now.month - 1) ~/ 3 * 3 + 4, 0),
      ),
    };
    return Performance(
      from: from,
      to: to,
      metrics: team
          ? const [
              PerfMetric('completed', 4, 3),
              PerfMetric('on_time_rate', 50, 50, unit: '%'),
              PerfMetric('first_time_right_rate', 50, 50, unit: '%'),
              PerfMetric('average_rounds', 1.8, 0.8),
              PerfMetric('saved_days', 2.2, 0),
            ]
          : const [
              PerfMetric('completed', 0, 0),
              PerfMetric(
                'on_time_streak',
                4,
                0,
                unit: 'days',
                note: 'Best: 11 days',
              ),
              PerfMetric(
                'recurring_compliance',
                80,
                0,
                unit: '%',
                note: '13 of 16 days',
              ),
              PerfMetric(
                'punctuality',
                80,
                0,
                unit: '%',
                note: '1 of 5 lates used',
              ),
            ],
      weekly: [
        for (var i = 0; i < 8; i++)
          (
            _short(to.subtract(Duration(days: (7 - i) * 7))),
            (36 + (i * 13 + period.index * 7 + (team ? 9 : 0)) % 79) ~/ 10,
            (12 + i * 8 % 32) ~/ 10,
          ),
      ],
      level: team ? null : (level: 2, points: 640, toNext: 360, progress: .64),
      attention: const [
        ('Regression test plan for portal', '2 days late · David'),
        ('Refactor auth middleware', '1 day late · Tunde'),
      ],
    );
  }
}
