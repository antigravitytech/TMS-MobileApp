import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../application/oauth_controller.dart';
import '../domain/account.dart';
import 'widgets/account_action_form.dart';

class OAuthCallbackScreen extends ConsumerStatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  ConsumerState<OAuthCallbackScreen> createState() =>
      _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _complete();
    });
  }

  Future<void> _complete() async {
    final params = context.routeData.queryParams;
    try {
      await ref
          .read(oauthControllerProvider)
          .finish(params.getString('code', ''), params.getString('state', ''));
      if (mounted) TmsRoute.account.reset(context);
    } on AccountFailure catch (error) {
      if (mounted) setState(() => _error = accountErrorMessage(context, error));
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.tr('network.errors.unknown'));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(
                    onPressed: () => TmsRoute.signIn.reset(context),
                    child: Text(context.tr('common.sign_in')),
                  ),
                ],
              ),
      ),
    ),
  );
}
