import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/workspace_preview.dart';
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
  final comment = TextEditingController();
  final note = TextEditingController(
    text: 'Draft plan attached: 3 roles, budget in sheet 2.',
  );

  @override
  void dispose() {
    comment.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _submit(WorkspacePreview state, PreviewTask task) async {
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(TmsIcons.attachment, size: 16),
              const SizedBox(width: 5),
              Text(context.tr('tasks.sample_file')),
            ],
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
    state.updateTask(task, 'Submitted');
    setState(() => tab = 0);
    designToast(context, context.tr('tasks.sent_to_assigner'));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspacePreviewProvider);
    final task = state.activeTask;
    final submitted = task.status == 'Submitted';
    final completed = task.status == 'Completed';
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
                          '${taskProjectLabel(context, task.project)} · ${task.id}',
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
                            taskStatusLabel(context, task.status),
                            taskStatusColor(task.status),
                            dot: true,
                          ),
                          _SmallTag(
                            taskPriorityLabel(context, task.priority),
                            DesignColor.amber,
                          ),
                          _SmallTag(context.tr('tasks.public'), context.muted),
                          _SmallTag(context.tr('tasks.round_1'), context.muted),
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
                      if (task.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          task.note,
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
                              'CO',
                              '${state.firstName} ${state.lastName}',
                              context.tr('tasks.assignee'),
                              DesignColor.purple,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PersonCard(
                              'IM',
                              'Ibrahim Musa',
                              context.tr('tasks.assigner'),
                              DesignColor.blue,
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
                              state: state,
                              controller: comment,
                            ),
                            2 => _FilesPanel(),
                            3 => _DetailsPanel(task),
                            _ => _ActivityPanel(submitted: submitted),
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
                      Expanded(
                        child: submitted || completed
                            ? Container(
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.raised,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  submitted
                                      ? context.tr('tasks.waiting_for_assigner')
                                      : context.tr('common.completed'),
                                  style: TextStyle(
                                    color: submitted
                                        ? DesignColor.amber
                                        : DesignColor.green,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : DesignButton(
                                context.tr('tasks.submit_for_review'),
                                onPressed: () => _submit(state, task),
                              ),
                      ),
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
