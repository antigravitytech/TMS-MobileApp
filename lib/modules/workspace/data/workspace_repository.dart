import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import '../../family/data/family_reference.dart';
import 'workspace_demo.dart';

part 'live_workspace_repository.dart';
part 'mock_workspace_repository.dart';

/// Where workspace content starts from: the prototype's data in mock
/// builds, the person's own records in live builds.
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) {
    return const MockWorkspaceRepository();
  }
  return const LiveWorkspaceRepository();
});

abstract class WorkspaceRepository {
  /// Fills what a loaded directory is missing. Returns [directory] itself
  /// when nothing changed.
  WorkspaceDirectory prepare(WorkspaceDirectory directory, DateTime now);

  /// Fills a workspace that was just created.
  LocalWorkspace fill(LocalWorkspace created, DateTime now);
}
