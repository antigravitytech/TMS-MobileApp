import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/design_tokens.dart';
import 'package:auto_route/auto_route.dart';

import '../../workspace/application/workspace_preview.dart';
import 'widgets/task_labels.dart';
import '../../../shared/design/tms_icons.dart';

part 'widgets/new_task_options.dart';
part 'widgets/new_task_confirmation.dart';

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
  Widget build(BuildContext context) => Stack(
    children: [
      _form(context),
      if (created)
        Positioned.fill(
          child: _TaskConfirmation(
            id: ref.watch(workspacePreviewProvider).activeTask.id,
            person: assigneeLabel(context, people[person]),
            due: taskDueLabel(context, due),
            onAgain: () => setState(() {
              title.clear();
              description.clear();
              created = false;
            }),
          ),
        ),
    ],
  );

  Widget _form(BuildContext context) => DesignPage(
    title: context.tr('common.new_task'),
    headerTop: 12,
    leading: DesignIcon(
      icon: TmsIcons.close,
      label: context.tr('common.back'),
      onPressed: () => context.router.maybePop(),
    ),
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
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.outline),
        ),
        child: Row(
          children: [
            for (var i = 0; i < types.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => type = i),
                  child: AnimatedContainer(
                    duration: DesignMotion.fast,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: type == i ? context.raised : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      child: Text(
                        taskProjectLabel(context, types[i]),
                        style: TextStyle(
                          fontSize: 12,
                          color: type == i ? context.foreground : context.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      if (type == 1 || type == 3)
        DesignCard(
          child: Row(
            children: [
              Icon(
                type == 1 ? TmsIcons.work : TmsIcons.history,
                color: type == 1 ? context.lavender : DesignColor.teal,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type == 1
                      ? 'Customer Portal Revamp'
                      : context.tr('tasks.every_weekday_by_5_00_pm'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(TmsIcons.chevronNext, size: 16, color: context.muted),
            ],
          ),
        ),
      DesignLabel(context.tr('tasks.assign_to')),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < people.length; i++)
              SizedBox(
                width: 68,
                child: GestureDetector(
                  onTap: () => setState(() => person = i),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: DesignMotion.fast,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: person == i
                                ? DesignColor.purple
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: [
                            const Color(0xffc4b9f4),
                            const Color(0xff86dbce),
                            const Color(0xffefaab4),
                            const Color(0xffefd087),
                            const Color(0xffb9da98),
                            const Color(0xffd8b7ec),
                          ][i],
                          child: Text(
                            ['CO', 'TB', 'AE', 'SJ', 'DM', 'NA'][i],
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
                        assigneeLabel(context, people[i]),
                        style: TextStyle(
                          fontSize: 12,
                          color: person == i
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
          for (final day in ['Today', 'Tomorrow', 'Fri, 27 Nov'])
            _TaskChip(
              taskDueLabel(context, day),
              selected: due == day,
              onTap: () => setState(() => due = day),
            ),
          _TaskChip(
            context.tr('tasks.pick_a_date'),
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
      DesignLabel(context.tr('common.priority')),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < priorities.length; i++)
            _TaskChip(
              taskPriorityLabel(context, priorities[i]),
              selected: priority == i,
              color: [
                context.muted,
                DesignColor.amber,
                const Color(0xfff59562),
                DesignColor.red,
              ][i],
              onTap: () => setState(() => priority = i),
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
