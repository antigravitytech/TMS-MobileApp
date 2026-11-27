/// Task workflow states, in order, with their API codes.
enum TaskStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  submitted('submitted'),
  returned('returned'),
  completed('completed');

  const TaskStatus(this.code);
  final String code;
  static TaskStatus parse(String code) =>
      values.firstWhere((s) => s.code == code, orElse: () => notStarted);
}

/// Lowest to highest; the API calls the top one `critical`.
enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const TaskPriority(this.code);
  final String code;
  static TaskPriority parse(String code) =>
      values.firstWhere((p) => p.code == code, orElse: () => medium);
}

enum TaskType {
  standalone('standalone'),
  project('project'),
  team('team'),
  recurring('recurring');

  const TaskType(this.code);
  final String code;
  static TaskType parse(String code) =>
      values.firstWhere((t) => t.code == code, orElse: () => standalone);
}

/// The list tabs: tasks assigned to me, ones I asked for, my teams', all.
enum TaskScope { mine, requests, team, all }

class TaskPerson {
  const TaskPerson(this.id, this.name);
  final String id, name;
  String get firstName => name.split(' ').first;
}

/// What the signed-in user may do to a task right now.
class TaskPermissions {
  const TaskPermissions({
    this.canStart = false,
    this.canSubmit = false,
    this.canComplete = false,
    this.canComment = true,
  });
  final bool canStart, canSubmit, canComplete, canComment;
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.reference,
    required this.title,
    required this.status,
    required this.priority,
    required this.type,
    this.description = '',
    this.project = '',
    this.confidential = false,
    this.assignee,
    this.assigner,
    this.due,
    this.originalDue,
    this.completedAt,
    this.createdAt,
    this.submittedAt,
    this.round = 0,
    this.fileCount = 0,
    this.scopes = const {TaskScope.all},
    this.permissions = const TaskPermissions(),
  });

  final String id;

  /// The workspace's short code, like `TK-142`.
  final String reference;
  final String title, description;
  final TaskStatus status;
  final TaskPriority priority;
  final TaskType type;

  /// The project or team the task belongs to; empty when standalone.
  final String project;
  final bool confidential;
  final TaskPerson? assignee, assigner;
  final DateTime? due, originalDue, completedAt, createdAt, submittedAt;

  /// How many times it has been submitted, and how many files it has.
  final int round, fileCount;

  /// Which list tabs show it.
  final Set<TaskScope> scopes;
  final TaskPermissions permissions;

  bool get done => status == TaskStatus.completed;

  /// Whole days past due, or 0.
  int overdueDays(DateTime today) {
    final due = this.due;
    if (due == null || done) return 0;
    final days = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime(due.year, due.month, due.day)).inDays;
    return days > 0 ? days : 0;
  }

  TaskItem copyWith({TaskStatus? status, int? round}) => TaskItem(
    id: id,
    reference: reference,
    title: title,
    status: status ?? this.status,
    priority: priority,
    type: type,
    description: description,
    project: project,
    confidential: confidential,
    assignee: assignee,
    assigner: assigner,
    due: due,
    originalDue: originalDue,
    completedAt: status == TaskStatus.completed ? DateTime.now() : completedAt,
    createdAt: createdAt,
    submittedAt: status == TaskStatus.submitted ? DateTime.now() : submittedAt,
    round: round ?? this.round,
    fileCount: fileCount,
    scopes: scopes,
    permissions: TaskPermissions(
      canStart: (status ?? this.status) == TaskStatus.notStarted,
      canSubmit: const {
        TaskStatus.inProgress,
        TaskStatus.returned,
      }.contains(status ?? this.status),
      canComment: permissions.canComment,
    ),
  );
}

/// A comment, an activity entry or an attached file on a task.
class TaskComment {
  const TaskComment(this.author, this.body, this.at, {this.mine = false});
  final TaskPerson author;
  final String body;
  final DateTime at;
  final bool mine;
}

class TaskActivity {
  const TaskActivity(this.actor, this.kind, this.at, {this.note = ''});
  final TaskPerson? actor;

  /// The API's activity kind, such as `created`, `started` or `submitted`.
  final String kind;
  final DateTime at;
  final String note;
}

class TaskFile {
  const TaskFile(this.name, this.size);
  final String name;
  final int size;
}

/// A list tab's tasks with the count for every tab.
class TaskList {
  const TaskList(this.tasks, this.counts);
  final List<TaskItem> tasks;
  final Map<TaskScope, int> counts;
}

/// Who and what a new task can be assigned to.
class TaskOptions {
  const TaskOptions({
    required this.me,
    required this.people,
    this.projects = const [],
    this.teams = const [],
  });
  final TaskPerson me;
  final List<TaskPerson> people;

  /// `(id, name)` pairs.
  final List<(String, String)> projects, teams;
}

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.type,
    required this.assignee,
    required this.due,
    required this.priority,
    required this.confidential,
    this.projectId,
    this.teamId,
  });
  final String title, description;
  final TaskType type;
  final TaskPerson assignee;
  final DateTime due;
  final TaskPriority priority;
  final bool confidential;
  final String? projectId, teamId;
}

/// Submitted work waiting for my review, with the review counters.
class ReviewQueue {
  const ReviewQueue({
    required this.tasks,
    required this.avgHours,
    required this.approved,
    required this.returned,
  });

  /// Oldest submission first.
  final List<TaskItem> tasks;
  final double avgHours;

  /// Approved and returned this week.
  final int approved, returned;

  /// After deciding [task]: it leaves the queue and a counter goes up.
  ReviewQueue decided(TaskItem task, {required bool approved}) => ReviewQueue(
    tasks: [
      for (final t in tasks)
        if (t.id != task.id) t,
    ],
    avgHours: avgHours,
    approved: this.approved + (approved ? 1 : 0),
    returned: returned + (approved ? 0 : 1),
  );
}
