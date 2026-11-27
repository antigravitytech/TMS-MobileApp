import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

part 'widgets/attendance_widgets.dart';
part 'widgets/attendance_lists.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  int tab = 0;
  bool checking = false;
  Future<void> clockIn() async {
    if (checking) return;
    setState(() => checking = true);
    await Future<void>.delayed(
      DesignMotion.duration(context, const Duration(milliseconds: 1050)),
    );
    if (!mounted) return;
    ref.read(workspacePreviewProvider).setAttendance(inOffice: true);
    setState(() => checking = false);
    designToast(context, context.tr('attendance.clocked_in_head_office'));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspacePreviewProvider);
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Color(0xff203750),
                  Color(0xff242445),
                  Color(0xff44478d),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('common.monday_23_november'),
                  style: TextStyle(color: context.lavender, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'attendance.good_morning_name',
                    namedArgs: {'name': state.firstName},
                  ),
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  spacing: 8,
                  children: [
                    _AttendanceTag(
                      context.tr('attendance.29_partly_cloudy'),
                      context.lavender,
                    ),
                    _AttendanceTag(
                      context.tr('attendance.head_office'),
                      context.lavender,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    width: 226,
                    height: 226,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DesignColor.purple.withValues(alpha: .4),
                        width: 2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: checking || state.clockedOut
                            ? null
                            : state.clockedIn
                            ? () => state.setAttendance(inOffice: false)
                            : clockIn,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xffb2a5ef), Color(0xff8274cc)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x559184d9),
                                blurRadius: 30,
                                offset: Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (checking)
                                const CircularProgressIndicator(
                                  color: DesignColor.ink,
                                )
                              else
                                Icon(
                                  state.clockedOut
                                      ? TmsIcons.check
                                      : state.clockedIn
                                      ? TmsIcons.logout
                                      : TmsIcons.login,
                                  size: 30,
                                  color: DesignColor.ink,
                                ),
                              const SizedBox(height: 10),
                              Text(
                                context.tr(
                                  checking
                                      ? 'attendance.checking_location'
                                      : state.clockedOut
                                      ? 'attendance.nice_work_today'
                                      : state.clockedIn
                                      ? 'attendance.clock_out'
                                      : 'common.clock_in',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: DesignColor.ink,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                DateFormat.jm(
                                  context.locale.toString(),
                                ).format(DateTime(2026, 11, 23, 8, 52)),
                                style: const TextStyle(
                                  color: Color(0xff4f496f),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    context.tr('attendance.arrive_9_00_9_30_leave_from'),
                    style: TextStyle(color: context.lavender, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          DesignTitle(
            context.tr('attendance.your_month'),
            action: context.tr('attendance.november'),
          ),
          const _AttendanceMonth(),
          const _AttendanceMetrics(),
        ],
        if (tab == 1) const _AttendanceHistory(),
        if (tab == 2) const _AttendanceTeam(),
      ],
    );
  }
}
