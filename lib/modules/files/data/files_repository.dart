import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';
import '../../tasks/domain/task.dart';
import '../domain/file_item.dart';

part 'live_files_repository.dart';
part 'mock_files_repository.dart';

final filesRepositoryProvider = Provider<FilesRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) {
    final account = ref.read(accountSessionProvider);
    return MockFilesRepository(account?.firstName ?? 'Chioma');
  }
  return LiveFilesRepository(
    ref.watch(networkCallsRepositoryProvider),
    workspace: ref.watch(activeLiveWorkspaceProvider),
  );
});

abstract class FilesRepository {
  /// Files on tasks the user can see, newest first.
  Future<List<FileItem>> list();

  /// Attaches [file] to [task].
  Future<FileItem> upload(PickedFile file, TaskItem task);
}

/// The kind a file name suggests.
FileKind fileKindOf(String name) {
  final ext = name.split('.').last.toLowerCase();
  if (const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext)) {
    return FileKind.image;
  }
  if (ext == 'pdf') return FileKind.pdf;
  if (const ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
    return FileKind.video;
  }
  return FileKind.document;
}
