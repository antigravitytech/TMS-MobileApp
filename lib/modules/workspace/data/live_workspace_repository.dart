part of 'workspace_repository.dart';

/// Live builds keep exactly what the person saved.
class LiveWorkspaceRepository implements WorkspaceRepository {
  const LiveWorkspaceRepository();

  @override
  WorkspaceDirectory prepare(WorkspaceDirectory directory, DateTime now) =>
      directory;

  @override
  LocalWorkspace fill(LocalWorkspace created, DateTime now) => created;
}
