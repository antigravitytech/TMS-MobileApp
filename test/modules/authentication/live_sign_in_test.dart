import 'package:dio/dio.dart';
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
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/home/presentation/home_screen.dart';
import 'package:sabi_pipu_tms/router/router_config.dart';
import 'package:sabi_pipu_tms/router/tms_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live sign-in opens approved Home and can switch workspaces', (
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
    await _waitForDashboard(tester, 'Fixture task');
    expect(find.byType(LiveHomeScreen), findsOneWidget);
    expect(find.text('Fixture Company'), findsOneWidget);
    final company = container.read(activeLiveWorkspaceProvider)!;
    final companyState = container.read(liveHomeProvider(company));
    expect(companyState.hasValue, isTrue, reason: companyState.toString());
    expect(find.text('1 due today'), findsOneWidget);
    expect(find.text('Fixture task'), findsOneWidget);

    await tester.tap(find.byTooltip('Your account'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.text('Fixture Event'), findsOneWidget);
    await tester.ensureVisible(find.text('Fixture Event'));
    await tester.tap(find.text('Fixture Event'));
    await tester.pumpAndSettle();
    await _waitForDashboard(tester, 'Fixture Event');
    final guests = find.text('Guest list').first;
    await tester.ensureVisible(guests);
    await tester.tap(guests);
    await tester.pumpAndSettle();
    await _waitForDashboard(tester, 'Fixture guest');
    expect(find.byType(LiveHomeScreen), findsOneWidget);
    expect(find.text('Fixture Event'), findsOneWidget);
    expect(find.text('Guest list'), findsOneWidget);
    expect(find.text('Fixture guest'), findsOneWidget);

    await tester.tap(find.byTooltip('Your account'));
    await tester.pumpAndSettle();
    final addWorkspace = find.text('Add a workspace');
    await tester.ensureVisible(addWorkspace);
    await tester.tap(addWorkspace);
    await tester.pumpAndSettle();
    expect(find.text('Specials'), findsOneWidget);
    await router.replaceAll([NamedRoute(TmsRoute.account.name)]);
    await tester.pumpAndSettle();

    final signOut = find.widgetWithText(TextButton, 'Sign out');
    await tester.ensureVisible(signOut);
    await tester.pumpAndSettle();
    await tester.tap(signOut);
    await tester.pumpAndSettle();
    expect(router.current.path, '/sign-in');
    expect(await TokenUtils().getAccessToken(), isNull);
  });
}

Future<void> _waitForDashboard(WidgetTester tester, String title) async {
  for (
    var attempt = 0;
    attempt < 30 && find.text(title).evaluate().isEmpty;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
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
  Future<ApiResponse<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final dashboard = switch (path) {
      '/workspace/list-workspaces/' => {
        'items': [
          {
            'id': 'pending',
            'kind': 'family',
            'name': 'Fixture Pending',
            'approval_status': 'pending',
          },
          {
            'id': 'one',
            'kind': 'business',
            'name': 'Fixture Company',
            'approval_status': 'approved',
          },
          {
            'id': 'two',
            'kind': 'specials',
            'subtype': 'event',
            'name': 'Fixture Event',
            'approval_status': 'approved',
          },
        ],
        'total_pages': 1,
      },
      '/task/get-summary/one/' => {
        'my_tasks': {'due_today': 1, 'overdue': 0},
        'review': {'waiting': 0},
      },
      '/task/list-tasks/one/' => {
        'items': [
          {'title': 'Fixture task'},
        ],
      },
      '/event/get-event/two/' => {'name': 'Fixture Event'},
      '/event/list-guests/two/' => {
        'items': [
          {'id': 'fixture-guest', 'name': 'Fixture guest', 'rsvp': 'attending'},
        ],
      },
      _ => <String, dynamic>{},
    };
    expect(withToken, isTrue);
    return ApiResponse<T>.success(dashboard as T, statusCode: 200);
  }

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
    return super.noSuchMethod(invocation);
  }
}
