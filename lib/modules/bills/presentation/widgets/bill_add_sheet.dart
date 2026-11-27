import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/kit/kit_controls.dart';
import '../../application/bills_controller.dart';

/// "New bill" sheet: name, amount and due date.
Future<void> showBillAdd(BuildContext context, String workspaceId) =>
    designSheet<void>(
      context,
      title: context.tr('bills.new'),
      builder: (_) => _BillAddForm(workspaceId: workspaceId),
    );

class _BillAddForm extends ConsumerStatefulWidget {
  const _BillAddForm({required this.workspaceId});
  final String workspaceId;
  @override
  ConsumerState<_BillAddForm> createState() => _BillAddFormState();
}

class _BillAddFormState extends ConsumerState<_BillAddForm> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _due = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _due.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final done = context.tr('bills.added');
    final failed = context.tr('workspaces.try_again');
    final ok = await ref
        .read(billsControllerProvider(widget.workspaceId).notifier)
        .add(
          name: _name.text,
          amount: _amount.text,
          due: _due.text,
          fallbackName: context.tr('bills.example_name'),
          fallbackDue: context.tr('bills.example_due'),
        );
    if (!mounted) return;
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
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
        hint: c.tr('bills.name_hint'),
        autofocus: true,
      ),
      const SizedBox(height: 10),
      Row(
        spacing: 10,
        children: [
          Expanded(
            child: KitInput(
              controller: _amount,
              hint: c.tr('bills.amount_hint'),
              keyboardType: TextInputType.number,
            ),
          ),
          Expanded(
            child: KitInput(controller: _due, hint: c.tr('bills.due_hint')),
          ),
        ],
      ),
      const SizedBox(height: 18),
      DesignButton(c.tr('bills.add'), onPressed: _save),
    ],
  );
}
