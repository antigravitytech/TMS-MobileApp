part of 'tasks_repository.dart';

typedef _Json = Map<String, dynamic>;

/// Tasks over the `/task` API for the signed-in workspace.
class LiveTasksRepository implements TasksRepository {
  const LiveTasksRepository(this._network, {this.workspace, this.me});

  final NetworkCallsRepository _network;
  final AccountWorkspace? workspace;
  final Account? me;

  @override
  TaskItem? get opened => null;

  String get _ws {
    final id = workspace?.id;
    if (id == null) throw const AccountFailure(NetworkFailureType.unauthorized);
    return Uri.encodeComponent(id);
  }

  String _task(TaskItem task) => Uri.encodeComponent(task.id);

  Future<_Json> _get(String path, [Map<String, dynamic>? query]) async =>
      accountPayload(await _network.get<_Json>(path, queryParameters: query));

  Future<T> _post<T>(String path, [Object? data]) async =>
      accountPayload(await _network.post<T>(path, data: data));

  @override
  Future<TaskList> list(TaskScope scope) async {
    final ws = _ws;
    final [page, summary] = await Future.wait([
      _get('/task/list-tasks/$ws/', {
        'scope': scope.name,
        'sort_by': 'due',
        'sort_dir': 'asc',
        'page_size': 100,
      }),
      _get('/task/get-summary/$ws/'),
    ]);
    return _parse(() {
      final tabs = summary['tabs'] as _Json;
      return TaskList(
        [for (final t in _items(page)) _item(t, scope)],
        {for (final s in TaskScope.values) s: tabs[s.name] as int? ?? 0},
      );
    });
  }

  @override
  Future<TaskItem> byId(String id) async {
    final body = await _get('/task/get-task/${Uri.encodeComponent(id)}/');
    return _parse(() => _item(body, null));
  }

  @override
  Future<List<TaskActivity>> activity(TaskItem task) async {
    final page = await _get('/task/list-activity/${_task(task)}/', {
      'order': 'newest',
      'page_size': 50,
    });
    return _parse(
      () => [
        for (final a in _items(page))
          TaskActivity(
            _person(a['actor']),
            a['kind'] as String,
            _time(a['created_at']),
            note: a['note'] as String? ?? '',
          ),
      ],
    );
  }

  @override
  Future<List<TaskComment>> comments(TaskItem task) async {
    final page = await _get('/task/list-comments/${_task(task)}/', {
      'order': 'oldest',
      'page_size': 100,
    });
    return _parse(() => [for (final c in _items(page)) _comment(c)]);
  }

  @override
  Future<List<TaskFile>> files(TaskItem task) async {
    final page = await _get('/task/list-attachments/${_task(task)}/', {
      'page_size': 100,
    });
    return _parse(
      () => [
        for (final f in _items(page))
          TaskFile(f['file_name'] as String, f['file_size'] as int? ?? 0),
      ],
    );
  }

  @override
  Future<TaskItem> start(TaskItem task) =>
      _workflow(task, '/task/start-task/${_task(task)}/');

  @override
  Future<TaskItem> submit(TaskItem task, String note) => _workflow(
    task,
    '/task/submit-task/${_task(task)}/',
    {'note': note.trim()},
  );

  @override
  Future<TaskItem> complete(TaskItem task) =>
      _workflow(task, '/task/complete-task/${_task(task)}/');

  Future<TaskItem> _workflow(TaskItem task, String path, [Object? data]) async {
    final body = await _post<_Json>(path, data);
    return _parse(() => _item(body, null, scopes: task.scopes));
  }

  @override
  Future<TaskComment> comment(TaskItem task, String body) async {
    final saved = await _post<_Json>('/task/add-comment/${_task(task)}/', {
      'kind': 'general',
      'body': body.trim(),
    });
    return _parse(() => _comment(saved));
  }

  @override
  Future<ReviewQueue> approvals() async {
    final ws = _ws;
    final [page, summary] = await Future.wait([
      _get('/task/list-approvals/$ws/', {'sort': 'oldest', 'page_size': 100}),
      _get('/task/get-summary/$ws/'),
    ]);
    return _parse(() {
      final review = summary['review'] as _Json;
      return ReviewQueue(
        tasks: [for (final t in _items(page)) _item(t, null)],
        avgHours: (review['avg_review_hours'] as num? ?? 0).toDouble(),
        approved: review['approved_this_week'] as int? ?? 0,
        returned: review['returned_this_week'] as int? ?? 0,
      );
    });
  }

  @override
  Future<String> submissionNote(TaskItem task) async {
    final detail = await _get('/task/get-task/${_task(task)}/');
    return _parse(() => detail['latest_submission_note'] as String? ?? '');
  }

  @override
  Future<void> approve(TaskItem task) =>
      _post<_Json>('/task/approve-task/${_task(task)}/', {'comment': ''});

  @override
  Future<void> returnTask(TaskItem task, String note) =>
      _post<_Json>('/task/return-task/${_task(task)}/', {'note': note.trim()});

  @override
  Future<TaskOptions> options() async {
    final ws = _ws;
    final [members, projects, teams] = await Future.wait([
      _get('/workspace/list-members/$ws/', {
        'status': 'active',
        'page_size': 100,
      }),
      _get('/project/list-projects/$ws/', {'page_size': 100}),
      _get('/team/list-teams/$ws/', {'page_size': 100}),
    ]);
    final self = TaskPerson(
      me?.id ?? '',
      '${me?.firstName ?? ''} ${me?.lastName ?? ''}'.trim(),
    );
    return _parse(
      () => TaskOptions(
        me: self,
        people: [
          for (final m in _items(members))
            if (_person(m['user']) case final p? when p.id != self.id) p,
        ],
        projects: [
          for (final p in _items(projects))
            (p['id'] as String, p['name'] as String),
        ],
        teams: [
          for (final t in _items(teams))
            (t['id'] as String, t['name'] as String),
        ],
      ),
    );
  }

  @override
  Future<TaskItem> create(TaskDraft draft) async {
    final due = DateFormat('yyyy-MM-dd').format(draft.due);
    final created = await _post<List<dynamic>>('/task/create-task/$_ws/', {
      'title': draft.title.trim(),
      if (draft.description.trim().isNotEmpty)
        'description': draft.description.trim(),
      'type': draft.type.code,
      'assignee_ids': [draft.assignee.id],
      'priority': draft.priority.code,
      'visibility': draft.confidential ? 'confidential' : 'public',
      'due_date': due,
      if (draft.type == TaskType.project) 'project_id': draft.projectId,
      if (draft.type == TaskType.team) 'team_id': draft.teamId,
      // The prototype's recurring option is "every weekday by 5:00 pm".
      if (draft.type == TaskType.recurring) ...{
        'repeat_frequency': 'weekdays',
        'due_time': '17:00',
      },
    });
    return _parse(
      () => _item(
        created.cast<_Json>().first,
        null,
        scopes: {
          TaskScope.all,
          draft.assignee.id == me?.id ? TaskScope.mine : TaskScope.requests,
        },
      ),
    );
  }

  // ----- Mapping -----

  static List<_Json> _items(_Json page) =>
      (page['items'] as List).cast<_Json>();

  static TaskPerson? _person(Object? json) {
    if (json is! _Json) return null;
    return TaskPerson(
      json['id'] as String,
      [
        json['first_name'],
        json['last_name'],
      ].whereType<String>().join(' ').trim(),
    );
  }

  static DateTime _time(Object? value) =>
      DateTime.parse(value as String).toLocal();

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  TaskComment _comment(_Json c) {
    final author = _person(c['author']) ?? const TaskPerson('', '');
    return TaskComment(
      author,
      c['body'] as String? ?? '',
      _time(c['created_at']),
      mine: author.id == me?.id,
    );
  }

  TaskItem _item(_Json t, TaskScope? scope, {Set<TaskScope>? scopes}) =>
      taskItemFromJson(t, scopes: scopes ?? {TaskScope.all, ?scope});

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

/// A `TaskRead` from the API, for screens that already hold task JSON.
TaskItem taskItemFromJson(
  Map<String, dynamic> t, {
  Set<TaskScope> scopes = const {TaskScope.all},
}) {
  final permissions = t['permissions'] as _Json? ?? const {};
  final project =
      (t['project'] as _Json?)?['name'] ?? (t['team'] as _Json?)?['name'];
  return TaskItem(
    id: t['id'] as String,
    reference: t['reference'] as String? ?? '',
    title: t['title'] as String,
    description: t['description'] as String? ?? '',
    status: TaskStatus.parse(t['status'] as String),
    priority: TaskPriority.parse(t['priority'] as String),
    type: TaskType.parse(t['type'] as String),
    project: project is String ? project : '',
    confidential: t['visibility'] == 'confidential',
    assignee: LiveTasksRepository._person(t['assignee']),
    assigner: LiveTasksRepository._person(t['assigner']),
    due: LiveTasksRepository._date(t['due_date']),
    originalDue: LiveTasksRepository._date(t['original_due_date']),
    completedAt: LiveTasksRepository._date(t['completed_at'])?.toLocal(),
    createdAt: LiveTasksRepository._date(t['created_at'])?.toLocal(),
    submittedAt: LiveTasksRepository._date(t['submitted_at'])?.toLocal(),
    round: t['submission_round'] as int? ?? 0,
    fileCount: t['attachment_count'] as int? ?? 0,
    scopes: scopes,
    permissions: TaskPermissions(
      canStart: permissions['can_start'] == true,
      canSubmit: permissions['can_submit'] == true,
      canComplete: permissions['can_complete'] == true,
      canComment: permissions['can_comment'] != false,
    ),
  );
}
