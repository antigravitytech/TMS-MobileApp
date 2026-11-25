import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import 'task_labels.dart';
import '../../../shared/design/tms_icons.dart';

Color taskStatusColor(String status) => switch (status) {
  'Completed' => DesignColor.green,
  'Submitted' => DesignColor.amber,
  'Returned' => DesignColor.rose,
  'In progress' => DesignColor.blue,
  _ => DesignColor.purple,
};

class TaskCard extends ConsumerWidget {
  const TaskCard(this.task, {super.key});
  final PreviewTask task;
  @override
  Widget build(BuildContext context, WidgetRef ref) => DesignCard(
    onTap: () {
      ref.read(workspacePreviewProvider).selectTask(task);
      TmsRoute.task.open(context);
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 9,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DesignPill(
              taskStatusLabel(context, task.status),
              color: taskStatusColor(task.status),
              icon: TmsIcons.dot,
            ),
            DesignLabel(
              taskPriorityLabel(context, task.priority),
              color: task.priority == 'High'
                  ? DesignColor.amber
                  : context.muted,
            ),
            DesignLabel(task.id),
          ],
        ),
        Text(
          task.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        Row(
          spacing: 8,
          children: [
            DesignAvatar(
              task.person.substring(0, 1).toUpperCase(),
              size: 29,
              color: DesignColor.blue,
            ),
            Expanded(
              child: DesignLabel(
                '${assigneeLabel(context, task.person)} · ${taskProjectLabel(context, task.project)}',
              ),
            ),
            DesignLabel(
              taskDueLabel(context, task.due),
              color: context.lavender,
            ),
          ],
        ),
      ],
    ),
  );
}
