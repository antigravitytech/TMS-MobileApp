import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/kit/kit_controls.dart';
import '../../application/estate_controller.dart';

/// New gate pass: who's coming and when, then a code for security.
Future<void> showPassSheet(BuildContext context, EstateController actions) =>
    designSheet<void>(
      context,
      title: context.tr('estate.new_pass_title'),
      builder: (_) => _PassForm(actions: actions),
    );

class _PassForm extends StatefulWidget {
  const _PassForm({required this.actions});
  final EstateController actions;
  @override
  State<_PassForm> createState() => _PassFormState();
}

class _PassFormState extends State<_PassForm> {
  final _who = TextEditingController();
  var when = passDays.keys.first;

  @override
  void dispose() {
    _who.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final who = _who.text.trim().isEmpty
        ? context.tr('estate.pass_example')
        : _who.text.trim();
    final failed = context.tr('workspaces.try_again');
    final code = await widget.actions.createPass(who, when);
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          code == null
              ? failed
              : context.tr('estate.code_sent', namedArgs: {'code': code}),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitInput(
        controller: _who,
        hint: c.tr('estate.who_hint'),
        autofocus: true,
      ),
      const SizedBox(height: 14),
      Text(
        c.tr('estate.when'),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: c.muted,
        ),
      ),
      const SizedBox(height: 8),
      KitSegment<String>(
        values: passDays.keys.toList(),
        selected: when,
        label: (k) => c.tr('estate.days.$k'),
        onChanged: (k) => setState(() => when = k),
      ),
      const SizedBox(height: 12),
      Text(
        c.tr('estate.share_hint'),
        style: TextStyle(fontSize: 12, color: c.muted),
      ),
      const SizedBox(height: 16),
      DesignButton(c.tr('estate.create_code'), onPressed: _create),
    ],
  );
}
