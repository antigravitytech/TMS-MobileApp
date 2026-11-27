part of 'files_repository.dart';

typedef _Json = Map<String, dynamic>;

/// The file library over `/file`.
class LiveFilesRepository implements FilesRepository {
  const LiveFilesRepository(this._network, {this.workspace});

  final NetworkCallsRepository _network;
  final AccountWorkspace? workspace;

  String get _ws {
    final id = workspace?.id;
    if (id == null) throw const AccountFailure(NetworkFailureType.unauthorized);
    return Uri.encodeComponent(id);
  }

  @override
  Future<List<FileItem>> list() async {
    final page = accountPayload(
      await _network.get<_Json>(
        '/file/list-files/$_ws/',
        queryParameters: {'page_size': 100},
      ),
    );
    return _parse(
      () => [for (final f in (page['items'] as List).cast<_Json>()) _item(f)],
    );
  }

  @override
  Future<FileItem> upload(PickedFile file, TaskItem task) async {
    final body = accountPayload(
      await _network.post<_Json>(
        '/file/upload-file/$_ws/',
        data: FormData.fromMap({
          'task_id': task.id,
          'file': await MultipartFile.fromFile(file.path, filename: file.name),
        }),
      ),
    );
    return _parse(() => _item(body));
  }

  static FileItem _item(_Json f) {
    final user = f['uploaded_by'] as _Json?;
    final task = f['task'] as _Json? ?? const {};
    return FileItem(
      id: f['id'] as String,
      name: f['file_name'] as String,
      kind: FileKind.values.firstWhere(
        (k) => k.name == f['kind'],
        orElse: () => fileKindOf(f['file_name'] as String),
      ),
      size: f['file_size'] as int? ?? 0,
      uploader: user?['first_name'] as String? ?? '',
      taskId: task['id'] as String? ?? '',
      taskTitle: task['title'] as String? ?? '',
      project:
          (f['project'] as _Json?)?['name'] as String? ??
          (f['team'] as _Json?)?['name'] as String? ??
          '',
      createdAt: DateTime.parse(f['created_at'] as String).toLocal(),
      url: f['download_url'] as String? ?? '',
    );
  }

  static T _parse<T>(T Function() read) {
    try {
      return read();
    } on TypeError {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    } on FormatException {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
  }
}
