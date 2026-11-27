import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/core/services/location_service.dart';
import 'package:sabi_pipu_tms/modules/attendance/application/attendance_controller.dart';
import 'package:sabi_pipu_tms/modules/attendance/data/attendance_repository.dart';
import 'package:sabi_pipu_tms/modules/attendance/domain/attendance.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';

void main() {
  test('mock attendance clocks in and out without the network', () async {
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    expect(
      c.read(attendanceRepositoryProvider),
      isA<MockAttendanceRepository>(),
    );
    final sub = c.listen(attendanceTodayProvider, (_, _) {});
    addTearDown(sub.close);
    final today = await c.read(attendanceTodayProvider.future);
    expect(today.status, DayStatus.notClockedIn);
    await c.read(attendanceTodayProvider.notifier).clockIn();
    expect(c.read(attendanceTodayProvider).requireValue.clockedIn, isTrue);
    await c.read(attendanceTodayProvider.notifier).clockOut();
    expect(c.read(attendanceTodayProvider).requireValue.clockedOut, isTrue);
    final stats = await c.read(attendanceMonthProvider.future);
    expect(stats.lateLimit, 5);
  });

  group('live attendance', () {
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
          locationServiceProvider.overrideWithValue(_Here()),
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

    test('today, month, history and board map the documented shapes', () async {
      final repo = c.read(attendanceRepositoryProvider);
      final today = await repo.today();
      expect(
        (today.status, today.place, today.window.until),
        (DayStatus.notClockedIn, 'Head office', '09:30'),
      );
      expect(await repo.weather(today), (celsius: 30, code: 2));

      final stats = await repo.month();
      expect(
        (stats.early, stats.onTime, stats.late, stats.absent),
        (3, 10, 2, 1),
      );
      expect(
        (stats.punctuality, stats.avgIn, stats.lateLimit),
        (81, '08:57', 5),
      );
      expect(stats.days.last.$2, DayStatus.onTime);

      final history = await repo.history();
      expect(history.single.minutesWorked, 553);
      expect(transport.queries['/attendance/list-records/ws/'], {
        'page_size': 30,
      });

      final board = await repo.board();
      expect(
        (board.single.name, board.single.status),
        ('Ada Obi', DayStatus.late),
      );
    });

    test('clock-in sends the position; a refusal carries the reason', () async {
      final sub = c.listen(attendanceTodayProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(attendanceTodayProvider.future);
      await c.read(attendanceTodayProvider.notifier).clockIn();
      expect(transport.writes.last.$1, '/attendance/clock-in/ws/');
      expect(transport.writes.last.$2, {
        'lat': 6.4,
        'lng': 3.4,
        'accuracy_m': 18,
      });
      expect(c.read(attendanceTodayProvider).requireValue.clockedIn, isTrue);

      transport.refuse = true;
      await expectLater(
        c.read(attendanceTodayProvider.notifier).clockOut(),
        throwsA(
          isA<AttendanceRefused>().having(
            (e) => e.detail,
            'detail',
            "You're 1.2 km from Head office.",
          ),
        ),
      );
    });

    test('weather is hidden when unavailable', () async {
      transport.noWeather = true;
      final repo = c.read(attendanceRepositoryProvider);
      expect(await repo.weather(await repo.today()), isNull);
    });
  });
}

class _Here implements LocationService {
  @override
  Future<DevicePosition?> current() async =>
      (lat: 6.4, lng: 3.4, accuracy: 18.2);
}

Map<String, dynamic> _record({bool open = true}) => {
  'date': '2026-11-27',
  'clock_in_at': '2026-11-27T08:42:00Z',
  'clock_out_at': open ? null : '2026-11-27T17:55:00Z',
  'in_status': 'late',
  'minutes_worked': open ? null : 553,
  'place': 'Head office',
};

Map<String, dynamic> _today({Map<String, dynamic>? record}) => {
  'date': '2026-11-27',
  'status': record == null ? 'not_clocked_in' : 'late',
  'record': record,
  'enabled': true,
  'schedule': {'start': '09:00', 'start_until': '09:30', 'end': '17:00'},
  'locations': [
    {
      'name': 'Head office',
      'center': {'lat': 6.4281, 'lng': 3.4219},
    },
  ],
};

class _Transport implements NetworkCallsRepository {
  final writes = <(String, Object?)>[];
  final queries = <String, Map<String, dynamic>?>{};
  var refuse = false, noWeather = false;

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
    queries[path] = queryParameters;
    if (path == '/attendance/get-weather/ws/' && noWeather) {
      return ApiResponse<T>.error(
        'Weather is unavailable right now.',
        statusCode: 503,
        failureType: NetworkFailureType.server,
      );
    }
    final Object body = switch (path) {
      '/attendance/get-today/ws/' => _today(),
      '/attendance/get-weather/ws/' => {'temperature_c': 30, 'code': 2},
      '/attendance/get-stats/ws/' => {
        'early': 3,
        'on_time': 10,
        'late': 2,
        'absent': 1,
        'punctuality': 81,
        'avg_clock_in': '08:57',
        'avg_clock_out': '17:22',
        'minutes_worked': 7420,
        'late_limit': 5,
        'days': [
          {'date': '2026-11-26', 'status': 'on_time'},
        ],
      },
      '/attendance/list-records/ws/' => {
        'items': [_record(open: false)],
      },
      '/attendance/list-board/ws/' => [
        {
          'user': {'id': 'ada', 'first_name': 'Ada', 'last_name': 'Obi'},
          'job_title': 'Accountant',
          'status': 'late',
          'record': _record(),
        },
      ],
      _ => fail('Unexpected read $path'),
    };
    return ApiResponse<T>.success(body as T);
  }

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
    writes.add((path, data));
    if (refuse) {
      return ApiResponse<T>.error(
        'refused',
        statusCode: 403,
        failureType: NetworkFailureType.forbidden,
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 403,
          data: {'detail': "You're 1.2 km from Head office."},
        ),
      );
    }
    return ApiResponse<T>.success(_today(record: _record()) as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
