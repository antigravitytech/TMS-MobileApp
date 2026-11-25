import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../application/focus_timer.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';

class WorkspaceFocusTimer extends ConsumerStatefulWidget {
  const WorkspaceFocusTimer({super.key, required this.workspace});
  final LocalWorkspace workspace;
  @override
  ConsumerState<WorkspaceFocusTimer> createState() => _TimerState();
}

class _TimerState extends ConsumerState<WorkspaceFocusTimer>
    with SingleTickerProviderStateMixin {
  Timer? ticker;
  late final pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  @override
  void dispose() {
    ticker?.cancel();
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(focusTimerProvider(widget.workspace.id));
    if (timer.running) {
      ticker ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
      if (!pulse.isAnimating && !MediaQuery.disableAnimationsOf(context)) {
        pulse.repeat();
      }
    } else {
      ticker?.cancel();
      ticker = null;
      pulse.stop();
    }
    final clients = widget.workspace
        .items(WorkspaceSection.clients)
        .map((r) => r.title)
        .toSet();
    final elapsed = timer.elapsed,
        number = NumberFormat('00', context.locale.toString());
    final clock = [
      elapsed.inHours,
      elapsed.inMinutes % 60,
      elapsed.inSeconds % 60,
    ].map(number.format).join(':');
    final admin = context.tr('studio.admin');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff262a60), Color(0xff1b1e45), Color(0xff353b80)],
        ),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final client in <String?>[...clients, null])
                InkWell(
                  onTap: timer.running || timer.saving
                      ? null
                      : () => timer.choose(client),
                  child: AnimatedContainer(
                    duration: DesignMotion.duration(context, DesignMotion.fast),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: timer.client == client
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      client ?? admin,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: timer.client == client
                            ? DesignColor.ink
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              clock,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              timer.running ? 'studio.tracking' : 'studio.start_hint',
              namedArgs: {'client': timer.client ?? admin},
            ),
            style: const TextStyle(color: Color(0xffc9cbe0), fontSize: 12),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: pulse,
            builder: (_, child) {
              final t = (pulse.value / .7).clamp(0.0, 1.0);
              return DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (timer.running)
                      BoxShadow(
                        color: DesignColor.rose.withValues(alpha: .5 * (1 - t)),
                        spreadRadius: 18 * t,
                      ),
                  ],
                ),
                child: child,
              );
            },
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: timer.running
                    ? DesignColor.rose
                    : DesignColor.teal,
                foregroundColor: DesignColor.ink,
                minimumSize: const Size.square(72),
              ),
              tooltip: context.tr(
                timer.running ? 'studio.stop_timer' : 'studio.start_timer',
              ),
              onPressed: timer.saving
                  ? null
                  : () async {
                      if (!timer.running) {
                        timer.start();
                        return;
                      }
                      final ok = await timer.finish(
                        context.tr('studio.focus_session'),
                        admin,
                      );
                      if (!ok && context.mounted) {
                        designToast(
                          context,
                          context.tr('workspaces.try_again'),
                        );
                      }
                    },
              icon: Icon(
                timer.running ? TmsIcons.pause : TmsIcons.play,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
