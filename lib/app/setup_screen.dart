import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../shared/design/tms_icons.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  TmsIcons.dashboard,
                  color: theme.colorScheme.primary,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('app.title'),
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('app.setup_status'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
