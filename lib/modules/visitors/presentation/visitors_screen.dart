import 'package:easy_localization/easy_localization.dart';
import '../../../shared/kit/qr_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';

part 'widgets/visitor_cards.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});
  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  String? reception;
  static const expectedGuests = [('Bayo Ogunleye', 'visitors.bayo_expected')];
  final invites = <(String, String)>[];
  Future<void> invite() async {
    var name = 'Kemi Lawal',
        purpose = 'Vendor demo',
        day = DateFormat(
          'EEE, d MMM',
          context.locale.toString(),
        ).format(DateTime(2026, 11, 25)),
        time = '11:00';
    final result = await designSheet<(String, String, String, String)>(
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
                    value: day,
                    onTap: () async {
                      final now = DateTime.now();
                      final value = await showDatePicker(
                        switchToInputEntryModeIcon: const Icon(
                          TmsIcons.keyboard,
                        ),
                        switchToCalendarEntryModeIcon: const Icon(
                          TmsIcons.calendar,
                        ),
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 2),
                      );
                      if (context.mounted && value != null) {
                        update(
                          () => day = MaterialLocalizations.of(
                            context,
                          ).formatShortDate(value),
                        );
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _VisitorDateField(
                    label: context.tr('visitors.time'),
                    value: time,
                    onTap: () async {
                      final value = await showTimePicker(
                        switchToInputEntryModeIcon: const Icon(
                          TmsIcons.keyboard,
                        ),
                        switchToTimerEntryModeIcon: const Icon(TmsIcons.clock),
                        context: context,
                        initialTime: const TimeOfDay(hour: 10, minute: 30),
                      );
                      if (context.mounted && value != null) {
                        update(() => time = value.format(context));
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
              onPressed: name.trim().isEmpty
                  ? null
                  : () => Navigator.pop(sheet, (
                      name.trim(),
                      day,
                      time,
                      purpose.trim(),
                    )),
            ),
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    final (guest, date, hour, why) = result;
    setState(
      () => invites.insert(0, (
        guest,
        '$date · $hour${why.isNotEmpty ? ' · $why' : ''}',
      )),
    );
    final code = 'K7Q-${41 + invites.length}M';
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
  Widget build(BuildContext context) => DesignPage(
    title: context.tr('common.visitors'),
    subtitleBelow: true,
    subtitle: context.tr('visitors.invite_guests_and_answer_when_they_arrive'),
    footer: DesignButton(
      context.tr('visitors.invite_a_guest'),
      icon: TmsIcons.add,
      onPressed: invite,
    ),
    children: [
      _VisitorHeading(context.tr('visitors.waiting_for_you')),
      AnimatedSwitcher(
        duration: DesignMotion.duration(context, DesignMotion.page),
        child: reception == null
            ? _WaitingVisitor(
                onDecision: (decision) => setState(() => reception = decision),
              )
            : DesignCard(
                key: ValueKey(reception),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: DesignColor.green.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: DesignColor.green.withValues(alpha: .3),
                        ),
                      ),
                      child: const Icon(
                        TmsIcons.check,
                        color: DesignColor.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              reception == 'visitors.wait_10_min'
                                  ? 'visitors.asked_to_wait'
                                  : reception == 'visitors.not_today'
                                  ? 'visitors.told_not_today'
                                  : 'visitors.asked_to_come',
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('visitors.reception_has_been_told'),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      _VisitorHeading(context.tr('visitors.expected')),
      DesignSection(
        children: [
          for (final (guest, detail) in [
            ...invites,
            for (final (name, key) in expectedGuests) (name, context.tr(key)),
          ])
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  DesignAvatar(
                    guest.split(' ').map((v) => v[0]).take(2).join(),
                    color: guest == 'Bayo Ogunleye'
                        ? const Color(0xffbcd995)
                        : const Color(0xffd8b4ec),
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guest,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail,
                          style: TextStyle(fontSize: 12, color: context.muted),
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
                      guest == 'Bayo Ogunleye' ? 'B2X-81P' : 'K7Q-42M',
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
  );
}
