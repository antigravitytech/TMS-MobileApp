import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import '../application/account_session.dart';
import '../domain/account.dart';
import 'widgets/account_action_form.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(accountSessionProvider, (previous, next) {
      if (previous != null && next == null && context.mounted) {
        TmsRoute.signIn.reset(context);
      }
    });
    final account = ref.watch(accountSessionProvider);
    if (account == null) {
      return Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => TmsRoute.signIn.reset(context),
            child: Text(context.tr('common.sign_in')),
          ),
        ),
      );
    }
    final workspaces = ref.watch(accountWorkspacesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('authentication.account'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${account.firstName} ${account.lastName}'.trim(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(account.email),
            if (!account.verified) ...[
              Text(context.tr('authentication.unverified')),
              TextButton(
                onPressed: () => showAccountAction(
                  context,
                  AccountAction.verify,
                  email: account.email,
                ),
                child: Text(context.tr('authentication.action.verify')),
              ),
              TextButton(
                onPressed: () async {
                  final sent = await showAccountAction(
                    context,
                    AccountAction.resend,
                    email: account.email,
                  );
                  if (context.mounted && sent == true) {
                    designToast(
                      context,
                      context.tr('authentication.verification_sent'),
                    );
                  }
                },
                child: Text(context.tr('authentication.action.resend')),
              ),
            ],
            FilledButton(
              onPressed: () => TmsRoute.profileSetup.open(context),
              child: Text(context.tr('authentication.edit_profile')),
            ),
            for (final action in [
              AccountAction.requestEmailChange,
              AccountAction.changePassword,
            ])
              TextButton(
                onPressed: () => showAccountAction(context, action),
                child: Text(context.tr('authentication.action.${action.name}')),
              ),
            workspaces.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                error is AccountFailure
                    ? accountErrorMessage(context, error)
                    : context.tr('network.errors.unknown'),
              ),
              data: (items) => Column(
                children: [
                  for (final item in items)
                    ListTile(
                      title: Text(item.name),
                      subtitle: Text(switch (item.approval) {
                        'approved' => context.tr(
                          'authentication.approval_approved',
                        ),
                        'rejected' =>
                          item.rejectionReason ??
                              context.tr('authentication.approval_rejected'),
                        _ => context.tr('authentication.approval_pending'),
                      }),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => TmsRoute.setup.open(context),
              child: Text(context.tr('authentication.add_workspace')),
            ),
            TextButton(
              onPressed: () => ref.invalidate(accountWorkspacesProvider),
              child: Text(context.tr('authentication.refresh_workspaces')),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await ref.read(accountSessionProvider.notifier).signOut();
                } catch (_) {
                  if (context.mounted) {
                    designToast(
                      context,
                      context.tr('network.errors.tokenStorage'),
                    );
                  }
                }
              },
              child: Text(context.tr('authentication.sign_out')),
            ),
          ],
        ),
      ),
    );
  }
}
