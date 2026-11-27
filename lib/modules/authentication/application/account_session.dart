import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../onboarding/data/onboarding_progress.dart';
import '../data/auth_repository.dart';
import '../domain/account.dart';

final accountSessionProvider = NotifierProvider<AccountSession, Account?>(
  AccountSession.new,
);

final accountWorkspacesProvider =
    FutureProvider.autoDispose<List<AccountWorkspace>>((ref) async {
      final accountId = ref.watch(
        accountSessionProvider.select((account) => account?.id),
      );
      if (accountId == null) return [];
      final session = ref.read(accountSessionProvider.notifier);
      final repository =
          ref.watch(authRepositoryProvider) as LiveAuthRepository;
      try {
        final workspaces = await repository.workspaces();
        if (ref.mounted &&
            workspaces.any((workspace) => workspace.approval == 'pending')) {
          final timer = Timer(const Duration(seconds: 30), ref.invalidateSelf);
          ref.onDispose(timer.cancel);
        }
        return workspaces;
      } on AccountFailure catch (error) {
        await session.expire(error, accountId: accountId);
        rethrow;
      }
    });

class AccountSession extends Notifier<Account?> {
  @override
  Account? build() => null;

  Future<Account?> restore() async {
    final account = await ref.read(authRepositoryProvider).restore();
    state = account;
    return account;
  }

  Future<bool> shouldResumeOnboarding(Account account) async {
    final progress = await OnboardingProgress(account.id).load();
    return progress != null && progress != 'complete';
  }

  void update(Account account) => state = account;

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = null;
  }

  Future<bool> expire(AccountFailure error, {String? accountId}) async {
    if (error.type != NetworkFailureType.unauthorized) return false;
    if (state == null || (accountId != null && state?.id != accountId)) {
      return true;
    }
    await signOut();
    return true;
  }
}
