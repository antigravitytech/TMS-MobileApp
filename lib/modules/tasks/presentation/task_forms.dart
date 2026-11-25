import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import 'task_card.dart';
import 'task_labels.dart';
import '../../../shared/design/tms_icons.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key});
  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  int tab = 0;
  final input = TextEditingController();
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspacePreviewProvider);
    final task = state.activeTask;
    return DesignPage(
      title: context.tr('tasks.task_detail'),
      subtitle: '${taskProjectLabel(context, task.project)} · ${task.id}',
      footer: !['Submitted', 'Completed'].contains(task.status)
          ? DesignButton(
              context.tr('tasks.submit_for_review'),
              icon: TmsIcons.send,
              onPressed: () async {
                final confirmed = await designSheet<bool>(
                  context,
                  title: context.tr('tasks.submit_for_review'),
                  builder: (sheet) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 11,
                    children: [
                      DesignField(label: context.tr('common.notes'), lines: 3),
                      DesignButton(
                        context.tr('tasks.submit'),
                        onPressed: () => Navigator.pop(sheet, true),
                      ),
                    ],
                  ),
                );
                if (mounted && confirmed == true) {
                  state.updateTask(task, 'Submitted');
                  designToast(
                    this.context,
                    this.context.tr('tasks.submitted_for_review'),
                  );
                }
              },
            )
          : null,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DesignPill(
              taskStatusLabel(context, task.status),
              color: taskStatusColor(task.status),
            ),
            DesignPill(
              taskPriorityLabel(context, task.priority),
              color: DesignColor.amber,
            ),
            DesignPill(context.tr('tasks.public')),
          ],
        ),
        Text(
          task.title,
          style: const TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            height: 1.13,
          ),
        ),
        if (task.note.isNotEmpty) DesignLabel(task.note),
        DesignSection(
          children: [
            DesignTile(
              title: 'Chioma Okafor',
              subtitle: context.tr('tasks.assignee'),
              leading: const DesignAvatar('CO'),
            ),
            DesignTile(
              title: task.person,
              subtitle: context.tr('tasks.assigner'),
              leading: const DesignAvatar('IM', color: DesignColor.blue),
            ),
          ],
        ),
        DesignCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              for (final (label, value) in [
                (
                  context.tr('tasks.original_target'),
                  context.tr('tasks.original_target_date'),
                ),
                (
                  context.tr('tasks.current_target'),
                  taskDueLabel(context, task.due),
                ),
                (
                  context.tr('common.completed'),
                  task.status == 'Completed'
                      ? context.tr('common.today')
                      : context.tr('tasks.not_yet'),
                ),
              ])
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      DesignLabel(label),
                      Text(
                        value,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        DesignChoices(
          items: [
            context.tr('tasks.activity'),
            context.tr('tasks.comments'),
            context.tr('common.files'),
            context.tr('tasks.details'),
          ],
          selected: tab,
          onChanged: (i) => setState(() => tab = i),
        ),
        switch (tab) {
          1 => Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final comment in state.comments[task.id] ?? <String>[])
                DesignCard(child: Text(comment)),
              DesignField(
                label: context.tr('tasks.write_a_comment'),
                controller: input,
                suffix: IconButton(
                  tooltip: context.tr('tasks.send_comment'),
                  icon: const Icon(TmsIcons.send),
                  onPressed: () {
                    if (input.text.trim().isEmpty) return;
                    state.addComment(task.id, input.text.trim());
                    input.clear();
                  },
                ),
              ),
            ],
          ),
          2 => DesignSection(
            children: [
              DesignTile(
                title: context.tr('tasks.view_workspace_files'),
                icon: TmsIcons.attachment,
                onTap: () => TmsRoute.files.open(context),
              ),
            ],
          ),
          3 => DesignCard(
            child: DesignLabel(
              context.tr(
                'tasks.details_summary',
                namedArgs: {
                  'project': taskProjectLabel(context, task.project),
                  'id': task.id,
                  'priority': taskPriorityLabel(context, task.priority),
                },
              ),
            ),
          ),
          _ => DesignSection(
            children: [
              DesignTile(
                title: taskStatusLabel(context, task.status),
                subtitle: context.tr('tasks.activity_today'),
                icon: TmsIcons.history,
              ),
              DesignTile(
                title: context.tr('tasks.open_conversation'),
                icon: TmsIcons.chat,
                onTap: () => TmsRoute.conversation.open(context),
              ),
            ],
          ),
        },
      ],
    );
  }
}

class NewTaskScreen extends ConsumerStatefulWidget {
  const NewTaskScreen({super.key});
  @override
  ConsumerState<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends ConsumerState<NewTaskScreen> {
  final title = TextEditingController(text: 'Push notification copy for beta');
  final description = TextEditingController();
  static const types = ['Standalone', 'Project', 'Team', 'Recurring'];
  static const people = ['Me', 'Tunde', 'Amaka', 'Sarah', 'David', 'Ngozi'];
  static const priorities = ['Low', 'Medium', 'High', 'Urgent'];
  String due = 'Fri, 27 Nov';
  int type = 0, person = 1, priority = 1;
  bool confidential = false, created = false;
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DesignPage(
    title: context.tr('common.new_task'),
    footer: created
        ? null
        : DesignButton(
            context.tr(
              'tasks.create_and_assign',
              namedArgs: {'person': assigneeLabel(context, people[person])},
            ),
            onPressed: title.text.trim().isEmpty
                ? null
                : () {
                    ref
                        .read(workspacePreviewProvider)
                        .addTask(
                          title.text.trim(),
                          description.text.trim(),
                          people[person],
                          due,
                          priorities[priority],
                          type == 1 ? 'Customer Portal Revamp' : types[type],
                        );
                    setState(() => created = true);
                  },
          ),
    children: [
      if (created) ...[
        DesignEmpty(
          context.tr('tasks.task_created'),
          context.tr(
            'tasks.assigned_notice',
            namedArgs: {
              'person': assigneeLabel(context, people[person]),
              'due': taskDueLabel(context, due),
            },
          ),
        ),
        DesignButton(
          context.tr('tasks.view_task'),
          onPressed: () => TmsRoute.task.open(context),
        ),
        DesignButton(
          context.tr('tasks.create_another'),
          secondary: true,
          onPressed: () => setState(() {
            title.clear();
            description.clear();
            created = false;
          }),
        ),
        TextButton(
          onPressed: () => TmsRoute.tasks.open(context),
          child: Text(context.tr('common.done')),
        ),
      ] else ...[
        DesignField(
          label: context.tr('common.title'),
          controller: title,
          onChanged: (_) => setState(() {}),
        ),
        DesignField(
          label: context.tr('tasks.description'),
          controller: description,
          lines: 3,
        ),
        DesignTitle(context.tr('tasks.type')),
        DesignChoices(
          items: types
              .map((value) => taskProjectLabel(context, value))
              .toList(),
          selected: type,
          onChanged: (i) => setState(() => type = i),
        ),
        if (type == 1) const DesignPill('Customer Portal Revamp'),
        if (type == 3) DesignPill(context.tr('tasks.every_weekday_by_5_00_pm')),
        DesignTitle(context.tr('tasks.assign_to')),
        DesignChoices(
          items: people.map((value) => assigneeLabel(context, value)).toList(),
          selected: person,
          onChanged: (i) => setState(() => person = i),
        ),
        DesignTitle(context.tr('tasks.due')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in ['Today', 'Tomorrow', 'Fri, 27 Nov'])
              DesignPill(
                taskDueLabel(context, day),
                selected: due == day,
                onTap: () => setState(() => due = day),
              ),
            DesignPill(
              context.tr('tasks.pick_a_date'),
              icon: TmsIcons.calendar,
              onTap: () async {
                final now = DateTime.now();
                final chosen = await showDatePicker(
                  switchToInputEntryModeIcon: const Icon(TmsIcons.keyboard),
                  switchToCalendarEntryModeIcon: const Icon(TmsIcons.calendar),
                  context: context,
                  initialDate: now,
                  firstDate: now,
                  lastDate: DateTime(now.year + 5),
                );
                if (mounted && chosen != null) {
                  setState(
                    () => due = MaterialLocalizations.of(
                      this.context,
                    ).formatShortDate(chosen),
                  );
                }
              },
            ),
          ],
        ),
        DesignLabel(
          context.tr('tasks.this_becomes_the_original_target_it_never'),
        ),
        DesignTitle(context.tr('common.priority')),
        DesignChoices(
          items: priorities
              .map((value) => taskPriorityLabel(context, value))
              .toList(),
          selected: priority,
          onChanged: (i) => setState(() => priority = i),
        ),
        DesignCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            title: Text(context.tr('tasks.confidential')),
            subtitle: DesignLabel(
              context.tr('tasks.only_the_assignee_assigner_and_watchers'),
            ),
            value: confidential,
            onChanged: (on) => setState(() => confidential = on),
          ),
        ),
        DesignButton(
          context.tr('tasks.attach_files'),
          secondary: true,
          icon: TmsIcons.attachment,
          onPressed: () => TmsRoute.files.open(context),
        ),
      ],
    ],
  );
}
