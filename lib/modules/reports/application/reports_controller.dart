import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../data/reports_repository.dart';
import '../domain/report.dart';

/// Today's report. Sending marks it sent here without reloading it.
final dailyReportProvider =
    AsyncNotifierProvider.autoDispose<DailyReportController, DailyReport?>(
      DailyReportController.new,
      retry: (_, _) => null,
    );

class DailyReportController extends AsyncNotifier<DailyReport?> {
  @override
  Future<DailyReport?> build() => guardSession(
    ref,
    () => ref.watch(reportsRepositoryProvider).dailyReport(),
  );

  Future<void> send(Map<String, Object> answers) async {
    final report = state.value;
    if (report == null) return;
    await guardSession(
      ref,
      () => ref.read(reportsRepositoryProvider).send(report, answers),
    );
    if (ref.mounted) state = AsyncData(report.asSent());
  }
}

/// The Team tab, loaded when it is first opened.
final teamReportsProvider = FutureProvider.autoDispose<TeamReports?>(
  (ref) => guardSession(ref, () => ref.watch(reportsRepositoryProvider).team()),
  retry: (_, _) => null,
);

/// Performance for me or my team over a period.
final performanceProvider = FutureProvider.autoDispose
    .family<Performance, (bool, ReportPeriod)>(
      (ref, args) => guardSession(
        ref,
        () => ref
            .watch(reportsRepositoryProvider)
            .performance(team: args.$1, period: args.$2),
      ),
      retry: (_, _) => null,
    );
