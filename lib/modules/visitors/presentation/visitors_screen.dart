import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../../shared/kit/kit.dart';
import '../../../shared/kit/qr_painter.dart';
import '../../tasks/presentation/tasks_screen.dart' show taskErrorMessage;
import '../application/visitors_controller.dart';
import '../domain/visit_pass.dart';

part 'widgets/visitor_cards.dart';

/// A failed request in words; refusals use the server's sentence.
String _visitorError(BuildContext context, Object? error) =>
    error is VisitorRefused ? error.detail : taskErrorMessage(context, error);

class VisitorsScreen extends ConsumerStatefulWidget {
  const VisitorsScreen({super.key});
  @override
  ConsumerState<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends ConsumerState<VisitorsScreen> {
  /// Guests I answered on this visit, shown as a confirmation.
  final answered = <String, GuestAnswer>{};

  Future<void> answer(VisitPass pass, GuestAnswer decision) async {
    try {
      await ref.read(visitorsProvider.notifier).answer(pass, decision);
      if (mounted) setState(() => answered[pass.id] = decision);
    } catch (error) {
      if (mounted) designToast(context, _visitorError(context, error));
    }
  }

  Future<void> invite() async {
    var name = '', purpose = '';
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    var time = const TimeOfDay(hour: 10, minute: 30);
    final result = await designSheet<GuestInvite>(
      context,
      title: context.tr('visitors.invite_a_guest'),
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            _VisitorInput(
              label: context.tr('visitors.guests_name'),
              initialValue: name,
              onChanged: (value) => update(() => name = value),
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  flex: 2,
                  child: _VisitorDateField(
                    label: context.tr('visitors.day'),
                    value: DateFormat(
                      'EEE, d MMM',
                      context.locale.toString(),
                    ).format(day),
                    onTap: () async {
                      final value = await showDatePicker(
                        switchToInputEntryModeIcon: const Icon(
                          TmsIcons.keyboard,
                        ),
                        switchToCalendarEntryModeIcon: const Icon(
                          TmsIcons.calendar,
                        ),
                        context: context,
                        initialDate: day,
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: DateTime(now.year + 2),
                      );
                      if (context.mounted && value != null) {
                        update(() => day = value);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _VisitorDateField(
                    label: context.tr('visitors.time'),
                    value: time.format(context),
                    onTap: () async {
                      final value = await showTimePicker(
                        switchToInputEntryModeIcon: const Icon(
                          TmsIcons.keyboard,
                        ),
                        switchToTimerEntryModeIcon: const Icon(TmsIcons.clock),
                        context: context,
                        initialTime: time,
                      );
                      if (context.mounted && value != null) {
                        update(() => time = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            _VisitorInput(
              label: context.tr('visitors.purpose'),
              initialValue: purpose,
              onChanged: (value) => purpose = value,
            ),
            DesignButton(
              context.tr('visitors.create_invite'),
              onPressed: name.trim().length < 2
                  ? null
                  : () => Navigator.pop<GuestInvite>(sheet, (
                      name: name.trim(),
                      day: day,
                      // Passes carry a date only, so the time leads the
                      // purpose that the desk sees.
                      purpose: [
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        if (purpose.trim().isNotEmpty) purpose.trim(),
                      ].join(' · '),
                    )),
            ),
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    final VisitPass pass;
    try {
      pass = await ref.read(visitorsProvider.notifier).invite(result);
    } catch (error) {
      if (mounted) designToast(context, _visitorError(context, error));
      return;
    }
    if (!mounted) return;
    final guest = pass.guest;
    final code = pass.code;
    await designSheet<void>(
      context,
      title: context.tr(
        'visitors.invite_ready',
        namedArgs: {'name': guest.split(' ').first},
      ),
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          DesignLabel(context.tr('visitors.they_scan_or_show_it_at_reception')),
          Center(
            child: Container(
              width: 150,
              height: 150,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(painter: QrPainter(code)),
            ),
          ),
          Center(
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: DesignButton(
                  context.tr('common.done'),
                  secondary: true,
                  onPressed: () => Navigator.pop(sheet),
                ),
              ),
              Expanded(
                child: DesignButton(
                  context.tr('visitors.copy_code'),
                  icon: TmsIcons.copy,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (sheet.mounted) {
                      Navigator.pop(sheet);
                      if (mounted) {
                        designToast(
                          context,
                          context.tr('visitors.invite_code_copied'),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(visitorsProvider);
    final passes = async.value;
    final waiting = [
      for (final p in passes ?? const <VisitPass>[])
        if (p.needsAnswer || answered.containsKey(p.id)) p,
    ];
    final expected = [
      for (final p in passes ?? const <VisitPass>[])
        if (p.status == 'expected') p,
    ]..sort((a, b) => a.validOn.compareTo(b.validOn));
    return DesignPage(
      title: context.tr('common.visitors'),
      subtitleBelow: true,
      subtitle: context.tr(
        'visitors.invite_guests_and_answer_when_they_arrive',
      ),
      footer: DesignButton(
        context.tr('visitors.invite_a_guest'),
        icon: TmsIcons.add,
        onPressed: passes == null ? null : invite,
      ),
      children: [
        if (passes == null && !async.hasError)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (passes == null) ...[
          DesignLabel(_visitorError(context, async.error)),
          DesignButton(
            context.tr('workspaces.try_again'),
            secondary: true,
            onPressed: () => ref.invalidate(visitorsProvider),
          ),
        ] else ...[
          _VisitorHeading(context.tr('visitors.waiting_for_you')),
          if (waiting.isEmpty)
            DesignLabel(context.tr('visitors.nobody_waiting')),
          for (final pass in waiting)
            AnimatedSwitcher(
              key: ValueKey(pass.id),
              duration: DesignMotion.duration(context, DesignMotion.page),
              child: switch (answered[pass.id]) {
                null => _WaitingVisitor(
                  pass: pass,
                  onDecision: (decision) => answer(pass, decision),
                ),
                final decision => _AnsweredVisitor(
                  key: ValueKey(decision),
                  name: pass.guest.split(' ').first,
                  decision: decision,
                ),
              },
            ),
          _VisitorHeading(context.tr('visitors.expected')),
          if (expected.isEmpty)
            DesignLabel(context.tr('visitors.nobody_expected'))
          else
            DesignSection(
              children: [
                for (final pass in expected)
                  Padding(
                    key: ValueKey(pass.id),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        DesignAvatar(
                          kitPerson(pass.guest).$1,
                          color: kitPerson(pass.guest).$2,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pass.guest,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  _visitDay(context, pass.validOn),
                                  if (pass.purpose.isNotEmpty) pass.purpose,
                                ].join(' · '),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: context.raised,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            pass.code,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.muted,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}
