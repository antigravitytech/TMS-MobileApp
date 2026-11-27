import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

part 'widgets/birthday_overview.dart';

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
    ('birthdays.confetti', Color(0xff4933aa), TmsIcons.celebration),
    ('birthdays.warm_wishes', Color(0xff238664), TmsIcons.heart),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    styles[style].$2,
                    [
                      const Color(0xffb744a5),
                      const Color(0xff1b9f9d),
                      const Color(0xffd34e54),
                      const Color(0xff713bc3),
                      const Color(0xff50a044),
                    ][style],
                  ],
                ),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  const SizedBox(height: 46),
                  Text(
                    context.tr(
                      'birthdays.card_greeting',
                      namedArgs: {'name': person.split(' ').first},
                    ),
                    textAlign: TextAlign.left,
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 10,
                children: [
                  for (var i = 0; i < styles.length; i++)
                    GestureDetector(
                      onTap: () => update(() => style = i),
                      child: AnimatedContainer(
                        duration: DesignMotion.fast,
                        width: 62,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: style == i
                                ? context.foreground
                                : styles[i].$2,
                            width: 2,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              styles[i].$2,
                              [
                                const Color(0xffb744a5),
                                const Color(0xff1b9f9d),
                                const Color(0xffd34e54),
                                const Color(0xff713bc3),
                                const Color(0xff50a044),
                              ][i],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            DesignField(
              label: context.tr('birthdays.message'),
              initialValue: message,
              lines: 3,
              onChanged: (value) => update(() => message = value),
            ),
            DesignButton(
              context.tr('birthdays.send_card'),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (var i = 0; i < months.length; i++)
                GestureDetector(
                  onTap: () => setState(() => month = i),
                  child: Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: month == i ? DesignColor.purple : context.panel,
                      border: Border.all(color: context.outline),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          context.tr(months[i]).split('·').first.trim(),
                          style: TextStyle(
                            fontSize: 10,
                            color: month == i ? DesignColor.ink : context.muted,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          context.tr(months[i]).split('·').last.trim(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: month == i
                                ? DesignColor.ink
                                : context.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (people.isEmpty)
          DesignEmpty(
            context.tr('birthdays.nothing_to_celebrate_this_month'),
            context.tr('birthdays.choose_another_month'),
            icon: TmsIcons.birthday,
          ),
        if (month == 2)
          _BirthdayOverview(
            sent: state.birthdayCards,
            onSend: compose,
            onWish: () =>
                ref.read(workspacePreviewProvider).sendCard('Mama Bisi'),
          )
        else if (people.isNotEmpty) ...[
          DesignTitle(context.tr('birthdays.coming_up')),
          for (final (initials, name, date) in people)
            DesignTile(
              title: name,
              subtitle: date,
              leading: DesignAvatar(initials),
            ),
        ],
      ],
    );
  }
}
