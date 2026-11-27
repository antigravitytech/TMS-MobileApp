import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../onboarding/data/onboarding_progress.dart';
import '../data/auth_repository.dart';
import '../domain/account.dart';
import 'account_session.dart';

enum AccountAction {
  register,
  recover,
  reset,
  verify,
  resend,
  requestEmailChange,
  confirmEmailChange,
  changePassword,
  unsubscribe,
}

final accountActionsProvider = Provider<AccountActions>(
  (ref) => AccountActions(
    ref.watch(authRepositoryProvider) as LiveAuthRepository,
    ref.read(accountSessionProvider.notifier),
  ),
);

class AccountActions {
  const AccountActions(this._repository, this._session);

  final LiveAuthRepository _repository;
  final AccountSession _session;

  Future<void> submit(
    AccountAction action,
    Map<String, String> fields, {
    Map<String, Object?> signup = const {},
  }) async {
    final email = fields['email']?.trim() ?? '';
    final password = fields['password'] ?? '';
    final token = fields['token']?.trim() ?? '';
    final code = fields['code']?.trim() ?? '';
    final first = fields['first_name']?.trim() ?? '';
    if ((const {
              AccountAction.register,
              AccountAction.recover,
              AccountAction.resend,
              AccountAction.requestEmailChange,
              AccountAction.unsubscribe,
            }.contains(action) &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) ||
        (const {
              AccountAction.register,
              AccountAction.reset,
              AccountAction.changePassword,
            }.contains(action) &&
            (password.length < 8 || password.length > 128)) ||
        (action == AccountAction.register &&
            (first.isEmpty || first.length > 255)) ||
        (const {
              AccountAction.reset,
              AccountAction.confirmEmailChange,
            }.contains(action) &&
            token.isEmpty) ||
        (action == AccountAction.verify &&
            token.isEmpty &&
            !RegExp(r'^\d{6}$').hasMatch(code))) {
      throw const AccountFailure(NetworkFailureType.validation);
    }

    switch (action) {
      case AccountAction.register:
        final account = await _repository.signup({
          ...signup,
          'first_name': first,
          'last_name': fields['last_name']?.trim(),
          'email': email,
          'password': password,
        });
        _session.update(account);
        await OnboardingProgress(account.id).save('profile');
      case AccountAction.recover:
        await _repository.requestReset(email);
      case AccountAction.reset:
        await _repository.confirmReset(token, password);
      case AccountAction.verify:
        if (token.isEmpty) {
          await _repository.verifyEmail(email: email, code: code);
        } else {
          await _repository.verifyEmail(token: token);
        }
        await _session.restore();
      case AccountAction.resend:
        await _repository.resendVerification(email);
      case AccountAction.requestEmailChange:
        await _authenticated(
          () => _repository.requestEmailChange(email, password),
        );
      case AccountAction.confirmEmailChange:
        await _repository.confirmEmailChange(token);
        await _session.restore();
      case AccountAction.changePassword:
        await _authenticated(
          () => _repository.changePassword(
            fields['current_password'] ?? '',
            password,
          ),
        );
        await _session.signOut();
      case AccountAction.unsubscribe:
        await _repository.unsubscribe(email);
    }
  }

  Future<void> _authenticated(Future<void> Function() operation) async {
    try {
      await operation();
    } on AccountFailure catch (error) {
      await _session.expire(error);
      rethrow;
    }
  }
}
