import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/application/account_session.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/modules/files/application/files_controller.dart';
import 'package:sabi_pipu_tms/modules/files/data/files_repository.dart';
import 'package:sabi_pipu_tms/modules/files/domain/file_item.dart';
import 'package:sabi_pipu_tms/modules/home/application/live_home.dart';
import 'package:sabi_pipu_tms/modules/tasks/data/tasks_repository.dart';
import 'package:sabi_pipu_tms/modules/tasks/domain/task.dart';

const _task = TaskItem(
  id: 't1',
  reference: 'TK-142',
  title: 'Webhook',
  status: TaskStatus.inProgress,
  priority: TaskPriority.high,
  type: TaskType.project,
  project: 'Portal',
);

void main() {
  test('file kinds come from the name', () {
    expect(fileKindOf('a.PDF'), FileKind.pdf);
    expect(fileKindOf('b.png'), FileKind.image);
    expect(fileKindOf('c.mp4'), FileKind.video);
    expect(fileKindOf('d.fig'), FileKind.document);
  });

  test('mock files list and upload without the network', () async {
    final c = ProviderContainer.test(
      overrides: [
        networkCallsRepositoryProvider.overrideWith(
          (_) => fail('Mock contacted network'),
        ),
      ],
    );
    expect(c.read(filesRepositoryProvider), isA<MockFilesRepository>());
    final sub = c.listen(filesProvider, (_, _) {});
    addTearDown(sub.close);
    expect((await c.read(filesProvider.future)).length, 7);
    await c.read(filesProvider.notifier).upload([
      (name: 'plan.pdf', path: '/tmp/plan.pdf', size: 2048),
    ], _task);
    final first = c.read(filesProvider).requireValue.first;
    expect(
      (first.name, first.taskTitle, first.kind),
      ('plan.pdf', 'Webhook', FileKind.pdf),
    );
  });

  group('live files', () {
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

    test('one request maps every row', () async {
      final files = await c.read(filesRepositoryProvider).list();
      expect(transport.reads, ['/file/list-files/ws/']);
      final f = files.single;
      expect(
        (f.name, f.kind, f.size, f.uploader, f.taskTitle, f.project),
        (
          'webhook-retry-tests.pdf',
          FileKind.pdf,
          245760,
          'Tunde',
          'Payment webhook retry handler',
          'Customer Portal Revamp',
        ),
      );
    });

    test('upload sends the file with its task', () async {
      final dir = await Directory.systemTemp.createTemp();
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/notes.pdf';
      await File(path).writeAsString('fixture');
      await c.read(filesRepositoryProvider).upload((
        name: 'notes.pdf',
        path: path,
        size: 7,
      ), _task);
      expect(transport.write?.$1, '/file/upload-file/ws/');
      final form = transport.write!.$2 as FormData;
      expect({for (final f in form.fields) f.key: f.value}, {'task_id': 't1'});
      expect(form.files.single.value.filename, 'notes.pdf');
    });

    test('a tapped file loads its task by id', () async {
      final task = await c.read(tasksRepositoryProvider).byId('t1');
      expect(transport.reads.last, '/task/get-task/t1/');
      expect((task.reference, task.status), ('TK-142', TaskStatus.submitted));
    });
  });
}

class _Transport implements NetworkCallsRepository {
  final reads = <String>[];
  (String, Object?)? write;

  static Map<String, dynamic> get _file => {
    'id': 'f1',
    'file_name': 'webhook-retry-tests.pdf',
    'file_size': 245760,
    'kind': 'pdf',
    'download_url': 'https://example.test/d',
    'uploaded_by': {'id': 'tunde', 'first_name': 'Tunde'},
    'task': {'id': 't1', 'title': 'Payment webhook retry handler'},
    'project': {'id': 'p1', 'name': 'Customer Portal Revamp'},
    'created_at': '2026-11-27T08:20:00Z',
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
    reads.add(path);
    final Object body = switch (path) {
      '/file/list-files/ws/' => {
        'items': [_file],
      },
      '/task/get-task/t1/' => {
        'id': 't1',
        'reference': 'TK-142',
        'title': 'Webhook',
        'type': 'project',
        'status': 'submitted',
        'priority': 'high',
      },
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
    write = (path, data);
    return ApiResponse<T>.success(_file as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
