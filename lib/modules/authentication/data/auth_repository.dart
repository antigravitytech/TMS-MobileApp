import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../../core/network/token_utils.dart';
import '../domain/account.dart';

part 'live_auth_repository.dart';
part 'mock_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) return const MockAuthRepository();
  return LiveAuthRepository(
    ref.watch(networkCallsRepositoryProvider),
    TokenUtils(),
  );
});

abstract class AuthRepository {
  ({String email, String password}) get initialCredentials;
  Future<Account?> signIn(
    String email,
    String password,
    bool remember,
    Duration delay,
  );
  Future<Account?> restore();
  Future<void> signOut();
}
