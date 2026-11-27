import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/app/tms_app.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/modules/authentication/data/auth_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/authentication/presentation/widgets/sign_in_ready.dart';
import 'package:sabi_pipu_tms/router/router_config.dart';
import 'package:sabi_pipu_tms/router/tms_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/english_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EnglishCatalog catalog;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    catalog = await EnglishCatalog.preload();
  });

  testWidgets('commits password autofill only after accepted credentials', (
    tester,
  ) async {
    if (!tester.testTextInput.isRegistered) {
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
    }
    final repository = _SignInFixture();
    final container = ProviderContainer.test(
      overrides: [
        environmentProvider.overrideWithValue(
          const AppEnvironment(source: DataSource.live),
        ),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TmsApp(assetLoader: catalog),
      ),
    );
    await tester.pump();
    await container.read(routerConfigProvider).replaceAll([
      NamedRoute(TmsRoute.signIn.name),
    ]);
    await tester.pumpAndSettle();

    final email = find.byType(TextField).first;
    final password = find.byType(TextField).last;
    expect(
      tester.widget<TextField>(email).autofillHints?.first,
      AutofillHints.username,
    );
    expect(tester.widget<TextField>(password).autofillHints, [
      AutofillHints.password,
    ]);

    Iterable<MethodCall> finishes() => tester.testTextInput.log.where(
      (call) => call.method == 'TextInput.finishAutofillContext',
    );

    await tester.enterText(email, 'member@example.test');
    await tester.enterText(password, 'incorrect-fixture-password');
    final submit = find.widgetWithText(FilledButton, 'Sign in');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(repository.attempts, 1);
    expect(finishes().where((call) => call.arguments == true), isEmpty);

    await tester.enterText(password, 'correct-fixture-password');
    tester.testTextInput.log.clear();
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(repository.attempts, 2);
    expect(find.byType(SignInReady), findsOneWidget);
    expect(finishes().first.arguments, isTrue);
    expect(finishes().where((call) => call.arguments == true), hasLength(1));
  });
}

class _SignInFixture implements AuthRepository {
  int attempts = 0;

  @override
  ({String email, String password}) get initialCredentials =>
      (email: '', password: '');

  @override
  Future<Account> signIn(
    String email,
    String password,
    bool remember,
    Duration delay,
  ) async {
    attempts++;
    if (password != 'correct-fixture-password') {
      throw const AccountFailure(NetworkFailureType.unauthorized);
    }
    return Account(
      id: 'fixture-autofill-account',
      email: email,
      firstName: 'Ari',
      lastName: 'Lee',
      verified: true,
    );
  }

  @override
  Future<Account?> restore() async => null;

  @override
  Future<void> signOut() async {}
}
