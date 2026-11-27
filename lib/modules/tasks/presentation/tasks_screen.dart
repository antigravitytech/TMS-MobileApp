import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/quick_create.dart';
import '../../../shared/design/design_tokens.dart';

import '../../workspace/application/workspace_preview.dart';
import 'widgets/task_card.dart';
import 'widgets/task_labels.dart';
import '../../../shared/design/tms_icons.dart';

part 'widgets/tasks_list_widgets.dart';
part 'widgets/tasks_filter_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  static const groups = ['Mine', 'Requested', 'Team', 'All'];
  static const filters = [
    'All',
    'Today',
    'Overdue',
    'In progress',
    'Submitted',
    'Returned',
    'Completed',
  ];
  static const priorities = [
    'tasks.any_priority',
    'Urgent',
    'High',
    'Medium',
    'Low',
  ];
  static const projects = [
    'common.all_projects',
    'Standalone',
    'Tech Team',
    'Customer Portal Revamp',
    'Mobile App Launch',
  ];
  static const sorts = ['tasks.due_date', 'common.priority', 'common.project'];
  int group = 0, filter = 0, priority = 0, project = 0, sort = 0;
  void reset() => setState(() {
    filter = 0;
    priority = 0;
    project = 0;
    sort = 0;
  });

  Future<void> openFilters() async {
    var p = priority, j = project, s = sort;
    final result = await showModalBottomSheet<(int, int, int)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheet) => _TaskFilterSheet(
        priority: p,
        project: j,
        sort: s,
        tasks: ref
            .read(workspacePreviewProvider)
            .tasks
            .where((t) => group == 3 || t.group == groups[group])
            .toList(),
      ),
    );
    if (mounted && result != null) {
      setState(() {
        final (chosenPriority, chosenProject, chosenSort) = result;
        priority = chosenPriority;
        project = chosenProject;
        sort = chosenSort;
      });
    }
  }

  String _bucket(PreviewTask t) => t.status == 'Completed'
      ? 'done'
      : t.due.contains('overdue')
      ? 'overdue'
      : t.due == 'Today'
      ? 'today'
      : 'week';

  @override
  Widget build(BuildContext context) {
    final items = ref
        .watch(workspacePreviewProvider)
        .tasks
        .where(
          (t) =>
              (group == 3 || t.group == groups[group]) &&
              (priority == 0 || t.priority == priorities[priority]) &&
              (project == 0 || t.project == projects[project]) &&
              (filter == 0 ||
                  switch (filter) {
                    1 => t.due == 'Today',
                    2 => t.due.contains('overdue'),
                    _ => t.status == filters[filter],
                  }),
        )
        .toList();
    if (sort == 1) {
      items.sort(
        (a, b) => priorities
            .indexOf(a.priority)
            .compareTo(priorities.indexOf(b.priority)),
      );
    }
    if (sort == 2) items.sort((a, b) => a.project.compareTo(b.project));
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
          onPressed: openFilters,
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
          counts: [
            for (final g in groups)
              ref
                  .watch(workspacePreviewProvider)
                  .tasks
                  .where((t) => g == 'All' || t.group == g)
                  .length,
          ],
          selected: group,
          onChanged: (i) => setState(() => group = i),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final status in [
                'All',
                'In progress',
                'Submitted',
                'Returned',
                'Completed',
              ])
                _TaskFilterChip(
                  status == 'All'
                      ? context.tr('common.all')
                      : taskStatusLabel(context, status),
                  selected: filters[filter] == status,
                  onTap: () => setState(() => filter = filters.indexOf(status)),
                ),
            ],
          ),
        ),
        if (priority > 0 || project > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: reset,
              child: Text(context.tr('tasks.clear_filters')),
            ),
          ),
        if (items.isEmpty) ...[
          DesignEmpty(
            context.tr('common.nothing_here'),
            context.tr('tasks.no_tasks_match_this_filter'),
            icon: TmsIcons.emptyList,
          ),
          DesignButton(context.tr('tasks.clear_filters'), onPressed: reset),
        ] else ...[
          for (final bucket in ['overdue', 'today', 'week', 'done']) ...[
            if (items.any((t) => _bucket(t) == bucket)) ...[
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'tasks.bucket_$bucket',
                  namedArgs: {
                    'count': items
                        .where((t) => _bucket(t) == bucket)
                        .length
                        .toString(),
                  },
                ),
                style: TextStyle(
                  color: context.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              for (final task in items.where((t) => _bucket(t) == bucket))
                _CompactTaskCard(task),
            ],
          ],
        ],
      ],
    );
  }
}
