part of '../attendance_screen.dart';

/// WMO weather code → copy key.
String _weatherKey(int code) => switch (code) {
  0 => 'clear',
  1 || 2 => 'partly_cloudy',
  3 => 'cloudy',
  45 || 48 => 'fog',
  >= 51 && <= 57 => 'drizzle',
  >= 61 && <= 67 || >= 80 && <= 82 => 'rain',
  >= 71 && <= 77 || 85 || 86 => 'snow',
  >= 95 => 'storm',
  _ => 'cloudy',
};

/// The Today card: date, greeting, weather and place, and the clock button.
class _ClockCard extends ConsumerStatefulWidget {
  const _ClockCard({required this.today});
  final AttendanceToday today;
  @override
  ConsumerState<_ClockCard> createState() => _ClockCardState();
}

class _ClockCardState extends ConsumerState<_ClockCard> {
  bool checking = false;

  Future<void> _clock() async {
    final today = widget.today;
    if (checking || today.clockedOut) return;
    setState(() => checking = true);
    final controller = ref.read(attendanceTodayProvider.notifier);
    final place = today.place;
    try {
      if (today.clockedIn) {
        await controller.clockOut();
      } else {
        await controller.clockIn();
        if (mounted) {
          designToast(
            context,
            place.isEmpty
                ? context.tr('attendance.clocked_in')
                : context.tr(
                    'attendance.clocked_in_at',
                    namedArgs: {'place': place},
                  ),
          );
        }
      }
    } catch (error) {
      if (mounted) designToast(context, _attendanceError(context, error));
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = widget.today;
    final weather = ref.watch(attendanceWeatherProvider(today)).value;
    final name = ref.watch(workspacePreviewProvider.select((p) => p.firstName));
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'attendance.good_morning_name'
        : hour < 17
        ? 'attendance.good_afternoon_name'
        : 'attendance.good_evening_name';
    final window = today.window;
    final shownAt =
        today.record?.clockOut ?? today.record?.clockIn ?? DateTime.now();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xff203750), Color(0xff242445), Color(0xff44478d)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.MMMMEEEEd(context.locale.toString()).format(today.date),
            style: TextStyle(color: context.lavender, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(greeting, namedArgs: {'name': name}),
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          if (!today.enabled) ...[
            const SizedBox(height: 18),
            DesignLabel(context.tr('attendance.switched_off')),
          ] else ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (weather != null)
                  _AttendanceTag(
                    context.tr(
                      'attendance.weather',
                      namedArgs: {
                        'temp': '${weather.celsius}',
                        'sky': context.tr(
                          'attendance.sky.${_weatherKey(weather.code)}',
                        ),
                      },
                    ),
                    context.lavender,
                  ),
                if (today.place.isNotEmpty)
                  _AttendanceTag(today.place, context.lavender),
                if (today.holiday case final holiday?)
                  _AttendanceTag(holiday, DesignColor.amber),
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
                    onTap: checking || today.clockedOut ? null : _clock,
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
                              today.clockedOut
                                  ? TmsIcons.check
                                  : today.clockedIn
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
                                  : today.clockedOut
                                  ? 'attendance.nice_work_today'
                                  : today.clockedIn
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
                            ).format(shownAt),
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
                window.start == window.until
                    ? context.tr(
                        'attendance.arrive_by',
                        namedArgs: {'start': window.start, 'end': window.end},
                      )
                    : context.tr(
                        'attendance.arrive_between',
                        namedArgs: {
                          'start': window.start,
                          'until': window.until,
                          'end': window.end,
                        },
                      ),
                style: TextStyle(color: context.lavender, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
