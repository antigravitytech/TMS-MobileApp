import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/workspace_repository.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';

void main() {
  final now = DateTime(2026, 11, 27);
  final empty = WorkspaceDirectory(
    activeId: 'company',
    workspaces: [
      for (final kind in WorkspaceKind.values.skip(1))
        LocalWorkspace(id: kind.name, kind: kind),
    ],
  );

  test('mock data leaves no section of any role empty', () {
    final filled = const MockWorkspaceRepository().prepare(empty, now);
    for (final space in filled.workspaces) {
      expect(space.name, isNotEmpty, reason: space.kind.name);
      for (final section in space.kind.sections) {
        expect(
          space.items(section),
          isNotEmpty,
          reason: '${space.kind.name} · ${section.name}',
        );
      }
    }
  });

  test('a created workspace gets content but keeps its name and members', () {
    const member = WorkspaceRecord(
      id: 'record-1',
      section: WorkspaceSection.household,
      title: 'Ada',
    );
    final created = const MockWorkspaceRepository().fill(
      const LocalWorkspace(
        id: 'workspace-9',
        kind: WorkspaceKind.family,
        name: 'The Obis',
        records: [member],
      ),
      now,
    );
    expect(created.name, 'The Obis');
    expect(created.items(WorkspaceSection.household).single.title, 'Ada');
    expect(created.items(WorkspaceSection.chores), isNotEmpty);
  });

  test('live data is left as saved', () {
    expect(
      identical(const LiveWorkspaceRepository().prepare(empty, now), empty),
      isTrue,
    );
  });
}
