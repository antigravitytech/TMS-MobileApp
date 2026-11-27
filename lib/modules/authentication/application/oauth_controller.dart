import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/services/browser_service.dart';
import '../data/auth_repository.dart';
import '../domain/account.dart';
import 'account_session.dart';

enum OAuthProvider { google, microsoft }

final oauthControllerProvider = Provider<OAuthController>(
  (ref) => OAuthController(
    ref.watch(environmentProvider).oauthCallback,
    ref.watch(authRepositoryProvider),
    ref.read(accountSessionProvider.notifier),
  ),
);

class OAuthController {
  OAuthController(this._redirect, this._repository, this._session);

  final Uri? _redirect;
  final AuthRepository _repository;
  final AccountSession _session;
  ({OAuthProvider provider, String state})? _pending;
  bool _busy = false;

  Future<void> start(OAuthProvider provider) async {
    final redirect = _redirect;
    final repository = _repository;
    if (redirect == null || repository is! LiveAuthRepository || _busy) return;
    _busy = true;
    _pending = null;
    try {
      final result = await repository.startOAuth(provider.name);
      final url = result.url;
      final host = switch (provider) {
        OAuthProvider.google => 'accounts.google.com',
        OAuthProvider.microsoft => 'login.microsoftonline.com',
      };
      if (url.scheme != 'https' ||
          url.host != host ||
          url.userInfo.isNotEmpty ||
          result.state.isEmpty ||
          url.queryParameters['state'] != result.state ||
          url.queryParameters['redirect_uri'] != redirect.toString()) {
        throw const AccountFailure(NetworkFailureType.configuration);
      }
      _pending = (provider: provider, state: result.state);
      if (!await BrowserService.open(url)) {
        throw const AccountFailure(NetworkFailureType.configuration);
      }
    } catch (_) {
      _pending = null;
      rethrow;
    } finally {
      _busy = false;
    }
  }

  Future<void> finish(String code, String state) async {
    final pending = _pending;
    _pending = null;
    final redirect = _redirect;
    final repository = _repository;
    if (pending == null ||
        redirect == null ||
        repository is! LiveAuthRepository ||
        pending.state != state ||
        code.isEmpty) {
      throw const AccountFailure(NetworkFailureType.validation);
    }
    _session.update(
      await repository.finishOAuth(
        pending.provider.name,
        code,
        state,
        redirect,
      ),
    );
  }
}
