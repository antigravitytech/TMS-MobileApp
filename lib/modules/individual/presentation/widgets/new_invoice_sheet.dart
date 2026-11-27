import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/kit/kit_controls.dart';
import '../../../../shared/kit/kit.dart';
import '../../application/new_invoice.dart';

/// The prototype's New invoice sheet: pick a client, type an amount or
/// take it from tracked time, then create and send.
Future<void> showNewInvoiceSheet(BuildContext context, String workspaceId) =>
    designSheet<void>(
      context,
      title: '',
      builder: (_) => _NewInvoiceForm(workspaceId),
    );

class _NewInvoiceForm extends ConsumerStatefulWidget {
  const _NewInvoiceForm(this.workspaceId);
  final String workspaceId;
  @override
  ConsumerState<_NewInvoiceForm> createState() => _NewInvoiceFormState();
}

class _NewInvoiceFormState extends ConsumerState<_NewInvoiceForm> {
  final _amount = TextEditingController();
  final _name = TextEditingController();
  String? _client;

  NewInvoice get _invoices => ref.read(newInvoiceProvider(widget.workspaceId));

  @override
  void dispose() {
    _amount.dispose();
    _name.dispose();
    super.dispose();
  }

  String _naira(int kobo) => NumberFormat.currency(
    locale: context.locale.toString(),
    symbol: '₦',
    decimalDigits: 0,
  ).format(kobo / 100);

  Future<void> _create(String client) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final naira = int.tryParse(_amount.text.replaceAll(RegExp(r'\D'), ''));
    final kobo = naira == null ? _invoices.fromTime : naira * 100;
    if (kobo <= 0) {
      return designToast(context, context.tr('individual.invoice.need_amount'));
    }
    final failed = context.tr('workspaces.try_again');
    final number = await _invoices.create(client, kobo);
    if (!mounted) return;
    if (number != null) navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          number == null
              ? failed
              : context.tr(
                  'individual.invoice.sent',
                  namedArgs: {'number': number, 'client': client},
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    final clients = _invoices.clients;
    final client = clients.isEmpty
        ? _name.text.trim()
        : _client ?? clients.first;
    final fromTime = _invoices.fromTime;
    final label = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: c.muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          c.tr('individual.invoice.title'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Text(c.tr('individual.invoice.client'), style: label),
        const SizedBox(height: 8),
        if (clients.isEmpty)
          KitInput(
            controller: _name,
            hint: c.tr('individual.invoice.client_hint'),
            onChanged: (_) => setState(() {}),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in clients)
                KitChip(
                  label: name,
                  selected: name == client,
                  onTap: () => setState(() => _client = name),
                ),
            ],
          ),
        const SizedBox(height: 14),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: KitInput(
                controller: _amount,
                hint: c.tr('individual.invoice.amount'),
                keyboardType: TextInputType.number,
              ),
            ),
            if (fromTime > 0)
              SizedBox(
                height: 54,
                child: KitMiniButton(
                  c.tr(
                    'individual.invoice.from_time',
                    namedArgs: {'amount': _naira(fromTime)},
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _amount.text = NumberFormat.decimalPattern(
                      c.locale.toString(),
                    ).format(fromTime ~/ 100);
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        DesignButton(
          c.tr('individual.invoice.create'),
          onPressed: client.isEmpty ? null : () => _create(client),
        ),
      ],
    );
  }
}
