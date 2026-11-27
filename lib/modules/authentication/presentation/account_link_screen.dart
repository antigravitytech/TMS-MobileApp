import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import 'widgets/account_action_form.dart';

class AccountLinkScreen extends ConsumerWidget {
  const AccountLinkScreen(this.action, {super.key});

  final AccountAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(environmentProvider).isLive;
    final params = context.routeData.queryParams;
    final token = params.getString('token', '');
    final email = params.getString('email', '');
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('authentication.action.${action.name}')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (live &&
                (action != AccountAction.verify ||
                    token.isNotEmpty ||
                    email.isNotEmpty))
              AccountActionForm(
                action,
                email,
                token,
                const {},
                onComplete: () {
                  designToast(
                    context,
                    context.tr('authentication.action_complete'),
                  );
                  TmsRoute.splash.reset(context);
                },
              )
            else
              FilledButton(
                onPressed: () => TmsRoute.signIn.reset(context),
                child: Text(context.tr('common.sign_in')),
              ),
          ],
        ),
      ),
    );
  }
}
