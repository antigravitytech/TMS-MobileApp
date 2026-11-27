import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/core/services/shared_pref_service.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/settings/application/settings_controller.dart';
import 'package:sabi_pipu_tms/modules/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesService.init();
  });

  test('mock switches stay on the device', () async {
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    expect(c.read(settingsRepositoryProvider), isA<MockSettingsRepository>());
    final sub = c.listen(settingsNoticesProvider, (_, _) {});
    addTearDown(sub.close);
    final notices = await c.read(settingsNoticesProvider.future);
    expect(notices['sounds_vibration'], isFalse);
    await c
        .read(settingsNoticesProvider.notifier)
        .toggle('sounds_vibration', true);
    expect(DeviceNotices.read('sounds_vibration'), isTrue);
  });

  group('live settings', () {
    late _Transport transport;
    late ProviderContainer c;

    setUp(() {
      transport = _Transport();
      c = ProviderContainer.test(
        overrides: [
          environmentProvider.overrideWithValue(
            const AppEnvironment(source: DataSource.live),
          ),
          networkCallsRepositoryProvider.overrideWithValue(transport),
          activeLiveWorkspaceProvider.overrideWithValue(
            AccountWorkspace.fromJson({
              'id': 'ws',
              'name': 'Acme',
              'kind': 'business',
              'approval_status': 'approved',
            }),
          ),
        ],
      );
      c
          .read(accountSessionProvider.notifier)
          .update(
            const Account(
              id: 'me',
              email: 'me@example.test',
              firstName: 'Ari',
              lastName: 'Lee',
              verified: true,
            ),
          );
    });

    test('reads server switches and keeps device ones local', () async {
      final notices = await c.read(settingsRepositoryProvider).notices();
      expect(notices['reviews_mentions'], isTrue);
      expect(notices['daily_report_reminder'], isFalse);
      expect(notices['push_notifications'], isTrue);
      await c.read(settingsRepositoryProvider).setNotice('quiet_hours', false);
      expect(transport.write, isNull);
      expect(DeviceNotices.read('quiet_hours'), isFalse);
    });

    test('a server switch keeps each event\'s email choice', () async {
      await c
          .read(settingsRepositoryProvider)
          .setNotice('daily_report_reminder', true);
      expect(transport.write?.$1, '/notification/update-preferences/ws/');
      expect(transport.write?.$2, {
        'events': [
          {'event': 'reminder', 'in_app': true, 'email': true},
        ],
      });
    });

    test('a failed switch goes back', () async {
      transport.failWrites = true;
      final sub = c.listen(settingsNoticesProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(settingsNoticesProvider.future);
      await expectLater(
        c
            .read(settingsNoticesProvider.notifier)
            .toggle('reviews_mentions', false),
        throwsA(isA<AccountFailure>()),
      );
      expect(
        c.read(settingsNoticesProvider).requireValue['reviews_mentions'],
        isTrue,
      );
    });

    test('theme saves to the account; system stays local', () async {
      final actions = c.read(settingsActionsProvider);
      await actions.saveTheme(ThemeMode.system);
      expect(transport.write, isNull);
      await actions.saveTheme(ThemeMode.light);
      expect(transport.write?.$1, '/auth/update-profile-json/');
      expect(transport.write?.$2, {'theme': 'light'});
      expect(c.read(accountSessionProvider)?.theme, 'light');
    });
  });
}

class _Transport implements NetworkCallsRepository {
  (String, Object?)? write;
  bool failWrites = false;

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
    expect(path, '/notification/get-preferences/ws/');
    return ApiResponse<T>.success(
      <String, dynamic>{
            'events': [
              {'event': 'submitted', 'in_app': false, 'email': true},
              {'event': 'mention', 'in_app': true, 'email': false},
              {'event': 'reminder', 'in_app': false, 'email': true},
            ],
          }
          as T,
    );
  }

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    if (failWrites) {
      return ApiResponse<T>.error(
        "boom",
        failureType: NetworkFailureType.server,
      );
    }
    write = (path, data);
    return ApiResponse<T>.success(<String, dynamic>{} as T);
  }

  @override
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool withToken = true,
    CancelToken? cancelToken,
    bool logResponse = false,
  }) async {
    write = (path, data);
    return ApiResponse<T>.success(
      <String, dynamic>{
            'id': 'me',
            'email': 'me@example.test',
            'is_verified': true,
            'theme': 'light',
          }
          as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
