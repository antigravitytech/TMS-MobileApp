import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../specials/application/special_actions.dart';

export '../../specials/presentation/widgets/special_records.dart'
    show SpecialPollVotes;
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

enum AlumniTab { overview, dues, committees, poll, notices, directory }

/// Classmate activity, in order.
const alumniActivity = ['active', 'occasional', 'inactive'];

extension AlumniRecord on WorkspaceRecord {
  bool get isClass => fields['meta'] == 'true';
  int get activity => int.tryParse(fields['activity'] ?? '') ?? 0;
  List<String> get members => [
    for (final m in (fields['members'] ?? '').split('\n'))
      if (m.trim().isNotEmpty) m.trim(),
  ];
}

/// Everything the Alumni home shows, derived from the workspace records.
class AlumniView {
  AlumniView(this.space, DateTime now)
    : today = DateTime(now.year, now.month, now.day),
      dues = space.items(WorkspaceSection.dues).toList(),
      committees = space.items(WorkspaceSection.committees).toList(),
      polls = space.items(WorkspaceSection.poll).toList(),
      notices = space.items(WorkspaceSection.notices).toList()
        ..sort((a, b) => (b.date ?? now).compareTo(a.date ?? now)),
      classmates = space
          .items(WorkspaceSection.directory)
          .where((r) => !r.isClass)
          .toList(),
      info = space
          .items(WorkspaceSection.directory)
          .where((r) => r.isClass)
          .firstOrNull;
  final LocalWorkspace space;
  final DateTime today;
  final List<WorkspaceRecord> dues, committees, polls, notices, classmates;

  /// The class record: size, reunion date and dues target.
  final WorkspaceRecord? info;

  int get size => int.tryParse(info?.fields['size'] ?? '') ?? classmates.length;
  int get collected => dues.fold(0, (s, d) => s + d.paid.clamp(0, d.amount));
  int get pledged => dues.fold(0, (s, d) => s + d.amount);
  int get target => (info?.amount ?? 0) > 0 ? info!.amount : pledged;
  List<WorkspaceRecord> get owing =>
      dues.where((d) => d.outstanding > 0).toList();
  int get outstanding => owing.fold(0, (s, d) => s + d.outstanding);
  int get openTodos => committees.fold(
    0,
    (s, c) => s + c.todos.values.where((done) => !done).length,
  );
  WorkspaceRecord? get poll => polls.lastOrNull;
  int get active => classmates.where((c) => c.activity == 0).length;
}

final alumniViewProvider = Provider.autoDispose.family<AlumniView?, String>((
  ref,
  id,
) {
  final space = ref
      .watch(localWorkspacesProvider)
      .value
      ?.workspaces
      .where((w) => w.id == id)
      .firstOrNull;
  return space == null ? null : AlumniView(space, DateTime.now());
});

final alumniControllerProvider = NotifierProvider.autoDispose
    .family<AlumniController, AlumniTab, (String, AlumniTab)>(
      AlumniController.new,
    );

/// Holds the open tab and changes Alumni records through [SpecialActions].
class AlumniController extends Notifier<AlumniTab> {
  AlumniController(this.args);

  /// Workspace id and the tab the screen opened on.
  final (String, AlumniTab) args;

  @override
  AlumniTab build() => args.$2;

  SpecialActions get _actions => ref.read(specialActionsProvider(args.$1));

  void tab(AlumniTab value) => state = value;

  Future<bool> toggleTodo(WorkspaceRecord committee, String todo) =>
      _actions.update(
        committee,
        (r) => r.copyWith(todos: {...r.todos, todo: !(r.todos[todo] ?? false)}),
      );

  Future<bool> takeLead(WorkspaceRecord committee, String me) =>
      _actions.update(committee, (r) => r.copyWith(person: me));

  Future<bool> setActivity(WorkspaceRecord classmate, int activity) =>
      _actions.update(
        classmate,
        (r) => r.copyWith(fields: {...r.fields, 'activity': '$activity'}),
      );
}
