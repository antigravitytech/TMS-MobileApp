import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';

import 'profile_avatar_picker.dart';

class BirthdaySetup extends StatelessWidget {
  const BirthdaySetup({
    super.key,
    required this.date,
    required this.visible,
    required this.name,
    required this.daysInMonth,
    required this.years,
    required this.onDay,
    required this.onMonth,
    required this.onYear,
    required this.onVisible,
  });
  final DateTime date;
  final bool visible;
  final String name;
  final int daysInMonth;
  final Iterable<int> years;
  final ValueChanged<int?> onDay, onMonth, onYear;
  final ValueChanged<bool> onVisible;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final locale = context.locale.toString();
    final number = NumberFormat('0', locale);
    final month = DateFormat.MMMM(locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('onboarding.birthday_description'),
          style: TextStyle(
            color: context.profileSetupMuted,
            fontSize: 15.5,
            height: 1.38,
          ),
        ),
        const SizedBox(height: 22),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: CustomPaint(
            painter: const _BirthdayGradient(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                spacing: 12,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0x1affffff),
                      border: Border.all(color: const Color(0x2affffff)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      TmsIcons.birthday,
                      color: Color(0xfff3f5fe),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('onboarding.birthday_colleagues'),
                          style: const TextStyle(
                            color: Color(0xffe9e9ed),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        Text(
                          tr(
                            'onboarding.birthday_preview',
                            namedArgs: {
                              'name': name,
                              'date':
                                  (context.locale.languageCode == 'en'
                                          ? DateFormat('d MMMM', locale)
                                          : DateFormat.MMMMd(locale))
                                      .format(date),
                            },
                          ),
                          style: const TextStyle(
                            color: Color(0xffc9cbe0),
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              SizedBox(
                width: (constraints.maxWidth * .4).clamp(0.0, 110.0),
                child: _BirthdayField(
                  label: tr('onboarding.birthday_day'),
                  value: date.day,
                  options: Iterable.generate(daysInMonth, (index) => index + 1),
                  format: number.format,
                  onChanged: onDay,
                ),
              ),
              Expanded(
                child: _BirthdayField(
                  label: tr('onboarding.birthday_month'),
                  value: date.month,
                  options: Iterable.generate(12, (index) => index + 1),
                  format: (value) => month.format(DateTime(2000, value)),
                  onChanged: onMonth,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _BirthdayField(
          label: tr('onboarding.birthday_year'),
          value: date.year,
          options: years,
          format: number.format,
          onChanged: onYear,
        ),
        const SizedBox(height: 18),
        Text(tr('onboarding.birthday_visibility'), style: _label(context)),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.dark ? context.panel : const Color(0xffe8eaf4),
            border: Border.all(color: context.outline),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            spacing: 4,
            children: [
              for (final (value, key) in const [
                (true, 'onboarding.birthday_visible'),
                (false, 'onboarding.birthday_private'),
              ])
                Expanded(
                  child: Semantics(
                    selected: value == visible,
                    child: AnimatedContainer(
                      duration: DesignMotion.duration(
                        context,
                        const Duration(milliseconds: 250),
                      ),
                      curve: DesignMotion.curve,
                      decoration: BoxDecoration(
                        color: value == visible
                            ? (context.dark ? context.raised : context.panel)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: value == visible
                            ? const [
                                BoxShadow(
                                  color: Color(0x55000000),
                                  blurRadius: 10,
                                  spreadRadius: -5,
                                  offset: Offset(0, 5),
                                ),
                              ]
                            : const [],
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: value == visible
                              ? context.foreground
                              : context.profileSetupMuted,
                          minimumSize: const Size(0, 38),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          textStyle: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        onPressed: () => onVisible(value),
                        child: Text(tr(key), textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

TextStyle _label(BuildContext context) => TextStyle(
  color: context.profileSetupMuted,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: 1.35,
);

class _BirthdayField extends StatelessWidget {
  const _BirthdayField({
    required this.label,
    required this.value,
    required this.options,
    required this.format,
    required this.onChanged,
  });
  final String label;
  final int value;
  final Iterable<int> options;
  final String Function(int) format;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: Text(label, style: _label(context))),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.panel,
            border: Border.all(color: context.outline),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(15),
              dropdownColor: context.panel,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              icon: Icon(
                TmsIcons.chevronDown,
                color: context.profileSetupMuted,
                size: 16,
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.foreground,
                fontSize: 16,
                letterSpacing: 0,
              ),
              items: [
                for (final option in options)
                  DropdownMenuItem(value: option, child: Text(format(option))),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BirthdayGradient extends CustomPainter {
  const _BirthdayGradient();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    void drawEllipse(Offset center, Size radius, RadialGradient gradient) {
      canvas.save();
      canvas.translate(center.dx * size.width, center.dy * size.height);
      canvas.scale(radius.width * size.width, radius.height * size.height);
      // Draw out to the edges of the card so the last stop fills the corners.
      final fill = Rect.fromLTRB(
        -center.dx / radius.width,
        -center.dy / radius.height,
        (1 - center.dx) / radius.width,
        (1 - center.dy) / radius.height,
      );
      canvas.drawRect(
        fill,
        Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: Offset.zero, radius: .5),
          ),
      );
      canvas.restore();
    }

    canvas.drawRect(bounds, Paint()..color = const Color(0xff1b1e45));
    drawEllipse(
      const Offset(.9, -.1),
      const Size(1.3, .9),
      const RadialGradient(
        radius: 1,
        colors: [
          Color(0xff4a4fa8),
          Color(0xff353b80),
          Color(0xff262a60),
          Color(0xff1b1e45),
        ],
        stops: [0, .22, .48, .8],
      ),
    );
    drawEllipse(
      const Offset(.1, 1.1),
      const Size(.6, .5),
      const RadialGradient(
        radius: 1,
        colors: [Color(0x332bb3a3), Color(0x002bb3a3)],
        stops: [0, .7],
      ),
    );
  }

  @override
  bool shouldRepaint(_BirthdayGradient oldDelegate) => false;
}
