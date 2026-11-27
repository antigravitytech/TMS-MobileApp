part of 'workspace_repository.dart';

/// Mock builds fill every workspace without content with its role's
/// prototype data, so no screen opens on an empty state.
class MockWorkspaceRepository implements WorkspaceRepository {
  const MockWorkspaceRepository();

  @override
  WorkspaceDirectory prepare(WorkspaceDirectory directory, DateTime now) {
    var changed = false;
    final workspaces = [
      for (final space in directory.workspaces)
        if (_needsContent(space))
          () {
            changed = true;
            return fill(space, now);
          }()
        else
          space,
    ];
    return changed ? directory.copyWith(workspaces: workspaces) : directory;
  }

  @override
  LocalWorkspace fill(LocalWorkspace created, DateTime now) {
    if (!_needsContent(created)) return created;
    final demo = created.kind == WorkspaceKind.family
        ? familyReference()
        : demoWorkspace(created.kind, now);
    // Household members someone added during setup replace the sample ones.
    final members = created.items(WorkspaceSection.household).toList();
    return created.copyWith(
      name: created.name.isEmpty ? demo.name : created.name,
      records: [
        ...members,
        ...demo.records.where(
          (r) => members.isEmpty || r.section != WorkspaceSection.household,
        ),
      ],
      eventDate: created.eventDate ?? demo.eventDate,
      eventVenue: created.eventVenue.isEmpty
          ? demo.eventVenue
          : created.eventVenue,
      eventCapacity: created.eventCapacity == 0
          ? demo.eventCapacity
          : created.eventCapacity,
      eventBudget: created.eventBudget == 0
          ? demo.eventBudget
          : created.eventBudget,
    );
  }

  /// A workspace with nothing but its household members.
  static bool _needsContent(LocalWorkspace space) =>
      space.kind != WorkspaceKind.business &&
      space.records.every((r) => r.section == WorkspaceSection.household);
}
