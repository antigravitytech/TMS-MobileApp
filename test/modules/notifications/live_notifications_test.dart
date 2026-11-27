import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/app/tms_app.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/home/data/live_dashboard_data.dart';
import 'package:sabi_pipu_tms/modules/notifications/presentation/widgets/live_notification_bell.dart';
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

  testWidgets('Home opens the scoped inbox and read actions update the badge', (
    tester,
  ) async {
    final transport = _NotificationTransport();
    final workspace = AccountWorkspace.fromJson({
      'id': 'fixture-workspace',
      'name': 'Fixture Company',
      'kind': 'business',
      'approval_status': 'approved',
    });
    final container = ProviderContainer.test(
      overrides: [
        environmentProvider.overrideWithValue(
          const AppEnvironment(source: DataSource.live),
        ),
        networkCallsRepositoryProvider.overrideWithValue(transport),
        accountWorkspacesProvider.overrideWith((ref) async => [workspace]),
        liveHomeProvider(workspace).overrideWith(
          (ref) async => (data: LiveHomeData(workspace, {}, {}), space: null),
        ),
      ],
    );
    container
        .read(accountSessionProvider.notifier)
        .update(
          const Account(
            id: 'fixture-account',
            email: 'member@example.test',
            firstName: 'Ari',
            lastName: 'Lee',
            verified: true,
          ),
        );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TmsApp(assetLoader: catalog),
      ),
    );
    await tester.pump();
    final router = container.read(routerConfigProvider);
    await router.replaceAll([NamedRoute(TmsRoute.home.name)]);
    await tester.pumpAndSettle();

    final bell = find.byType(LiveNotificationBell);
    Finder badge(String value) =>
        find.descendant(of: bell, matching: find.text(value));
    expect(badge('2'), findsOneWidget);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(router.current.path, '/notifications');

    expect(find.text('Fixture task assigned'), findsOneWidget);
    expect(find.text('Fixture already read'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.text('Fixture mention'), findsOneWidget);
    expect(transport.pages, [(false, 1), (false, 2)]);

    await tester.tap(find.text('Fixture task assigned'));
    await tester.pumpAndSettle();
    expect(transport.writes, ['/notification/mark-read/task/']);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(badge('1'), findsOneWidget);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unread only'));
    await tester.pumpAndSettle();
    expect(transport.pages.last, (true, 1));
    expect(find.text('Fixture task assigned'), findsNothing);
    expect(find.text('Fixture already read'), findsNothing);
    expect(find.text('Fixture mention'), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(
      transport.writes.last,
      '/notification/mark-all-read/fixture-workspace/',
    );
    expect(find.text('Fixture mention'), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: bell, matching: find.byType(Badge)),
      findsNothing,
    );
  });
}

class _NotificationTransport implements NetworkCallsRepository {
  final unread = {'task', 'mention'};
  final pages = <(bool, int)>[];
  final writes = <String>[];

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
    expect(withToken, isTrue);
    if (path == '/notification/get-unread-count/fixture-workspace/') {
      return ApiResponse<T>.success(
        <String, dynamic>{'unread': unread.length} as T,
      );
    }
    expect(path, '/notification/list-notifications/fixture-workspace/');
    final params = queryParameters!;
    final unreadOnly = params['unread_only'] as bool;
    final page = params['page'] as int;
    expect(params['page_size'], 20);
    pages.add((unreadOnly, page));
    final items = <Map<String, dynamic>>[
      _item('task', 'Fixture task assigned'),
      _item('read', 'Fixture already read'),
      _item('mention', 'Fixture mention'),
    ].where((item) => !unreadOnly || item['is_read'] == false).toList();
    return ApiResponse<T>.success(
      <String, dynamic>{
            'items': items.skip((page - 1) * 2).take(2).toList(),
            'total_pages': (items.length / 2).ceil(),
          }
          as T,
    );
  }

  Map<String, dynamic> _item(String id, String message) => {
    'id': id,
    'kind': 'task_mention',
    'message': message,
    'actor': {'first_name': 'Ari', 'last_name': 'Lee'},
    'is_read': !unread.contains(id),
    'created_at': '2026-11-19T10:00:00Z',
  };

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    ResponseType? responseType,
  }) async {
    expect(withToken, isTrue);
    writes.add(path);
    switch (path) {
      case '/notification/mark-read/task/':
        unread.remove('task');
      case '/notification/mark-all-read/fixture-workspace/':
        unread.clear();
      default:
        fail('Unexpected notification mutation');
    }
    return ApiResponse<T>.success(
      <String, dynamic>{'message': 'Fixture complete'} as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
