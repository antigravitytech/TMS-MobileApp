part of 'tasks_repository.dart';

/// The prototype's tasks from [WorkspacePreview], which Home, Approvals and
/// chat also read, adapted to [TaskItem]. Changes are written back there.
class MockTasksRepository implements TasksRepository {
  MockTasksRepository(this._preview);

  final WorkspacePreview _preview;

  static const _assigner = TaskPerson('mock-im', 'Ibrahim Musa');
  static const _people = [
    'Tunde Bakare',
    'Amaka Eze',
    'Sarah Johnson',
    'David Mensah',
    'Ngozi Adeyemi',
  ];
  static const _projects = [
    ('mock-cp', 'Customer Portal Revamp'),
    ('mock-ma', 'Mobile App Launch'),
  ];
  static const _teams = [('mock-tt', 'Tech Team')];

  static const _status = {
    'Not started': TaskStatus.notStarted,
    'In progress': TaskStatus.inProgress,
    'Submitted': TaskStatus.submitted,
    'Returned': TaskStatus.returned,
    'Completed': TaskStatus.completed,
  };
  static const _priority = {
    'Low': TaskPriority.low,
    'Medium': TaskPriority.medium,
    'High': TaskPriority.high,
    'Urgent': TaskPriority.critical,
  };

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  TaskPerson get _me =>
      TaskPerson('mock-me', '${_preview.firstName} ${_preview.lastName}');

  /// The prototype's due labels ("Today", "2 days overdue", "Wed, 25 Nov").
  DateTime? _due(String label) {
    if (label == 'Today') return _today;
    if (label == 'Tomorrow') return _today.add(const Duration(days: 1));
    final overdue = RegExp(r'^(\d+) days? overdue$').firstMatch(label);
    if (overdue != null) {
      return _today.subtract(Duration(days: int.parse(overdue[1]!)));
    }
    final date = RegExp(r'^\w{3}, (\d{1,2}) (\w{3})$').firstMatch(label);
    final month = _months.indexOf(date?[2] ?? '') + 1;
    if (date == null || month == 0) return null;
    return DateTime(_today.year, month, int.parse(date[1]!));
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _label(DateTime due) {
    final days = DateTime(due.year, due.month, due.day).difference(_today);
    if (days.inDays == 0) return 'Today';
    if (days.inDays == 1) return 'Tomorrow';
    return '${_weekdays[due.weekday - 1]}, ${due.day} ${_months[due.month - 1]}';
  }

  TaskItem _item(PreviewTask t) {
    final status = _status[t.status] ?? TaskStatus.notStarted;
    final mine = t.group == 'Mine';
    final type = switch (t.project) {
      'Standalone' => TaskType.standalone,
      'Tech Team' => TaskType.team,
      'Recurring' => TaskType.recurring,
      _ => TaskType.project,
    };
    return TaskItem(
      id: t.id,
      reference: t.id,
      title: t.title,
      description: t.note,
      status: status,
      priority: _priority[t.priority] ?? TaskPriority.medium,
      type: type,
      project: type == TaskType.standalone ? '' : t.project,
      assignee: mine || t.person == 'Me'
          ? _me
          : TaskPerson('mock-${t.person}', t.person),
      assigner: mine ? _assigner : _me,
      due: _due(t.due),
      originalDue: _due(t.due),
      createdAt: _today.subtract(const Duration(days: 2)),
      submittedAt: status == TaskStatus.submitted ? DateTime.now() : null,
      // The prototype's webhook handler is on its second round.
      round: status == TaskStatus.submitted ? (t.id == 'TK-142' ? 2 : 1) : 0,
      fileCount: status == TaskStatus.submitted ? 2 : 0,
      scopes: {
        TaskScope.all,
        switch (t.group) {
          'Mine' => TaskScope.mine,
          'Team' => TaskScope.team,
          _ => TaskScope.requests,
        },
      },
      permissions: TaskPermissions(
        canSubmit: !const {
          TaskStatus.submitted,
          TaskStatus.completed,
        }.contains(status),
      ),
    );
  }

  PreviewTask? _find(TaskItem task) =>
      _preview.tasks.where((t) => t.id == task.id).firstOrNull;

  @override
  TaskItem? get opened => _item(_preview.activeTask);

  @override
  Future<TaskItem> byId(String id) async => _item(
    _preview.tasks.firstWhere(
      (t) => t.id == id,
      orElse: () => _preview.tasks.first,
    ),
  );

  @override
  Future<TaskList> list(TaskScope scope) async {
    final all = _preview.tasks.map(_item).toList();
    return TaskList(
      [
        for (final t in all)
          if (t.scopes.contains(scope)) t,
      ],
      {
        for (final s in TaskScope.values)
          s: all.where((t) => t.scopes.contains(s)).length,
      },
    );
  }

  @override
  Future<List<TaskActivity>> activity(TaskItem task) async {
    final created = task.createdAt ?? _today;
    return [
      if (task.status == TaskStatus.submitted)
        TaskActivity(_me, 'submitted', DateTime.now()),
      if (task.status != TaskStatus.notStarted)
        TaskActivity(
          task.assignee,
          'started',
          created.add(const Duration(days: 1, hours: 10)),
        ),
      TaskActivity(
        task.assigner ?? _assigner,
        'created',
        created.add(const Duration(hours: 9)),
      ),
    ];
  }

  @override
  Future<List<TaskComment>> comments(TaskItem task) async => [
    TaskComment(
      task.assigner ?? _assigner,
      'Keep the QA role contract-to-hire if the budget is tight.',
      DateTime.now().subtract(const Duration(days: 2)),
    ),
    for (final line in _preview.comments[task.id] ?? const <String>[])
      TaskComment(_me, line, DateTime.now(), mine: true),
  ];

  @override
  Future<List<TaskFile>> files(TaskItem task) async => const [
    TaskFile('q4-hiring-plan.pdf', 310 * 1024),
  ];

  TaskItem _set(TaskItem task, TaskStatus status, String label) {
    if (_find(task) case final found?) _preview.updateTask(found, label);
    return task.copyWith(
      status: status,
      round: status == TaskStatus.submitted ? task.round + 1 : null,
    );
  }

  @override
  Future<TaskItem> start(TaskItem task) async =>
      _set(task, TaskStatus.inProgress, 'In progress');

  @override
  Future<TaskItem> submit(TaskItem task, String note) async =>
      _set(task, TaskStatus.submitted, 'Submitted');

  @override
  Future<TaskItem> complete(TaskItem task) async =>
      _set(task, TaskStatus.completed, 'Completed');

  @override
  Future<TaskComment> comment(TaskItem task, String body) async {
    _preview.addComment(task.id, body.trim());
    return TaskComment(_me, body.trim(), DateTime.now(), mine: true);
  }

  @override
  Future<ReviewQueue> approvals() async => ReviewQueue(
    tasks: _preview.reviewQueue.map(_item).toList(),
    avgHours: 5.3,
    approved: 2 + _preview.approved.length,
    returned: 5 + _preview.returned.length,
  );

  @override
  Future<String> submissionNote(TaskItem task) async => task.description;

  @override
  Future<void> approve(TaskItem task) async {
    if (_find(task) case final found?) _preview.review(found, approve: true);
  }

  @override
  Future<void> returnTask(TaskItem task, String note) async {
    if (_find(task) case final found?) _preview.review(found, approve: false);
  }

  @override
  Future<TaskOptions> options() async => TaskOptions(
    me: _me,
    people: [for (final name in _people) TaskPerson('mock-$name', name)],
    projects: _projects,
    teams: _teams,
  );

  @override
  Future<TaskItem> create(TaskDraft draft) async {
    final project = switch (draft.type) {
      TaskType.project =>
        _projects.where((p) => p.$1 == draft.projectId).firstOrNull?.$2 ??
            _projects.first.$2,
      TaskType.team => _teams.first.$2,
      TaskType.recurring => 'Recurring',
      TaskType.standalone => 'Standalone',
    };
    _preview.addTask(
      draft.title,
      draft.description,
      draft.assignee.id == _me.id ? 'Me' : draft.assignee.firstName,
      _label(draft.due),
      _priority.entries.firstWhere((e) => e.value == draft.priority).key,
      project,
    );
    return _item(_preview.activeTask);
  }
}
