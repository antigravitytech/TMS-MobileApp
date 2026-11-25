import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

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

String taskGroupLabel(BuildContext context, String group) => switch (group) {
  'Mine' => context.tr('tasks.mine'),
  'Requested' => context.tr('tasks.requested'),
  'Team' => context.tr('common.team'),
  'All' => context.tr('common.all'),
  _ => group,
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
