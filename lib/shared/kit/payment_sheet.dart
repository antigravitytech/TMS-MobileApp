import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/design_widgets.dart';
import 'kit_controls.dart';
import 'kit.dart';

/// "Record a payment" sheet shared by Bills and the Specials dues and levies:
/// pick a share of the balance and how it was paid, then confirm.
///
/// [shares] are (label, kobo) choices; [methods] are codes that [method]
/// translates. [onConfirm] saves and returns false when it failed;
/// [saved] builds the success message for the chosen amount.
Future<void> showPaymentSheet(
  BuildContext context, {
  required String eyebrow,
  required String title,
  required String balance,
  required List<(String, int)> shares,
  required List<String> methods,
  required String Function(String) method,
  required String Function(int kobo) amount,
  required Future<bool> Function(int kobo, String method) onConfirm,
  required String Function(int kobo) saved,
}) => designSheet<void>(
  context,
  title: '',
  builder: (_) => _PaymentForm(
    eyebrow: eyebrow,
    title: title,
    balance: balance,
    shares: shares,
    methods: methods,
    method: method,
    amount: amount,
    onConfirm: onConfirm,
    saved: saved,
  ),
);

class _PaymentForm extends StatefulWidget {
  const _PaymentForm({
    required this.eyebrow,
    required this.title,
    required this.balance,
    required this.shares,
    required this.methods,
    required this.method,
    required this.amount,
    required this.onConfirm,
    required this.saved,
  });
  final String eyebrow, title, balance;
  final List<(String, int)> shares;
  final List<String> methods;
  final String Function(String) method;
  final String Function(int) amount;
  final Future<bool> Function(int, String) onConfirm;
  final String Function(int) saved;
  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  var share = 0;
  late var method = widget.methods.first;

  Future<void> _confirm() async {
    final kobo = widget.shares[share].$2;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final done = widget.saved(kobo);
    final failed = context.tr('workspaces.try_again');
    final ok = await widget.onConfirm(kobo, method);
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
      Text(widget.eyebrow, style: TextStyle(fontSize: 12, color: c.muted)),
      const SizedBox(height: 2),
      Text(
        widget.title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(widget.balance, style: TextStyle(fontSize: 13.5, color: c.muted)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (i, (label, _)) in widget.shares.indexed)
            KitChip(
              label: label,
              selected: share == i,
              onTap: () => setState(() => share = i),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        c.tr('specials.paid_with'),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: c.muted,
        ),
      ),
      const SizedBox(height: 8),
      KitSegment<String>(
        values: widget.methods,
        selected: method,
        label: widget.method,
        onChanged: (m) => setState(() => method = m),
      ),
      const SizedBox(height: 20),
      DesignButton(
        c.tr(
          'specials.record_amount',
          namedArgs: {'amount': widget.amount(widget.shares[share].$2)},
        ),
        onPressed: _confirm,
      ),
    ],
  );
}
