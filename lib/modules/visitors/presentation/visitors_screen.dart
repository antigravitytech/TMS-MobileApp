import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});
  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  String? reception;
  static const expectedGuests = [
    ('Kemi Afolabi', 'visitors.tomorrow_10_30_vendor_meeting'),
    ('Leo Martins', 'visitors.wednesday_2_00_integration_demo'),
  ];
  final invites = <(String, String)>[];
  Future<void> invite() async {
    var name = '',
        purpose = '',
        day = context.tr('common.tomorrow'),
        time = '10:30 AM';
    final result = await designSheet<(String, String, String, String)>(
      context,
      title: context.tr('visitors.invite_a_guest'),
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            DesignField(
              label: context.tr('visitors.guests_name'),
              onChanged: (value) => update(() => name = value),
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: DesignButton(
                    day,
                    secondary: true,
                    icon: TmsIcons.calendar,
                    onPressed: () async {
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
                  child: DesignButton(
                    time,
                    secondary: true,
                    icon: TmsIcons.clock,
                    onPressed: () async {
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
            DesignField(
              label: context.tr('visitors.purpose'),
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
    final code = 'K7Q-${40 + expectedGuests.length + invites.length}M';
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
          const Center(
            child: Icon(TmsIcons.qrCode, size: 106, color: DesignColor.purple),
          ),
          Center(child: DesignPill(code)),
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
    subtitle: context.tr('visitors.invite_guests_and_answer_when_they_arrive'),
    children: [
      DesignTitle(context.tr('visitors.waiting_for_you')),
      AnimatedSwitcher(
        duration: DesignMotion.duration(context, DesignMotion.page),
        child: reception == null
            ? DesignCard(
                key: const ValueKey('request'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    DesignTile(
                      title: 'Folake Adebayo',
                      subtitle: context.tr(
                        'visitors.at_reception_arrived_2_min_ago',
                      ),
                      leading: DesignAvatar('FA', color: DesignColor.rose),
                    ),
                    DesignLabel(
                      context.tr('visitors.interview_backend_engineer_role'),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final decision in [
                          'visitors.come_in',
                          'visitors.wait_10_min',
                          'visitors.not_today',
                        ])
                          DesignButton(
                            context.tr(decision),
                            secondary: decision != 'visitors.come_in',
                            color: decision == 'visitors.come_in'
                                ? DesignColor.green
                                : null,
                            onPressed: () =>
                                setState(() => reception = decision),
                          ),
                      ],
                    ),
                  ],
                ),
              )
            : DesignCard(
                key: ValueKey(reception),
                child: DesignTile(
                  title: context.tr('visitors.reception_has_been_told'),
                  subtitle: context.tr(reception!),
                  icon: TmsIcons.checkCircle,
                  color: DesignColor.green,
                ),
              ),
      ),
      DesignTitle(context.tr('visitors.expected')),
      DesignSection(
        children: [
          for (final (guest, detail) in [
            ...invites,
            for (final (name, key) in expectedGuests) (name, context.tr(key)),
          ])
            DesignTile(title: guest, subtitle: detail, icon: TmsIcons.person),
        ],
      ),
      DesignButton(
        context.tr('visitors.invite_a_guest'),
        icon: TmsIcons.addPerson,
        onPressed: invite,
      ),
    ],
  );
}
