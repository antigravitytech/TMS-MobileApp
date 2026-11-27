import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance.dart';

/// Today. Clocking in or out replaces it with the server's copy, and the
/// month and history are refreshed in the background.
final attendanceTodayProvider =
    AsyncNotifierProvider.autoDispose<
      AttendanceTodayController,
      AttendanceToday
    >(AttendanceTodayController.new, retry: (_, _) => null);

class AttendanceTodayController extends AsyncNotifier<AttendanceToday> {
  AttendanceRepository get _repository =>
      ref.read(attendanceRepositoryProvider);

  @override
  Future<AttendanceToday> build() =>
      guardSession(ref, () => ref.watch(attendanceRepositoryProvider).today());

  Future<void> clockIn() => _clock(_repository.clockIn);
  Future<void> clockOut() => _clock(_repository.clockOut);

  Future<void> _clock(Future<AttendanceToday> Function() action) async {
    final today = await guardSession(ref, action);
    if (!ref.mounted) return;
    state = AsyncData(today);
    ref
      ..invalidate(attendanceMonthProvider)
      ..invalidate(attendanceHistoryProvider)
      ..invalidate(attendanceBoardProvider);
  }
}

/// The month's punctuality and calendar, shown under the clock.
final attendanceMonthProvider = FutureProvider.autoDispose<AttendanceStats>(
  (ref) =>
      guardSession(ref, () => ref.watch(attendanceRepositoryProvider).month()),
  retry: (_, _) => null,
);

/// The History and Team tabs, loaded when each is first opened.
final attendanceHistoryProvider =
    FutureProvider.autoDispose<List<AttendanceRecord>>(
      (ref) => guardSession(
        ref,
        () => ref.watch(attendanceRepositoryProvider).history(),
      ),
      retry: (_, _) => null,
    );

final attendanceBoardProvider = FutureProvider.autoDispose<List<BoardEntry>>(
  (ref) =>
      guardSession(ref, () => ref.watch(attendanceRepositoryProvider).board()),
  retry: (_, _) => null,
);

/// The weather at the workplace; null hides the tag.
final attendanceWeatherProvider = FutureProvider.autoDispose
    .family<Weather?, AttendanceToday>(
      (ref, today) => ref
          .read(attendanceRepositoryProvider)
          .weather(today)
          .then<Weather?>((w) => w, onError: (Object _) => null),
      retry: (_, _) => null,
    );
