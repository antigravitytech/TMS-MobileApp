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
  static const icons = [
    TmsIcons.checkCircle,
    TmsIcons.chat,
    TmsIcons.edit,
    TmsIcons.clock,
    TmsIcons.birthday,
  ];
  static const colors = [
    DesignColor.amber,
    DesignColor.purple,
    DesignColor.teal,
    DesignColor.blue,
    DesignColor.rose,
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DesignLabel(context.tr('onboarding.nudges_description')),
      const SizedBox(height: 20),
      DesignSection(
        children: [
          for (final (index, entry) in values.entries.indexed)
            SwitchListTile(
              secondary: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors[index].withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icons[index], color: colors[index], size: 20),
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
