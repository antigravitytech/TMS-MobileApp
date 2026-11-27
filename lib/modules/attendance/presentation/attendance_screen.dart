import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../../shared/kit/kit.dart';
import '../../tasks/presentation/tasks_screen.dart' show taskErrorMessage;
import '../../workspace/application/workspace_preview.dart';
import '../application/attendance_controller.dart';
import '../domain/attendance.dart';

part 'widgets/attendance_widgets.dart';
part 'widgets/attendance_lists.dart';
part 'widgets/attendance_clock.dart';

/// A failed attendance request in words; refusals use the server's sentence.
String _attendanceError(BuildContext context, Object? error) =>
    error is AttendanceRefused
    ? error.detail
    : taskErrorMessage(context, error);

/// The status label and colour, as on the design.
(String, Color) _statusLook(BuildContext context, DayStatus status) =>
    switch (status) {
      DayStatus.early => (context.tr('attendance.early'), DesignColor.teal),
      DayStatus.onTime => (context.tr('common.on_time'), DesignColor.green),
      DayStatus.late => (context.tr('attendance.late'), DesignColor.amber),
      DayStatus.absent => (context.tr('attendance.absent'), DesignColor.red),
      _ => (context.tr('attendance.statuses.${status.code}'), context.muted),
    };

/// Local `HH:mm` from a time.
String _hm(BuildContext context, DateTime at) =>
    DateFormat.Hm(context.locale.toString()).format(at);

/// "109h 19m".
String _duration(BuildContext context, int minutes) => context.tr(
  'attendance.hours_minutes',
  namedArgs: {'h': '${minutes ~/ 60}', 'm': '${minutes % 60}'},
);

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  int tab = 0;

  Widget _states<T>(
    AsyncValue<T> value,
    ProviderOrFamily retry,
    Widget Function(T) data,
  ) => switch (value) {
    AsyncValue(value: final v?) => data(v),
    AsyncValue(:final error?) => Column(
      spacing: 12,
      children: [
        DesignLabel(_attendanceError(context, error)),
        DesignButton(
          context.tr('workspaces.try_again'),
          secondary: true,
          onPressed: () => ref.invalidate(retry),
        ),
      ],
    ),
    _ => const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: CircularProgressIndicator()),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return DesignPage(
      title: context.tr('common.attendance'),
      leading: const SizedBox.shrink(),
      actions: [
        DesignIcon(
          icon: TmsIcons.close,
          label: context.tr('common.back'),
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
      children: [
        _AttendanceTabs(tab, (i) => setState(() => tab = i)),
        if (tab == 0) ...[
          _states(
            ref.watch(attendanceTodayProvider),
            attendanceTodayProvider,
            (today) => _ClockCard(today: today),
          ),
          DesignTitle(
            context.tr('attendance.your_month'),
            action: DateFormat.MMMM(
              context.locale.toString(),
            ).format(DateTime.now()),
          ),
          _states(
            ref.watch(attendanceMonthProvider),
            attendanceMonthProvider,
            (stats) => Column(
              spacing: 12,
              children: [_AttendanceMonth(stats), _AttendanceMetrics(stats)],
            ),
          ),
        ],
        if (tab == 1)
          _states(
            ref.watch(attendanceHistoryProvider),
            attendanceHistoryProvider,
            (records) => _AttendanceHistory(
              records: records,
              absent: [
                for (final (day, status)
                    in ref.watch(attendanceMonthProvider).value?.days ??
                        const <(DateTime, DayStatus)>[])
                  if (status == DayStatus.absent) day,
              ],
            ),
          ),
        if (tab == 2)
          _states(
            ref.watch(attendanceBoardProvider),
            attendanceBoardProvider,
            (board) => _AttendanceTeam(board),
          ),
      ],
    );
  }
}
