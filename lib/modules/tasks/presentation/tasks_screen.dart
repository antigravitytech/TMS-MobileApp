import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/quick_create.dart';
import '../../workspace/application/workspace_preview.dart';
import 'task_card.dart';
import 'task_labels.dart';
import '../../../shared/design/tms_icons.dart';

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
  static const sorts = ['tasks.due_date', 'common.priority', 'common.title'];
  int group = 0, filter = 0, priority = 0, project = 0, sort = 0;
  void reset() => setState(() {
    filter = 0;
    priority = 0;
    project = 0;
    sort = 0;
  });

  Future<void> openFilters() async {
    var p = priority, j = project, s = sort;
    final result = await designSheet<(int, int, int)>(
      context,
      title: context.tr('tasks.sort_filter'),
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => update(() {
                  p = 0;
                  j = 0;
                  s = 0;
                }),
                child: Text(context.tr('tasks.reset')),
              ),
            ),
            DesignTitle(context.tr('tasks.sort_by')),
            DesignChoices(
              items: sorts.map(context.tr).toList(),
              selected: s,
              onChanged: (i) => update(() => s = i),
            ),
            DesignTitle(context.tr('common.priority')),
            DesignChoices(
              items: [
                context.tr(priorities.first),
                for (final value in priorities.skip(1))
                  taskPriorityLabel(context, value),
              ],
              selected: p,
              onChanged: (i) => update(() => p = i),
            ),
            DesignTitle(context.tr('common.project')),
            DesignChoices(
              items: [
                context.tr(projects.first),
                for (final value in projects.skip(1))
                  taskProjectLabel(context, value),
              ],
              selected: j,
              onChanged: (i) => update(() => j = i),
              scroll: false,
            ),
            DesignButton(
              context.tr('tasks.show_tasks'),
              onPressed: () => Navigator.pop(sheet, (p, j, s)),
            ),
          ],
        ),
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
    if (sort == 2) items.sort((a, b) => a.title.compareTo(b.title));
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
        DesignChoices(
          items: groups.map((value) => taskGroupLabel(context, value)).toList(),
          selected: group,
          onChanged: (i) => setState(() => group = i),
        ),
        DesignChoices(
          items: [
            context.tr('common.all'),
            context.tr('common.today'),
            context.tr('common.overdue'),
            for (final status in filters.skip(3))
              taskStatusLabel(context, status),
          ],
          selected: filter,
          onChanged: (i) => setState(() => filter = i),
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
          DesignTitle(
            context.tr(
              'tasks.group_count',
              namedArgs: {
                'group': taskGroupLabel(context, groups[group]),
                'count': items.length.toString(),
              },
            ),
          ),
          for (final task in items) TaskCard(task, key: ValueKey(task.id)),
        ],
      ],
    );
  }
}
