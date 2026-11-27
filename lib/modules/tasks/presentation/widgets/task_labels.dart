import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../domain/task.dart';

String taskStatusLabel(BuildContext context, String status) => switch (status) {
  'Not started' => context.tr('common.not_started'),
  'In progress' => context.tr('common.in_progress'),
  'Submitted' => context.tr('common.submitted'),
  'Returned' => context.tr('common.returned'),
  'Completed' => context.tr('common.completed'),
  _ => status,
};

String taskPriorityLabel(BuildContext context, String priority) =>
    switch (priority) {
      'Low' => context.tr('common.low'),
      'Medium' => context.tr('common.medium'),
      'High' => context.tr('common.high'),
      'Urgent' => context.tr('common.urgent'),
      _ => priority,
    };

String taskProjectLabel(BuildContext context, String project) =>
    switch (project) {
      'Standalone' => context.tr('common.standalone'),
      'Project' => context.tr('common.project'),
      'Team' => context.tr('common.team'),
      'Recurring' => context.tr('tasks.recurring'),
      _ => project,
    };

String assigneeLabel(BuildContext context, String person) =>
    person == 'Me' ? context.tr('common.me') : person;

String taskDueLabel(BuildContext context, String due) => switch (due) {
  'Today' => context.tr('common.today'),
  'Tomorrow' => context.tr('common.tomorrow'),
  'Fri, 27 Nov' => context.tr('tasks.upcoming_date'),
  'Wed, 25 Nov' => context.tr('tasks.review_date'),
  'Fri, 13 Nov' => context.tr('tasks.completed_date'),
  '1 day overdue' => context.plural('tasks.days_overdue', 1),
  '2 days overdue' => context.plural('tasks.days_overdue', 2),
  _ => due,
};

String taskStatusText(BuildContext context, TaskStatus status) =>
    switch (status) {
      TaskStatus.notStarted => context.tr('common.not_started'),
      TaskStatus.inProgress => context.tr('common.in_progress'),
      TaskStatus.submitted => context.tr('common.submitted'),
      TaskStatus.returned => context.tr('common.returned'),
      TaskStatus.completed => context.tr('common.completed'),
    };

String taskPriorityText(BuildContext context, TaskPriority priority) =>
    switch (priority) {
      TaskPriority.low => context.tr('common.low'),
      TaskPriority.medium => context.tr('common.medium'),
      TaskPriority.high => context.tr('common.high'),
      TaskPriority.critical => context.tr('common.urgent'),
    };

String taskTypeText(BuildContext context, TaskType type) => switch (type) {
  TaskType.standalone => context.tr('common.standalone'),
  TaskType.project => context.tr('common.project'),
  TaskType.team => context.tr('common.team'),
  TaskType.recurring => context.tr('tasks.recurring'),
};

/// The project or team name, or the task's type when it has neither.
String taskPlaceText(BuildContext context, TaskItem task) =>
    task.project.isNotEmpty ? task.project : taskTypeText(context, task.type);

/// "Today", "Tomorrow", "2 days overdue" or a short date.
String taskDueText(BuildContext context, DateTime? due, {bool done = false}) {
  if (due == null) return context.tr('tasks.no_due_date');
  final now = DateTime.now();
  final days = DateTime(
    due.year,
    due.month,
    due.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (!done && days < 0) return context.plural('tasks.days_overdue', -days);
  if (days == 0) return context.tr('common.today');
  if (days == 1) return context.tr('common.tomorrow');
  return DateFormat('EEE, d MMM', context.locale.toString()).format(due);
}
