import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';
import '../../workspace/application/workspace_preview.dart';
import '../domain/report.dart';

part 'live_reports_repository.dart';
part 'mock_reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) {
    return MockReportsRepository(ref.read(workspacePreviewProvider));
  }
  return LiveReportsRepository(
    ref.watch(networkCallsRepositoryProvider),
    workspace: ref.watch(activeLiveWorkspaceProvider),
  );
});

abstract class ReportsRepository {
  /// Today's report routine with its fields, or null when none is due.
  Future<DailyReport?> dailyReport();

  /// Sends today's report; [answers] are by field id.
  Future<void> send(DailyReport report, Map<String, Object> answers);

  /// Who reported today among the people I manage.
  Future<TeamReports?> team();

  Future<Performance> performance({
    required bool team,
    required ReportPeriod period,
  });
}
