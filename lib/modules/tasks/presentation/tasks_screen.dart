import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/quick_create.dart';
import '../../../shared/design/tms_icons.dart';
import '../../../shared/kit/kit.dart';
import '../../authentication/domain/account.dart';
import '../../authentication/presentation/widgets/account_action_form.dart';
import '../application/tasks_controller.dart';
import '../domain/task.dart';
import 'widgets/task_card.dart';
import 'widgets/task_labels.dart';

part 'widgets/tasks_list_widgets.dart';
part 'widgets/tasks_filter_sheet.dart';

/// A failed task request, in words.
String taskErrorMessage(BuildContext context, Object? error) =>
    error is AccountFailure
    ? accountErrorMessage(context, error)
    : context.tr('network.errors.unknown');

/// How the list is narrowed and ordered; null means any.
typedef TaskFilters = ({TaskPriority? priority, String? place, int sort});

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  static const sorts = ['tasks.due_date', 'common.priority', 'common.project'];

  /// The status chips; null is "All".
  static const statuses = [
    null,
    TaskStatus.inProgress,
    TaskStatus.submitted,
    TaskStatus.returned,
    TaskStatus.completed,
  ];

  TaskScope scope = TaskScope.mine;
  TaskStatus? status;
  TaskFilters filters = (priority: null, place: null, sort: 0);

  void reset() => setState(() {
    status = null;
    filters = (priority: null, place: null, sort: 0);
  });

  List<TaskItem> _narrow(List<TaskItem> tasks, TaskFilters f) => [
    for (final t in tasks)
      if ((f.priority == null || t.priority == f.priority) &&
          (f.place == null || _place(t) == f.place))
        t,
  ];

  String _place(TaskItem t) => t.project.isEmpty ? t.type.code : t.project;

  Future<void> openFilters(List<TaskItem> tasks) async {
    final result = await showModalBottomSheet<TaskFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _TaskFilterSheet(
        filters: filters,
        tasks: tasks,
        place: _place,
        narrow: _narrow,
      ),
    );
    if (mounted && result != null) setState(() => filters = result);
  }

  /// Which heading a task sits under.
  String _bucket(TaskItem t, DateTime today) {
    if (t.done) return 'done';
    if (t.overdueDays(today) > 0) return 'overdue';
    final due = t.due;
    if (due != null && DateUtils.isSameDay(due, today)) return 'today';
    return 'week';
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(tasksListProvider(scope));
    final loaded = list.value;
    final today = DateTime.now();
    final items = _narrow([
      for (final t in loaded?.tasks ?? const <TaskItem>[])
        if (status == null || t.status == status) t,
    ], filters);
    switch (filters.sort) {
      case 1:
        items.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      case 2:
        items.sort((a, b) => _place(a).compareTo(_place(b)));
      default:
        items.sort(
          (a, b) =>
              (a.due ?? DateTime(9999)).compareTo(b.due ?? DateTime(9999)),
        );
    }
    final filtered = filters.priority != null || filters.place != null;
    return DesignPage(
      title: context.tr('common.tasks'),
      tab: TmsRoute.tasks,
      floatingActionButton: const QuickCreate(),
      actions: [
        DesignIcon(
          icon: TmsIcons.search,
          label: context.tr('common.search'),
          onPressed: () => TmsRoute.search.open(context),
        ),
        const SizedBox(width: 7),
        DesignIcon(
          icon: TmsIcons.filter,
          label: context.tr('common.sort_and_filter'),
          onPressed: () => openFilters(loaded?.tasks ?? const []),
        ),
      ],
      children: [
        _TaskGroupTabs(
          labels: [
            context.tr('tasks.my_tasks'),
            context.tr('tasks.my_requests'),
            context.tr('common.team'),
            context.tr('common.all'),
          ],
          counts: [for (final s in TaskScope.values) loaded?.counts[s] ?? 0],
          selected: scope.index,
          onChanged: (i) => setState(() => scope = TaskScope.values[i]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final s in statuses)
                _TaskFilterChip(
                  s == null
                      ? context.tr('common.all')
                      : taskStatusText(context, s),
                  selected: status == s,
                  onTap: () => setState(() => status = s),
                ),
            ],
          ),
        ),
        if (filtered)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: reset,
              child: Text(context.tr('tasks.clear_filters')),
            ),
          ),
        if (loaded == null && !list.hasError)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (loaded == null) ...[
          DesignEmpty(
            context.tr('tasks.load_failed'),
            taskErrorMessage(context, list.error),
            icon: TmsIcons.emptyList,
          ),
          DesignButton(
            context.tr('workspaces.try_again'),
            secondary: true,
            onPressed: () => ref.invalidate(tasksListProvider(scope)),
          ),
        ] else if (items.isEmpty) ...[
          DesignEmpty(
            context.tr('common.nothing_here'),
            context.tr('tasks.no_tasks_match_this_filter'),
            icon: TmsIcons.emptyList,
          ),
          if (filtered || status != null)
            DesignButton(context.tr('tasks.clear_filters'), onPressed: reset),
        ] else
          for (final bucket in ['overdue', 'today', 'week', 'done'])
            if (items.any((t) => _bucket(t, today) == bucket)) ...[
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'tasks.bucket_$bucket',
                  namedArgs: {
                    'count':
                        '${items.where((t) => _bucket(t, today) == bucket).length}',
                  },
                ),
                style: TextStyle(
                  color: context.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              for (final task in items.where(
                (t) => _bucket(t, today) == bucket,
              ))
                _CompactTaskCard(task),
            ],
      ],
    );
  }
}
