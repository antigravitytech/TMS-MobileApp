import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/birthdays/domain/birthday.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/tasks/application/tasks_controller.dart';
import 'package:sabi_pipu_tms/modules/tasks/data/tasks_repository.dart';
import 'package:sabi_pipu_tms/modules/tasks/domain/task.dart';

void main() {
  test('Home decisions and cards use the shared repositories', () async {
    final transport = _Transport();
    final workspace = AccountWorkspace.fromJson({
      'id': 'ws',
      'name': 'Fixture',
      'kind': 'business',
      'approval_status': 'approved',
    });
    final c = ProviderContainer.test(
      overrides: [
        environmentProvider.overrideWithValue(
          const AppEnvironment(source: DataSource.live),
        ),
        networkCallsRepositoryProvider.overrideWithValue(transport),
        activeLiveWorkspaceProvider.overrideWithValue(workspace),
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
    final sub = c.listen(liveHomeActionsProvider(workspace), (_, _) {});
    addTearDown(sub.close);
    final actions = c.read(liveHomeActionsProvider(workspace).notifier);

    // A dashboard row is a TaskRead, so it opens without a request.
    final task = taskItemFromJson({
      'id': 't1',
      'reference': 'TK-1',
      'title': 'Review me',
      'type': 'standalone',
      'status': 'submitted',
      'priority': 'high',
      'assignee': {'id': 'tunde', 'first_name': 'Tunde', 'last_name': 'B'},
    });
    expect((task.reference, task.status), ('TK-1', TaskStatus.submitted));
    c.read(openedTaskProvider.notifier).open(task);
    expect(transport.writes, isEmpty);

    expect(await actions.approve(task), isTrue);
    expect(transport.writes.last.$1, '/task/approve-task/t1/');
    expect(await actions.returnTask(task, 'Add tests'), isTrue);
    expect(transport.writes.last.$1, '/task/return-task/t1/');
    expect(transport.writes.last.$2, {'note': 'Add tests'});

    const person = BirthdayPerson(
      id: 'chioma',
      name: 'Chioma Okafor',
      jobTitle: '',
      day: '11-27',
      daysAway: 0,
    );
    expect(await actions.wish(person), isTrue);
    expect(transport.writes.last.$1, '/birthday/send-wish/chioma/');
    expect(transport.writes.last.$2, {
      'message': '',
      'theme': 'confetti',
      'sticker': 'cake',
    });
  });
}

class _Transport implements NetworkCallsRepository {
  final writes = <(String, Object?)>[];

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
    return ApiResponse<T>.success(<String, dynamic>{'id': 'ok'} as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
