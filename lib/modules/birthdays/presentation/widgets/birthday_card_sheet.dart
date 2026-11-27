part of '../birthdays_screen.dart';

/// Card colours per style in [birthdayCardStyles], as gradient ends.
const _cardStyles = [
  ('birthdays.confetti', Color(0xff6940c8), Color(0xffb744a5)),
  ('birthdays.cake', Color(0xffa63990), Color(0xff1b9f9d)),
  ('birthdays.warm_wishes', Color(0xff217b78), Color(0xffd34e54)),
  ('birthdays.confetti', Color(0xff4933aa), Color(0xff713bc3)),
  ('birthdays.warm_wishes', Color(0xff238664), Color(0xff50a044)),
];

/// The "Send a birthday card" sheet. Returns the chosen style and message,
/// or null when dismissed.
Future<({int style, String message})?> _composeCard(
  BuildContext context, {
  required String to,
  required String from,
}) {
  var style = 0;
  var message = context.tr(
    'birthdays.card_template',
    namedArgs: {'name': to.split(' ').first},
  );
  LinearGradient gradient(int i) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_cardStyles[i].$2, _cardStyles[i].$3],
  );
  return designSheet<({int style, String message})>(
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
              gradient: gradient(style),
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
                    namedArgs: {'name': to.split(' ').first},
                  ),
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 23,
                    color: Colors.white,
                  ),
                ),
                DesignLabel(
                  context.tr(
                    'birthdays.card_signature',
                    namedArgs: {'name': from},
                  ),
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
                for (var i = 0; i < _cardStyles.length; i++)
                  Semantics(
                    button: true,
                    selected: style == i,
                    label: context.tr(_cardStyles[i].$1),
                    child: GestureDetector(
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
                                : _cardStyles[i].$2,
                            width: 2,
                          ),
                          gradient: gradient(i),
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
                : () => Navigator.pop(sheet, (style: style, message: message)),
          ),
        ],
      ),
    ),
  );
}
