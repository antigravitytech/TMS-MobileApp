import 'dart:ui' as ui;
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../../shared/kit/kit.dart';
import '../application/tasks_controller.dart';
import '../domain/task.dart';
import 'tasks_screen.dart' show taskErrorMessage;
import 'widgets/task_labels.dart';

part 'widgets/new_task_options.dart';
part 'widgets/new_task_confirmation.dart';

class NewTaskScreen extends ConsumerStatefulWidget {
  const NewTaskScreen({super.key});
  @override
  ConsumerState<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends ConsumerState<NewTaskScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  TaskType type = TaskType.standalone;
  TaskPriority priority = TaskPriority.medium;
  TaskPerson? person;
  (String, String)? place;
  late DateTime due = _friday;
  bool confidential = false, busy = false;
  TaskItem? created;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// This week's Friday, or next week's when today is Friday or later.
  static DateTime get _friday {
    final ahead = (DateTime.friday - _today.weekday) % 7;
    return _today.add(Duration(days: ahead == 0 ? 7 : ahead));
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _create(TaskOptions options) async {
    final assignee = person ?? options.people.firstOrNull ?? options.me;
    setState(() => busy = true);
    try {
      final task = await ref.read(createTaskProvider)(
        TaskDraft(
          title: title.text,
          description: description.text,
          type: type,
          assignee: assignee,
          due: due,
          priority: priority,
          confidential: confidential,
          projectId: type == TaskType.project ? place?.$1 : null,
          teamId: type == TaskType.team ? place?.$1 : null,
        ),
      );
      if (mounted) setState(() => created = task);
    } catch (error) {
      if (mounted) designToast(context, taskErrorMessage(context, error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Project or team choices for the selected type.
  List<(String, String)> _places(TaskOptions options) => switch (type) {
    TaskType.project => options.projects,
    TaskType.team => options.teams,
    _ => const [],
  };

  Future<void> _pickPlace(List<(String, String)> places) async {
    final chosen = await designSheet<(String, String)>(
      context,
      title: taskTypeText(context, type),
      builder: (sheet) => Column(
        children: [
          for (final p in places)
            ListTile(
              title: Text(p.$2),
              trailing: p == place ? const Icon(TmsIcons.check) : null,
              onTap: () => Navigator.pop(sheet, p),
            ),
        ],
      ),
    );
    if (mounted && chosen != null) setState(() => place = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(taskOptionsProvider);
    final created = this.created;
    return Stack(
      children: [
        switch (options) {
          AsyncValue(value: final o?) => _form(context, o),
          AsyncValue(:final error?) => DesignPage(
            title: context.tr('common.new_task'),
            children: [
              DesignLabel(taskErrorMessage(context, error)),
              DesignButton(
                context.tr('workspaces.try_again'),
                onPressed: () => ref.invalidate(taskOptionsProvider),
              ),
            ],
          ),
          _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
        },
        if (created != null)
          Positioned.fill(
            child: _TaskConfirmation(
              id: created.reference,
              person: created.assignee?.name ?? '',
              due: taskDueText(context, created.due),
              onAgain: () => setState(() {
                title.clear();
                description.clear();
                this.created = null;
              }),
            ),
          ),
      ],
    );
  }

  Widget _form(BuildContext context, TaskOptions options) {
    final people = [options.me, ...options.people];
    // Like the design, a colleague is picked until someone else is chosen.
    final assignee = person ?? options.people.firstOrNull ?? options.me;
    final places = _places(options);
    final chosenPlace = places.contains(place) ? place : places.firstOrNull;
    final needsPlace =
        (type == TaskType.project || type == TaskType.team) &&
        chosenPlace == null;
    String personLabel(TaskPerson p) =>
        p.id == options.me.id ? context.tr('common.me') : p.firstName;
    return DesignPage(
      title: context.tr('common.new_task'),
      headerTop: 12,
      leading: DesignIcon(
        icon: TmsIcons.close,
        label: context.tr('common.back'),
        onPressed: () => context.router.maybePop(),
      ),
      footer: created != null
          ? null
          : DesignButton(
              context.tr(
                'tasks.create_and_assign',
                namedArgs: {'person': personLabel(assignee)},
              ),
              onPressed: title.text.trim().isEmpty || busy || needsPlace
                  ? null
                  : () {
                      place = chosenPlace;
                      _create(options);
                    },
            ),
      children: [
        TextField(
          controller: title,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: context.tr('tasks.what_needs_doing'),
            isDense: true,
          ),
        ),
        TextField(
          controller: description,
          maxLines: 2,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: context.tr('tasks.description_hint'),
            isDense: true,
          ),
        ),
        DesignLabel(context.tr('tasks.type')),
        _TaskTypeSwitch(
          type: type,
          onChanged: (t) => setState(() {
            type = t;
            place = null;
          }),
        ),
        if (type != TaskType.standalone)
          DesignCard(
            onTap: places.isEmpty ? null : () => _pickPlace(places),
            child: Row(
              children: [
                Icon(
                  type == TaskType.recurring ? TmsIcons.history : TmsIcons.work,
                  color: type == TaskType.recurring
                      ? DesignColor.teal
                      : context.lavender,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type == TaskType.recurring
                        ? context.tr('tasks.every_weekday_by_5_00_pm')
                        : chosenPlace?.$2 ?? context.tr('tasks.none_to_pick'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (places.length > 1)
                  Icon(TmsIcons.chevronNext, size: 16, color: context.muted),
              ],
            ),
          ),
        DesignLabel(context.tr('tasks.assign_to')),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final p in people)
                SizedBox(
                  width: 68,
                  child: GestureDetector(
                    onTap: () => setState(() => person = p),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: DesignMotion.fast,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: p.id == assignee.id
                                  ? DesignColor.purple
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: kitPerson(p.name).$2,
                            child: Text(
                              kitPerson(p.name).$1,
                              style: const TextStyle(
                                color: DesignColor.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          personLabel(p),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.id == assignee.id
                                ? context.foreground
                                : context.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        DesignLabel(context.tr('tasks.due')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in [
              _today,
              _today.add(const Duration(days: 1)),
              _friday,
            ])
              _TaskChip(
                taskDueText(context, day),
                selected: DateUtils.isSameDay(due, day),
                onTap: () => setState(() => due = day),
              ),
            _TaskChip(
              context.tr('tasks.pick_a_date'),
              onTap: () async {
                final chosen = await showDatePicker(
                  switchToInputEntryModeIcon: const Icon(TmsIcons.keyboard),
                  switchToCalendarEntryModeIcon: const Icon(TmsIcons.calendar),
                  context: context,
                  initialDate: due,
                  firstDate: _today,
                  lastDate: DateTime(_today.year + 5),
                );
                if (mounted && chosen != null) setState(() => due = chosen);
              },
            ),
          ],
        ),
        DesignLabel(
          context.tr('tasks.this_becomes_the_original_target_it_never'),
        ),
        DesignLabel(context.tr('common.priority')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, p) in TaskPriority.values.indexed)
              _TaskChip(
                taskPriorityText(context, p),
                selected: priority == p,
                color: [
                  context.muted,
                  DesignColor.amber,
                  const Color(0xfff59562),
                  DesignColor.red,
                ][i],
                onTap: () => setState(() => priority = p),
              ),
          ],
        ),
        _TaskPrivacy(
          value: confidential,
          onChanged: (value) => setState(() => confidential = value),
        ),
      ],
    );
  }
}
