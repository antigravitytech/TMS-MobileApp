part of '../home_screen.dart';

PreviewTask _dashboardTask(
  BuildContext context,
  DashboardJson task, {
  bool reviewer = false,
}) {
  final person = dashboardObject(task[reviewer ? 'assignee' : 'assigner']);
  final date = dashboardDate(task['due_date']);
  return PreviewTask(
    dashboardText(task['reference']),
    dashboardText(task['title']),
    dashboardText(
      dashboardObject(task['project'])['name'],
      dashboardText(
        dashboardObject(task['team'])['name'],
        switch (task['type']) {
          'project' => 'Project',
          'team' => 'Team',
          'recurring' => 'Recurring',
          'standalone' => 'Standalone',
          _ => '',
        },
      ),
    ),
    [person['first_name'], person['last_name']].whereType<String>().join(' '),
    date == null ? '' : DateFormat.MMMd(context.locale.toString()).format(date),
    switch (task['status']) {
      'not_started' => 'Not started',
      'in_progress' => 'In progress',
      'submitted' => 'Submitted',
      'returned' => 'Returned',
      'completed' => 'Completed',
      _ => '',
    },
    switch (task['priority']) {
      'low' => 'Low',
      'medium' => 'Medium',
      'high' => 'High',
      'critical' => 'Urgent',
      _ => '',
    },
  );
}
