import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';

class NotificationSetup extends StatelessWidget {
  const NotificationSetup({
    super.key,
    required this.values,
    required this.onChanged,
  });
  final Map<String, bool> values;
  final void Function(String, bool) onChanged;
  static const icons = {
    'reviews': TmsIcons.checkCircle,
    'chat': TmsIcons.chat,
    'report': TmsIcons.edit,
    'clock': TmsIcons.clock,
    'birthdays': TmsIcons.birthday,
  };
  static const colors = {
    'reviews': DesignColor.amber,
    'chat': DesignColor.purple,
    'report': DesignColor.teal,
    'clock': DesignColor.blue,
    'birthdays': DesignColor.rose,
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DesignLabel(context.tr('onboarding.nudges_description')),
      const SizedBox(height: 20),
      DesignSection(
        children: [
          for (final entry in values.entries)
            SwitchListTile(
              secondary: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors[entry.key]!.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icons[entry.key],
                  color: colors[entry.key]!,
                  size: 20,
                ),
              ),
              title: Text(
                context.tr('onboarding.nudges.${entry.key}.title'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: DesignLabel(
                context.tr('onboarding.nudges.${entry.key}.description'),
              ),
              value: entry.value,
              onChanged: (value) => onChanged(entry.key, value),
            ),
        ],
      ),
    ],
  );
}
