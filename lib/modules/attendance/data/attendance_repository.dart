import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../../core/services/location_service.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';
import '../../workspace/application/workspace_preview.dart';
import '../domain/attendance.dart';

part 'live_attendance_repository.dart';
part 'mock_attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) {
    return MockAttendanceRepository(ref.read(workspacePreviewProvider));
  }
  return LiveAttendanceRepository(
    ref.watch(networkCallsRepositoryProvider),
    ref.watch(locationServiceProvider),
    workspace: ref.watch(activeLiveWorkspaceProvider),
  );
});

abstract class AttendanceRepository {
  Future<AttendanceToday> today();
  Future<AttendanceStats> month();
  Future<List<AttendanceRecord>> history();
  Future<List<BoardEntry>> board();

  /// The weather at [today]'s workplace, or null when unavailable.
  Future<Weather?> weather(AttendanceToday today);

  /// Clocks in or out, checking the device's location first. Throws
  /// [AttendanceRefused] with the server's reason when refused.
  Future<AttendanceToday> clockIn();
  Future<AttendanceToday> clockOut();
}
