import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../application/focus_timer.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/time_controller.dart';

const _light = Color(0xfff3f5fe);
const _soft = Color(0xffc9cbe0);

/// Short chip label: a client's first word, e.g. "Unique".
String shortClient(String name) => name.split(' ').first;

/// The hero timer: pick a client, start, and stop to log the time.
class TimeTimerCard extends ConsumerStatefulWidget {
  const TimeTimerCard({
    super.key,
    required this.workspaceId,
    required this.clients,
  });
  final String workspaceId;
  final List<String> clients;
  @override
  ConsumerState<TimeTimerCard> createState() => _TimeTimerCardState();
}

class _TimeTimerCardState extends ConsumerState<TimeTimerCard>
    with SingleTickerProviderStateMixin {
  Timer? _tick;
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void dispose() {
    _tick?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _sync(bool running) {
    if (running && _tick == null) {
      _tick = Timer.periodic(
        const Duration(seconds: 1),
        (_) => mounted ? setState(() {}) : null,
      );
      if (!MediaQuery.disableAnimationsOf(context)) _pulse.repeat();
    } else if (!running && _tick != null) {
      _tick?.cancel();
      _tick = null;
      _pulse
        ..stop()
        ..reset();
    }
  }

  Future<void> _toggle(FocusTimer timer) async {
    if (!timer.running) return timer.start();
    final who = timer.client ?? adminClient;
    final minutes =
        ((timer.elapsed.inMilliseconds / 900000).round().clamp(1, 999)) * 15;
    final ok = await timer.finish(
      c.tr('individual.focus_session'),
      adminClient,
    );
    if (!mounted) return;
    designToast(
      context,
      ok
          ? c.tr(
              'individual.logged',
              namedArgs: {'hours': _hours(c, minutes), 'client': who},
            )
          : c.tr('workspaces.try_again'),
    );
  }

  BuildContext get c => context;

  @override
  Widget build(BuildContext c) {
    final timer = ref.watch(focusTimerProvider(widget.workspaceId));
    _sync(timer.running);
    final e = timer.elapsed;
    String two(int n) => n.toString().padLeft(2, '0');
    final clock =
        '${two(e.inHours)}:${two(e.inMinutes % 60)}:${two(e.inSeconds % 60)}';
    if (!timer.chosen && widget.clients.isNotEmpty) {
      timer.client = widget.clients.first;
    }
    final who = timer.client ?? adminClient;
    final line = timer.running
        ? c.tr('individual.tracking', namedArgs: {'client': who})
        : c.tr('individual.tap_play');
    final options = [...widget.clients, adminClient];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
      child: KitHero(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final o in options)
                  _HeroChip(
                    label: shortClient(o),
                    selected: o == who,
                    onTap: () => timer.choose(o == adminClient ? null : o),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              clock,
              style: const TextStyle(
                fontSize: 52,
                height: 1,
                letterSpacing: -2,
                fontWeight: FontWeight.w800,
                color: _light,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            Text(line, style: const TextStyle(fontSize: 12, color: _soft)),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (timer.running)
                      BoxShadow(
                        color: DesignColor.rose.withValues(
                          alpha: .5 * (1 - _pulse.value),
                        ),
                        spreadRadius: 18 * _pulse.value,
                      ),
                  ],
                ),
                child: child,
              ),
              child: Semantics(
                button: true,
                label: c.tr(
                  timer.running ? 'individual.stop' : 'individual.start',
                ),
                child: GestureDetector(
                  onTap: timer.saving ? null : () => _toggle(timer),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: kitSpring,
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: timer.running
                          ? DesignColor.rose
                          : DesignColor.teal,
                    ),
                    child: Icon(
                      timer.running
                          ? TmsIcons.pauseFilled
                          : TmsIcons.playFilled,
                      size: 28,
                      color: DesignColor.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _hours(BuildContext c, int minutes) => c.tr(
  'individual.hours',
  namedArgs: {
    'n': NumberFormat.decimalPattern(
      c.locale.toString(),
    ).format((minutes / 6).round() / 10),
  },
);

/// Hours as the prototype prints them, e.g. "3.5h".
String timeHours(BuildContext c, int minutes) => _hours(c, minutes);

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: DesignMotion.fast,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? _light : Colors.transparent,
        border: Border.all(color: selected ? _light : const Color(0x33ffffff)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: selected ? DesignColor.ink : _light,
        ),
      ),
    ),
  );
}

/// `.cbar`: client name, a teal bar and the hours.
class TimeClientBar extends StatelessWidget {
  const TimeClientBar({
    super.key,
    required this.name,
    required this.minutes,
    required this.max,
  });
  final String name;
  final int minutes, max;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      spacing: 10,
      children: [
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          width: 120,
          child: KitBar(
            value: max == 0 ? 0 : minutes / max,
            color: const Color(0xff2bb3a3),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            timeHours(c, minutes),
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
