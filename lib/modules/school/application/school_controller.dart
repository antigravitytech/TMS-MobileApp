import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../data/school_items.dart';

final schoolControllerProvider = ChangeNotifierProvider.autoDispose
    .family<SchoolController, String>(
      (ref, id) => SchoolController(
        id,
        ref.read(localWorkspacesProvider.notifier),
        ref.read(localWorkspacesProvider).requireValue.active!,
        () => ref.read(localWorkspacesProvider).requireValue.active!,
      ),
    );

class SchoolController extends ChangeNotifier {
  SchoolController(
    this.workspaceId,
    this.directory,
    LocalWorkspace space,
    this.current,
  ) {
    items = [
      ...schoolExamples.map(
        (r) =>
            space.records.any(
              (p) =>
                  p.fields['schoolId'] == r.id &&
                  p.status == WorkspaceStatus.done,
            )
            ? r.toggle()
            : r,
      ),
    ];
    final review = space.records
        .where((r) => r.id.endsWith('fractions'))
        .firstOrNull;
    checked = review != null && review.status != WorkspaceStatus.submitted;
    for (final record in space.records.where(
      (r) => r.fields['schoolAdded'] == 'true',
    )) {
      items.add(
        SchoolItem(
          record.id,
          record.group,
          record.title,
          record.person,
          'school.nov27',
          'wk',
          done: record.status == WorkspaceStatus.done,
        ),
      );
    }
  }
  final LocalWorkspace Function() current;
  final String workspaceId;
  final LocalWorkspaces directory;
  late List<SchoolItem> items;
  String child = '';
  bool checked = false, busy = false;
  bool disposed = false;
  List<SchoolItem> get visible => items
      .where((r) => child.isEmpty || r.child.isEmpty || r.child == child)
      .toList();
  void select(String value) {
    child = value;
    notifyListeners();
  }

  Future<bool> toggle(SchoolItem item) async {
    if (busy) return false;
    busy = true;
    try {
      final space = current();
      final saved = space.records
          .where((r) => r.fields['schoolId'] == item.id || r.id == item.id)
          .firstOrNull;
      await directory.saveRecord(
        workspaceId,
        WorkspaceRecord(
          id: saved?.id ?? '',
          section: WorkspaceSection.school,
          title: item.title,
          points: saved?.points ?? 0,
          person: item.child,
          status: item.done ? WorkspaceStatus.todo : WorkspaceStatus.done,
          fields: {...?(saved?.fields), 'schoolId': item.id},
        ),
      );
      items = items.map((r) => r.id == item.id ? r.toggle() : r).toList();
      return true;
    } catch (_) {
      return false;
    } finally {
      busy = false;
      if (!disposed) notifyListeners();
    }
  }

  Future<bool> review(bool approve) async {
    try {
      final space = current();
      final record = space.records
          .where((r) => r.id.endsWith('fractions'))
          .firstOrNull;
      if (record != null) {
        await directory.updateRecord(
          workspaceId,
          record.id,
          (r) => r.copyWith(
            status: approve ? WorkspaceStatus.done : WorkspaceStatus.returned,
          ),
        );
      }
      if (approve && !checked) {
        await directory.saveRecord(
          workspaceId,
          const WorkspaceRecord(
            id: '',
            section: WorkspaceSection.school,
            title: 'Fractions worksheet checked',
            person: 'Tobi',
            status: WorkspaceStatus.done,
            points: 15,
            fields: {'schoolAward': 'fractions'},
          ),
        );
      }
      checked = true;
      if (!disposed) notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> add(String type, String title) async {
    final name = title.trim().isEmpty
        ? 'Science project — volcano model'
        : title.trim();
    final person = child.isEmpty ? 'Tobi' : child;
    try {
      await directory.saveRecord(
        workspaceId,
        WorkspaceRecord(
          id: '',
          section: WorkspaceSection.school,
          title: name,
          points: 0,
          person: person,
          group: type,
          fields: {'schoolAdded': 'true'},
        ),
      );
      items = [
        SchoolItem(
          current().records.last.id,
          type,
          name,
          person,
          'school.nov27',
          'wk',
        ),
        ...items,
      ];
      if (!disposed) notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
