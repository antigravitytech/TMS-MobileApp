import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/core/services/shared_pref_service.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/search/application/search_controller.dart';
import 'package:sabi_pipu_tms/modules/search/data/search_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesService.init();
  });

  group('mock search', () {
    late ProviderContainer c;
    setUp(
      () => c = ProviderContainer.test(
        overrides: [
          networkCallsRepositoryProvider.overrideWith(
            (_) => fail('Mock contacted network'),
          ),
        ],
      ),
    );

    test('matches the reference tasks, projects and people', () async {
      final repo = c.read(searchRepositoryProvider);
      expect(repo, isA<MockSearchRepository>());
      final webhook = await repo.search('webhook');
      expect(webhook.tasks.map((t) => t.task.reference), ['TK-142']);
      expect(webhook.tasks.single.detailKey, 'search.webhook_subtitle');
      expect((await repo.search('tunde')).people.single.name, 'Tunde Bakare');
      expect(
        (await repo.search('at risk')).projects.single.project.name,
        'Mobile App Launch',
      );
      expect((await repo.search('zzz')).isEmpty, isTrue);
      expect(await repo.featured(), hasLength(2));
    });

    test('recent searches start from the reference and are kept', () async {
      expect(c.read(recentSearchesProvider), ['webhook', 'Tunde', 'TK-190']);
      await c.read(recentSearchesProvider.notifier).add('tunde');
      expect(c.read(recentSearchesProvider), ['tunde', 'webhook', 'TK-190']);
      expect(SharedPreferencesService.getStringList(key: RecentSearches.key), [
        'tunde',
        'webhook',
        'TK-190',
      ]);
    });
  });

  group('live search', () {
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
    });

    test('fans out to tasks, projects and people', () async {
      final r = await c.read(searchRepositoryProvider).search(' hook ');
      expect(transport.calls.keys.toSet(), {
        '/task/list-tasks/ws/',
        '/project/list-projects/ws/',
        '/people/list-people/ws/',
      });
      for (final q in transport.calls.values) {
        expect(q, {'search': 'hook', 'page_size': 5});
      }
      expect(r.tasks.single.task.title, 'Fix webhook');
      expect(r.tasks.single.detailKey, isNull);
      expect(r.projects.single.project.name, 'Portal');
      // Pending invites can't be messaged.
      expect(r.people.map((p) => (p.name, p.jobTitle, p.team)), [
        ('Tunde Bakare', 'Engineer', 'Tech Team'),
      ]);
    });

    test('short queries and the empty page send nothing', () async {
      final repo = c.read(searchRepositoryProvider);
      expect((await repo.search('h')).isEmpty, isTrue);
      expect(await repo.featured(), isEmpty);
      expect(transport.calls, isEmpty);
      expect(c.read(recentSearchesProvider), isEmpty);
    });
  });
}

class _Transport implements NetworkCallsRepository {
  final calls = <String, Map<String, dynamic>?>{};

  static final _bodies = <String, Object>{
    '/task/list-tasks/ws/': {
      'items': [
        {
          'id': 't1',
          'reference': 'TK-142',
          'title': 'Fix webhook',
          'status': 'in_progress',
          'priority': 'high',
          'type': 'task',
        },
      ],
    },
    '/project/list-projects/ws/': {
      'items': [
        {'id': 'p1', 'name': 'Portal', 'health': 'at_risk'},
      ],
    },
    '/people/list-people/ws/': {
      'items': [
        {
          'id': 'u1',
          'first_name': 'Tunde',
          'last_name': 'Bakare',
          'job_title': 'Engineer',
          'status': 'active',
          'team': {'name': 'Tech Team'},
        },
        {
          'id': 'i1',
          'first_name': 'New',
          'status': 'pending',
          'is_signup_request': true,
        },
      ],
    },
  };

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
    calls[path] = queryParameters;
    return ApiResponse<T>.success(_bodies[path] as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
