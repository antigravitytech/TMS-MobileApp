import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../../shared/kit/kit.dart';
import '../application/tasks_controller.dart';
import '../domain/task.dart';
import 'tasks_screen.dart' show taskErrorMessage;
import 'widgets/task_card.dart';
import 'widgets/task_labels.dart';

part 'widgets/task_detail_sections.dart';
part 'widgets/task_detail_tabs.dart';
part 'widgets/task_detail_panels.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key});
  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  int tab = 0;
  bool busy = false;
  final comment = TextEditingController();
  final note = TextEditingController();

  @override
  void dispose() {
    comment.dispose();
    note.dispose();
    super.dispose();
  }

  OpenedTask get _task => ref.read(openedTaskProvider.notifier);

  /// Runs a workflow action, then shows [done] or the failure.
  Future<void> _act(Future<void> Function() action, String done) async {
    setState(() => busy = true);
    try {
      await action();
      if (mounted) designToast(context, done);
    } catch (error) {
      if (mounted) designToast(context, taskErrorMessage(context, error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _submit(TaskItem task) async {
    final confirmed = await designSheet<bool>(
      context,
      title: context.tr('tasks.submit_for_review'),
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('tasks.submit_explanation'),
            style: TextStyle(color: context.muted),
          ),
          const SizedBox(height: 16),
          Text(context.tr('tasks.note_for_assigner')),
          const SizedBox(height: 7),
          TextField(
            controller: note,
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: context.raised,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          DesignButton(
            context.tr('tasks.submit'),
            onPressed: () => Navigator.pop(sheet, true),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final done = context.tr(
      'tasks.sent_to',
      namedArgs: {'name': task.assigner?.firstName ?? ''},
    );
    await _act(() => _task.submit(note.text), done);
    note.clear();
    if (mounted) setState(() => tab = 0);
  }

  /// The main action the task allows right now, or its state.
  Widget _action(TaskItem task) {
    final p = task.permissions;
    if (p.canStart) {
      return DesignButton(
        context.tr('tasks.start_task'),
        onPressed: busy
            ? null
            : () => _act(_task.start, context.tr('tasks.started_toast')),
      );
    }
    if (p.canSubmit) {
      return DesignButton(
        context.tr('tasks.submit_for_review'),
        onPressed: busy ? null : () => _submit(task),
      );
    }
    if (p.canComplete) {
      return DesignButton(
        context.tr('tasks.mark_complete'),
        onPressed: busy
            ? null
            : () => _act(_task.complete, context.tr('tasks.completed_toast')),
      );
    }
    final submitted = task.status == TaskStatus.submitted;
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.raised,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        submitted
            ? context.tr(
                'tasks.waiting_for',
                namedArgs: {'name': task.assigner?.firstName ?? ''},
              )
            : taskStatusText(context, task.status),
        style: TextStyle(
          color: taskStatusTone(task.status),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(openedTaskProvider);
    if (task == null) {
      return DesignPage(
        title: context.tr('common.tasks'),
        children: [DesignLabel(context.tr('common.nothing_here'))],
      );
    }
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      DesignIcon(
                        icon: TmsIcons.chevronBack,
                        label: context.tr('common.back'),
                        onPressed: () => context.router.maybePop(),
                      ),
                      Expanded(
                        child: Text(
                          '${taskPlaceText(context, task)} · ${task.reference}',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: context.muted),
                        ),
                      ),
                      DesignIcon(
                        icon: TmsIcons.more,
                        label: context.tr('tasks.more_actions'),
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: context.panel,
                          builder: (sheet) => SafeArea(
                            child: ListTile(
                              leading: const Icon(TmsIcons.chat),
                              title: Text(
                                context.tr('tasks.open_conversation'),
                              ),
                              onTap: () {
                                Navigator.pop(sheet);
                                TmsRoute.conversation.open(context);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 7,
                        children: [
                          _SmallTag(
                            taskStatusText(context, task.status),
                            taskStatusTone(task.status),
                            dot: true,
                          ),
                          _SmallTag(
                            taskPriorityText(context, task.priority),
                            DesignColor.amber,
                          ),
                          _SmallTag(
                            context.tr(
                              task.confidential
                                  ? 'tasks.confidential'
                                  : 'tasks.public',
                            ),
                            context.muted,
                          ),
                          if (task.round > 0)
                            _SmallTag(
                              context.tr(
                                'tasks.round',
                                namedArgs: {'n': '${task.round}'},
                              ),
                              context.muted,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          style: TextStyle(
                            color: context.muted,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _PersonCard(
                              task.assignee?.name ?? '',
                              context.tr('tasks.assignee'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PersonCard(
                              task.assigner?.name ?? '',
                              context.tr('tasks.assigner'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ProgressCard(task),
                      const SizedBox(height: 18),
                      _TaskTabs(tab, (i) => setState(() => tab = i)),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: DesignMotion.duration(
                          context,
                          DesignMotion.fast,
                        ),
                        switchInCurve: DesignMotion.curve,
                        child: KeyedSubtree(
                          key: ValueKey(tab),
                          child: switch (tab) {
                            1 => _CommentsPanel(
                              task: task,
                              controller: comment,
                            ),
                            2 => _FilesPanel(task),
                            3 => _DetailsPanel(task),
                            _ => _ActivityPanel(task),
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  decoration: BoxDecoration(
                    color: context.background,
                    border: Border(top: BorderSide(color: context.outline)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: DesignIcon(
                          icon: TmsIcons.chat,
                          label: context.tr('tasks.open_conversation'),
                          onPressed: () => TmsRoute.conversation.open(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _action(task)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
