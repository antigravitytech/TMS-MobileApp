import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/data/live_home_repository.dart';
import 'package:sabi_pipu_tms/modules/home/data/live_space_projection.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';

void main() {
  test(
    'Business dashboard loads every documented section with workspace scope',
    () async {
      final transport = _DashboardTransport();
      final repository = LiveHomeRepository(transport);
      final dashboard = await repository.load(_workspace('business'));

      expect(dashboard.name, 'Server workspace');
      expect(dashboard.count('summary', 'unread'), isNull);
      expect(
        transport.paths,
        containsAll([
          '/workspace/get-workspace/fixture/',
          '/people/my-context/fixture/',
          '/task/get-summary/fixture/',
          '/birthday/get-feed/fixture/',
          '/routine/list-my-routines/fixture/',
          '/task/list-approvals/fixture/',
          '/routine/list-summaries/fixture/',
          '/chat/get-unread-summary/fixture/',
        ]),
      );
      expect(
        transport.requests
            .where((request) => request.path == '/task/list-tasks/fixture/')
            .map((request) => request.query?['due']),
        unorderedEquals(['today', 'week']),
      );
      expect(transport.requests.every((request) => request.withToken), isTrue);

      // Nothing on Home lists conversations; the chat badge uses the summary.
      expect(
        transport.paths,
        isNot(contains('/chat/list-conversations/fixture/')),
      );
      await repository.submitReport('routine-id', '2027-01-09', {
        'field': 'Fixture response',
      });
      expect(transport.write?.$1, '/routine/submit-log/routine-id/');
      expect(transport.write?.$2, {
        'occurrence_date': '2027-01-09',
        'answers': {'field': 'Fixture response'},
      });
    },
  );

  test('a failed section leaves the other dashboard data available', () async {
    final transport = _DashboardTransport(
      failedPath: '/birthday/get-feed/fixture/',
    );
    final dashboard = await LiveHomeRepository(
      transport,
    ).load(_workspace('business'));
    expect(dashboard.failed, {'birthdays'});
    expect(dashboard.name, 'Server workspace');
  });

  test(
    'a dashboard authorization failure retains the typed session error',
    () async {
      final transport = _DashboardTransport(
        failedPath: '/task/get-summary/fixture/',
        failure: NetworkFailureType.unauthorized,
      );
      await expectLater(
        LiveHomeRepository(transport).load(_workspace('business')),
        throwsA(
          isA<AccountFailure>().having(
            (failure) => failure.type,
            'type',
            NetworkFailureType.unauthorized,
          ),
        ),
      );
    },
  );

  test(
    'Individual and Family use the space hub, Church and Event use dedicated feeds',
    () async {
      for (final (kind, subtype, path) in [
        ('individual', null, '/home/get-space/fixture/'),
        ('family', null, '/home/get-family/fixture/'),
        ('specials', 'church', '/church/get-church/fixture/'),
        ('specials', 'event', '/event/get-event/fixture/'),
      ]) {
        final transport = _DashboardTransport();
        await LiveHomeRepository(
          transport,
        ).load(_workspace(kind, subtype: subtype));
        expect(transport.paths, contains(path), reason: subtype ?? kind);
        if (subtype != null) {
          expect(transport.paths, isNot(contains('/home/get-space/fixture/')));
        }
      }
    },
  );

  test(
    'space projection keeps user records and converts backend decimal amounts to kobo',
    () {
      final data = LiveHomeData(_workspace('individual'), {
        'space': {
          'modules': [
            {
              'key': 'invoices',
              'items': [
                {
                  'id': 'live-invoice',
                  'title': 'Server invoice',
                  'amount': '153.07',
                  'paid': '20.05',
                },
              ],
            },
          ],
        },
      }, {});
      final workspace = projectLiveWorkspace(data);
      final invoice = workspace.items(WorkspaceSection.invoices).single;
      expect(workspace.records, hasLength(1));
      expect(invoice.id, 'live-invoice');
      expect(invoice.amount, 15307);
      expect(invoice.paid, 2005);
    },
  );
}

AccountWorkspace _workspace(String kind, {String? subtype}) =>
    AccountWorkspace.fromJson({
      'id': 'fixture',
      'name': 'Fixture workspace',
      'kind': kind,
      'subtype': subtype,
      'approval_status': 'approved',
    });

class _DashboardTransport implements NetworkCallsRepository {
  _DashboardTransport({
    this.failedPath,
    this.failure = NetworkFailureType.connection,
  });

  final String? failedPath;
  final NetworkFailureType failure;
  final requests =
      <({String path, Map<String, dynamic>? query, bool withToken})>[];
  (String, Object?, bool)? write;
  Iterable<String> get paths => requests.map((request) => request.path);

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
    requests.add((path: path, query: queryParameters, withToken: withToken));
    if (path == failedPath) {
      return ApiResponse<T>.error(
        'Fixture network error',
        failureType: failure,
      );
    }
    return ApiResponse<T>.success(
      <String, dynamic>{
            if (path == '/workspace/get-workspace/fixture/')
              'name': 'Server workspace',
          }
          as T,
    );
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
    write = (path, data, withToken);
    return ApiResponse<T>.success(<String, dynamic>{} as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
