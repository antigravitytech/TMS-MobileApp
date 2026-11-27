import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/kit/kit_controls.dart';
import '../../../../shared/kit/kit.dart';
import '../../application/church_controller.dart';

/// Add a first-timer by name, from the welcome card.
Future<void> showFirstTimerSheet(
  BuildContext context,
  ChurchController actions,
) => designSheet<void>(
  context,
  title: context.tr('church.add_first_timer_title'),
  builder: (_) => _FirstTimerForm(actions: actions),
);

class _FirstTimerForm extends StatefulWidget {
  const _FirstTimerForm({required this.actions});
  final ChurchController actions;
  @override
  State<_FirstTimerForm> createState() => _FirstTimerFormState();
}

class _FirstTimerFormState extends State<_FirstTimerForm> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final done = context.tr('church.first_added', namedArgs: {'name': name});
    final failed = context.tr('workspaces.try_again');
    final ok = await widget.actions.addFirstTimer(name);
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? done : failed),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitInput(
        controller: _name,
        hint: c.tr('church.first_name_hint'),
        autofocus: true,
      ),
      const SizedBox(height: 8),
      Text(
        c.tr('church.first_note'),
        style: TextStyle(fontSize: 12, color: c.muted),
      ),
      const SizedBox(height: 16),
      DesignButton(c.tr('church.add'), onPressed: _save),
    ],
  );
}

/// `.urgent` banner on a unit card.
class ChurchUrgent extends StatelessWidget {
  const ChurchUrgent(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext c) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: KitColor.overdue.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: KitColor.overdue,
      ),
    ),
  );
}
