import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

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
    final (icon, color, heading, body) = checking
        ? (
            TmsIcons.locate,
            DesignColor.purple,
            context.tr('attendance.checking_location'),
            context.tr('attendance.head_office_geofence'),
          )
        : state.clockedOut
        ? (
            TmsIcons.checkCircle,
            DesignColor.green,
            context.tr('attendance.nice_work_today'),
            context.tr('attendance.logged_today_8_52_17_25'),
          )
        : state.clockedIn
        ? (
            TmsIcons.check,
            DesignColor.green,
            context.tr('attendance.youre_in_have_a_good_one'),
            context.tr('attendance.in_8_52_8_min_early'),
          )
        : (
            TmsIcons.clock,
            DesignColor.purple,
            context.tr(
              'attendance.good_morning_name',
              namedArgs: {'name': state.firstName},
            ),
            context.tr('attendance.arrive_9_00_9_30_leave_from'),
          );
    return DesignPage(
      title: context.tr('common.attendance'),
      children: [
        DesignChoices(
          items: [
            context.tr('common.today'),
            context.tr('attendance.history'),
            context.tr('common.team'),
          ],
          selected: tab,
          onChanged: (i) => setState(() => tab = i),
        ),
        if (tab == 0) ...[
          Row(
            children: [
              Expanded(
                child: DesignLabel(context.tr('common.monday_23_november')),
              ),
              DesignPill(context.tr('attendance.29_partly_cloudy')),
            ],
          ),
          DesignCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                spacing: 14,
                children: [
                  DesignPill(
                    context.tr('attendance.head_office'),
                    icon: TmsIcons.location,
                  ),
                  AnimatedSwitcher(
                    duration: DesignMotion.duration(
                      context,
                      DesignMotion.object,
                    ),
                    transitionBuilder: (child, motion) => ScaleTransition(
                      scale: motion,
                      child: FadeTransition(opacity: motion, child: child),
                    ),
                    child: Container(
                      key: ValueKey(icon),
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: .12),
                        border: Border.all(
                          color: color.withValues(alpha: .45),
                          width: 2,
                        ),
                      ),
                      child: checking
                          ? Padding(
                              padding: const EdgeInsets.all(42),
                              child: CircularProgressIndicator(
                                color: color,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(icon, color: color, size: 56),
                    ),
                  ),
                  Text(
                    heading,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                  DesignLabel(body),
                  if (state.clockedIn)
                    const Text(
                      '8:52 AM',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (state.clockedOut)
                    Text(
                      context.tr('attendance.8h_33m'),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (!state.clockedOut)
                    DesignButton(
                      state.clockedIn
                          ? context.tr('attendance.clock_out')
                          : context.tr('common.clock_in'),
                      icon: state.clockedIn ? TmsIcons.logout : TmsIcons.login,
                      onPressed: checking
                          ? null
                          : state.clockedIn
                          ? () => state.setAttendance(inOffice: false)
                          : clockIn,
                    ),
                ],
              ),
            ),
          ),
        ],
        if (tab != 2) ...[
          DesignTitle(context.tr('attendance.your_month')),
          DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                DesignTitle(context.tr('attendance.november')),
                Text(
                  context.tr('attendance.80_on_time'),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                _AttendanceCalendar(),
                Wrap(
                  spacing: 7,
                  runSpacing: 8,
                  children: [
                    DesignPill(
                      context.tr('attendance.2_early'),
                      color: DesignColor.teal,
                    ),
                    DesignPill(
                      context.tr('attendance.10_on_time'),
                      color: DesignColor.green,
                    ),
                    DesignPill(
                      context.tr('attendance.1_late'),
                      color: DesignColor.amber,
                    ),
                    DesignPill(
                      context.tr('attendance.2_absent'),
                      color: DesignColor.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (tab == 1)
            DesignSection(
              children: [
                DesignTile(
                  title: context.tr('attendance.usual_arrival'),
                  subtitle: '9:01',
                  icon: TmsIcons.login,
                ),
                DesignTile(
                  title: context.tr('attendance.usual_leaving'),
                  subtitle: '17:25',
                  icon: TmsIcons.logout,
                ),
                DesignTile(
                  title: context.tr('attendance.time_logged'),
                  subtitle: context.tr('attendance.109h_19m'),
                  icon: TmsIcons.clock,
                ),
              ],
            ),
        ] else
          DesignSection(
            children: [
              DesignTile(
                title: 'Amaka Eze',
                subtitle: context.tr('attendance.in_8_44'),
                leading: DesignAvatar('AE', color: DesignColor.rose),
              ),
              DesignTile(
                title: 'Tunde Bakare',
                subtitle: context.tr('attendance.in_8_59'),
                leading: DesignAvatar('TB', color: DesignColor.teal),
              ),
              DesignTile(
                title: 'Sarah Johnson',
                subtitle: context.tr('attendance.not_in'),
                leading: DesignAvatar('SJ'),
              ),
            ],
          ),
      ],
    );
  }
}

class _AttendanceCalendar extends StatelessWidget {
  const _AttendanceCalendar();
  @override
  Widget build(BuildContext context) => Column(
    spacing: 7,
    children: [
      Row(
        children: [
          for (final name in [
            context.tr('attendance.m'),
            context.tr('attendance.t'),
            context.tr('attendance.w'),
            context.tr('attendance.t'),
            context.tr('attendance.f'),
            context.tr('attendance.s'),
            context.tr('attendance.s'),
          ])
            Expanded(child: Center(child: DesignLabel(name))),
        ],
      ),
      for (var week = 0; week < 5; week++)
        Row(
          children: [
            for (var day = 0; day < 7; day++)
              Expanded(child: Center(child: _day(context, week * 7 + day - 5))),
          ],
        ),
    ],
  );
  Widget _day(BuildContext context, int day) {
    if (day < 1 || day > 30) return const SizedBox(height: 28);
    final color = day == 23
        ? DesignColor.purple
        : [7, 8, 14, 15, 21, 22, 28, 29].contains(day) || day > 23
        ? context.raised
        : [11, 19].contains(day)
        ? DesignColor.red
        : day == 12
        ? DesignColor.amber
        : day % 6 == 0
        ? DesignColor.teal
        : DesignColor.green;
    return CircleAvatar(
      radius: 14,
      backgroundColor: color,
      foregroundColor: color == context.raised
          ? context.foreground
          : DesignColor.ink,
      child: Text(
        '$day',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
