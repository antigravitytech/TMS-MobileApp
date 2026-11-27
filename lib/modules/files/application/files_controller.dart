import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../../tasks/domain/task.dart';
import '../data/files_repository.dart';
import '../domain/file_item.dart';

/// The file library. An upload joins the list without reloading it.
final filesProvider =
    AsyncNotifierProvider.autoDispose<FilesController, List<FileItem>>(
      FilesController.new,
      retry: (_, _) => null,
    );

class FilesController extends AsyncNotifier<List<FileItem>> {
  @override
  Future<List<FileItem>> build() =>
      guardSession(ref, () => ref.watch(filesRepositoryProvider).list());

  Future<void> upload(List<PickedFile> files, TaskItem task) async {
    final added = <FileItem>[];
    for (final file in files) {
      added.add(
        await guardSession(
          ref,
          () => ref.read(filesRepositoryProvider).upload(file, task),
        ),
      );
    }
    if (ref.mounted) state = AsyncData([...added, ...?state.value]);
  }
}
