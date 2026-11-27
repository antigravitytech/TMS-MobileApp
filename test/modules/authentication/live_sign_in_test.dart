import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/app/tms_app.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/core/network/token_utils.dart';
import 'package:sabi_pipu_tms/modules/authentication/presentation/account_screen.dart';
import 'package:sabi_pipu_tms/router/router_config.dart';
import 'package:sabi_pipu_tms/router/tms_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live sign-in reaches the account and excludes demo workspaces', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    late Map<String, dynamic> catalog;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      catalog = (await const RootBundleAssetLoader().load(
        'assets/translations',
        const Locale('en'),
      ))!;
    });

    final calls = _AccountCalls();
    final container = ProviderContainer.test(
      overrides: [
        environmentProvider.overrideWithValue(
          const AppEnvironment(source: DataSource.live),
        ),
        networkCallsRepositoryProvider.overrideWithValue(calls),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TmsApp(assetLoader: _Catalog(catalog)),
      ),
    );
    await tester.pump();
    final router = container.read(routerConfigProvider);
    await router.replaceAll([NamedRoute(TmsRoute.signIn.name)]);
    await tester.pumpAndSettle();

    expect(find.text('Try a demo'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, 'member@example.test');
    await tester.enterText(find.byType(TextField).last, 'fixture-password');
    final signIn = find.widgetWithText(FilledButton, 'Sign in');
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await tester.pumpAndSettle();
    expect(calls.loginPayload, {
      'email': 'member@example.test',
      'password': 'fixture-password',
      'remember_me': true,
    });
    expect(await TokenUtils().getAccessToken(), 'fixture-access-token');
    final open = find.byType(FilledButton).last;
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.text('Fixture Company'), findsOneWidget);
    expect(find.text('Fixture Event'), findsNothing);

    final signOut = find.text('Sign out');
    await tester.ensureVisible(signOut);
    await tester.tap(signOut);
    await tester.pumpAndSettle();
    expect(router.current.path, '/sign-in');
    expect(await TokenUtils().getAccessToken(), isNull);
  });
}

class _Catalog extends AssetLoader {
  const _Catalog(this.catalog);

  final Map<String, dynamic> catalog;

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      catalog;
}

class _AccountCalls implements NetworkCallsRepository {
  Object? loginPayload;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final path = invocation.positionalArguments.first;
    if (path == '/auth/login/') {
      expect(invocation.namedArguments[#withToken], isFalse);
      loginPayload = invocation.namedArguments[#data];
      return Future.value(
        ApiResponse<Map<String, dynamic>>.success({
          'user': {
            'id': 'live-widget-fixture',
            'email': 'member@example.test',
            'first_name': 'Ari',
            'last_name': 'Lee',
            'is_verified': true,
          },
          'access_token': 'fixture-access-token',
          'token_type': 'bearer',
        }, statusCode: 200),
      );
    }
    if (path == '/workspace/list-workspaces/') {
      return Future.value(
        ApiResponse<Map<String, dynamic>>.success({
          'items': [
            {
              'id': 'one',
              'kind': 'business',
              'name': 'Fixture Company',
              'approval_status': 'approved',
            },
            {
              'id': 'two',
              'kind': 'specials',
              'name': 'Fixture Event',
              'approval_status': 'approved',
            },
          ],
          'total_pages': 1,
        }, statusCode: 200),
      );
    }
    return super.noSuchMethod(invocation);
  }
}
