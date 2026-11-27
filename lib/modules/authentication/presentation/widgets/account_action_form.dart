import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/network_failure_localization.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../application/account_actions.dart';
import '../../domain/account.dart';

export '../../application/account_actions.dart' show AccountAction;

String accountErrorMessage(BuildContext context, AccountFailure error) =>
    switch (error.code) {
      'workspace_pending_approval' => context.tr(
        'authentication.approval_pending',
      ),
      'workspace_rejected' => context.tr('authentication.approval_rejected'),
      _ => error.type.localizedMessage(context),
    };

Future<bool?> showAccountAction(
  BuildContext context,
  AccountAction action, {
  String email = '',
  String token = '',
  Map<String, Object?> signup = const {},
}) => designSheet<bool>(
  context,
  title: context.tr('authentication.action.${action.name}'),
  builder: (sheetContext) => AccountActionForm(
    action,
    email,
    token,
    signup,
    onComplete: () => Navigator.of(sheetContext).pop(true),
  ),
);

class AccountActionForm extends ConsumerStatefulWidget {
  const AccountActionForm(
    this.action,
    this.email,
    this.token,
    this.signup, {
    super.key,
    required this.onComplete,
  });

  final AccountAction action;
  final VoidCallback onComplete;
  final String email, token;
  final Map<String, Object?> signup;

  @override
  ConsumerState<AccountActionForm> createState() => _ActionFormState();
}

class _ActionFormState extends ConsumerState<AccountActionForm> {
  late final values = {'email': widget.email, 'token': widget.token};
  late var action = widget.action;
  bool busy = false;
  String? feedback;

  Future<void> submit() async {
    if (busy) return;
    setState(() {
      busy = true;
      feedback = null;
    });
    try {
      await ref
          .read(accountActionsProvider)
          .submit(action, values, signup: widget.signup);
      if (!mounted) return;
      if (action == AccountAction.recover) {
        setState(() {
          action = AccountAction.reset;
          feedback = context.tr('authentication.reset_sent');
        });
      } else if (action == AccountAction.requestEmailChange) {
        setState(() {
          action = AccountAction.confirmEmailChange;
          feedback = context.tr('authentication.email_change_sent');
        });
      } else {
        widget.onComplete();
      }
    } on AccountFailure catch (error) {
      if (mounted) {
        setState(() => feedback = accountErrorMessage(context, error));
      }
    } catch (_) {
      if (mounted) {
        setState(() => feedback = context.tr('network.errors.unknown'));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(String name, {bool secret = false}) => TextFormField(
    key: ValueKey(name),
    initialValue: values[name],
    enabled: !busy,
    obscureText: secret,
    autocorrect: false,
    keyboardType: switch (name) {
      'email' => TextInputType.emailAddress,
      'code' => TextInputType.number,
      _ => TextInputType.text,
    },
    decoration: InputDecoration(
      labelText: context.tr('authentication.field.$name'),
    ),
    onChanged: (value) => values[name] = value,
  );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (action == AccountAction.register) ...[
        field('first_name'),
        field('last_name'),
      ],
      if (const {
        AccountAction.register,
        AccountAction.recover,
      }.contains(action))
        field('email'),
      if (const {
            AccountAction.reset,
            AccountAction.confirmEmailChange,
          }.contains(action) &&
          widget.token.isEmpty)
        field('token'),
      if (action == AccountAction.verify && widget.token.isEmpty) field('code'),
      if (action == AccountAction.changePassword)
        field('current_password', secret: true),
      if (const {
        AccountAction.register,
        AccountAction.reset,
        AccountAction.requestEmailChange,
        AccountAction.changePassword,
      }.contains(action))
        field('password', secret: true),
      if (feedback case final message?)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(message),
        ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: busy ? null : submit,
        child: Text(context.tr('authentication.action.${action.name}')),
      ),
      if (action == AccountAction.recover)
        TextButton(
          onPressed: busy
              ? null
              : () => setState(() => action = AccountAction.reset),
          child: Text(context.tr('authentication.action.reset')),
        ),
    ],
  );
}
