import '../../../core/network/api_response.dart';
import '../data/auth_repository.dart';
import '../domain/account.dart';
import 'account_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/workspace_kind.dart';

final signInProvider =
    NotifierProvider.autoDispose<SignInNotifier, SignInStatus>(
      SignInNotifier.new,
    );

enum SignInStatus { idle, busy, signedIn }

enum SignInResult { ignored, invalidCredentials, signedIn }

class SignInNotifier extends Notifier<SignInStatus> {
  @override
  SignInStatus build() => SignInStatus.idle;

  Future<SignInResult> signIn({
    required String email,
    required String password,
    required Duration delay,
    required bool remember,
  }) async {
    if (state != SignInStatus.idle) return SignInResult.ignored;
    if (!email.contains('@') || password.isEmpty) {
      return SignInResult.invalidCredentials;
    }
    state = SignInStatus.busy;
    final session = ref.read(accountSessionProvider.notifier);
    try {
      final account = await ref
          .read(authRepositoryProvider)
          .signIn(email.trim(), password, remember, delay);
      if (account != null) session.update(account);
    } on AccountFailure {
      if (ref.mounted) state = SignInStatus.idle;
      rethrow;
    } catch (_) {
      if (ref.mounted) state = SignInStatus.idle;
      throw const AccountFailure(NetworkFailureType.unknown);
    }
    if (!ref.mounted) return SignInResult.ignored;
    showSignedIn();
    return SignInResult.signedIn;
  }

  void showSignedIn() => state = SignInStatus.signedIn;

  Future<void> enterDemo(WorkspaceKind kind) =>
      ref.read(localWorkspacesProvider.notifier).enterDemo(kind.name);
}
