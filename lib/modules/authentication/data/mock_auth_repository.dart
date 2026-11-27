part of 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  @override
  ({String email, String password}) get initialCredentials =>
      (email: 'chioma@acmegroup.com', password: 'preview-password');

  @override
  Future<Account?> signIn(
    String email,
    String password,
    bool remember,
    Duration delay,
  ) async {
    await Future<void>.delayed(delay);
    return null;
  }

  @override
  Future<Account?> restore() async => null;

  @override
  Future<void> signOut() async {}
}
