import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

class BirthdaysScreen extends ConsumerStatefulWidget {
  const BirthdaysScreen({super.key});
  @override
  ConsumerState<BirthdaysScreen> createState() => _BirthdaysScreenState();
}

class _BirthdaysScreenState extends ConsumerState<BirthdaysScreen> {
  int month = 2;
  static const months = [
    'birthdays.sep_0',
    'birthdays.oct_0',
    'birthdays.nov_5',
    'birthdays.dec_4',
    'birthdays.jan_2',
    'birthdays.feb_2',
    'birthdays.apr_1',
    'birthdays.jun_1',
  ];
  static const styles = [
    ('birthdays.confetti', Color(0xff6940c8), TmsIcons.celebration),
    ('birthdays.cake', Color(0xffa63990), TmsIcons.birthday),
    ('birthdays.warm_wishes', Color(0xff217b78), TmsIcons.heart),
  ];
  Future<void> compose(String person) async {
    var style = 0;
    var message = context.tr(
      'birthdays.card_template',
      namedArgs: {'name': person.split(' ').first},
    );
    final sent = await designSheet<bool>(
      context,
      title: context.tr('birthdays.send_a_birthday_card'),
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            AnimatedContainer(
              duration: DesignMotion.duration(context, DesignMotion.object),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: styles[style].$2,
                borderRadius: BorderRadius.circular(23),
              ),
              child: Column(
                spacing: 8,
                children: [
                  AnimatedSwitcher(
                    duration: DesignMotion.duration(
                      context,
                      DesignMotion.object,
                    ),
                    transitionBuilder: (child, motion) =>
                        ScaleTransition(scale: motion, child: child),
                    child: Icon(
                      styles[style].$3,
                      key: ValueKey(style),
                      size: 45,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    context.tr(
                      'birthdays.card_greeting',
                      namedArgs: {'name': person.split(' ').first},
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 23,
                      color: Colors.white,
                    ),
                  ),
                  DesignLabel(
                    context.tr('birthdays.card_signature'),
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            DesignTitle(context.tr('birthdays.pick_a_style')),
            DesignChoices(
              items: styles.map((s) => context.tr(s.$1)).toList(),
              selected: style,
              onChanged: (i) => update(() => style = i),
            ),
            DesignField(
              label: context.tr('birthdays.message'),
              initialValue: message,
              lines: 3,
              onChanged: (value) => update(() => message = value),
            ),
            DesignButton(
              context.tr('birthdays.send_card'),
              icon: TmsIcons.send,
              onPressed: message.trim().isEmpty
                  ? null
                  : () => Navigator.pop(sheet, true),
            ),
          ],
        ),
      ),
    );
    if (!mounted || sent != true) return;
    ref.read(workspacePreviewProvider).sendCard(person);
    designToast(
      context,
      context.tr(
        'birthdays.card_sent',
        namedArgs: {'name': person.split(' ').first},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspacePreviewProvider);
    final people = switch (month) {
      2 => [
        ('TB', 'Tunde Bakare', context.tr('common.today')),
        ('CO', 'Chioma Okafor', context.tr('common.today')),
        ('NA', 'Ngozi Adebayo', context.tr('common.today')),
        ('IM', 'Ibrahim Musa', context.tr('birthdays.27_november')),
        ('AE', 'Amaka Eze', context.tr('birthdays.29_november')),
      ],
      3 => [
        ('SJ', 'Sarah Johnson', context.tr('birthdays.4_december')),
        ('DM', 'David Martins', context.tr('birthdays.16_december')),
      ],
      4 => [('FA', 'Folake Adebayo', context.tr('birthdays.10_january'))],
      5 => [('AE', 'Amaka Eze', context.tr('birthdays.9_february'))],
      6 => [('IM', 'Ibrahim Musa', context.tr('birthdays.12_april'))],
      7 => [('NA', 'Ngozi Adebayo', context.tr('birthdays.15_june'))],
      _ => <(String, String, String)>[],
    };
    return DesignPage(
      title: context.tr('common.birthdays'),
      subtitle: context.tr('birthdays.15_to_celebrate_this_year'),
      children: [
        DesignChoices(
          items: months.map(context.tr).toList(),
          selected: month,
          onChanged: (i) => setState(() => month = i),
        ),
        if (people.isEmpty)
          DesignEmpty(
            context.tr('birthdays.nothing_to_celebrate_this_month'),
            context.tr('birthdays.choose_another_month'),
            icon: TmsIcons.birthday,
          ),
        if (people.isNotEmpty) ...[
          DesignTitle(
            month == 2
                ? context.tr('birthdays.today_3')
                : context.tr('birthdays.coming_up'),
          ),
          DesignSection(
            children: [
              for (final (initials, name, date) in people)
                DesignTile(
                  title: name,
                  subtitle: date,
                  leading: DesignAvatar(initials, color: DesignColor.rose),
                  trailing: TextButton(
                    onPressed: state.birthdayCards.contains(name)
                        ? null
                        : () => compose(name),
                    child: Text(
                      state.birthdayCards.contains(name)
                          ? context.tr('birthdays.sent')
                          : context.tr('common.send_a_card'),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
