part of '../tasks_screen.dart';

class _TaskGroupTabs extends StatelessWidget {
  const _TaskGroupTabs({
    required this.labels,
    required this.counts,
    required this.selected,
    required this.onChanged,
  });
  final List<String> labels;
  final List<int> counts;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          InkWell(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 10, 22, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: i == selected
                        ? DesignColor.purple
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: i == selected ? context.foreground : context.muted,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.raised,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${counts[i]}',
                      style: TextStyle(fontSize: 11, color: context.lavender),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _TaskFilterChip extends StatelessWidget {
  const _TaskFilterChip(
    this.label, {
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? context.foreground : Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: context.outline),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? context.background : context.muted,
          ),
        ),
      ),
    ),
  );
}

class _CompactTaskCard extends ConsumerWidget {
  const _CompactTaskCard(this.task);
  final PreviewTask task;
  @override
  Widget build(BuildContext context, WidgetRef ref) => DesignCard(
    padding: const EdgeInsets.all(16),
    onTap: () {
      ref.read(workspacePreviewProvider).selectTask(task);
      TmsRoute.task.open(context);
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: taskStatusColor(task.status).withValues(alpha: .16),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: taskStatusColor(task.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    taskStatusLabel(context, task.status),
                    style: TextStyle(
                      fontSize: 11,
                      color: taskStatusColor(task.status),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              taskPriorityLabel(context, task.priority),
              style: TextStyle(
                fontSize: 12,
                color: task.priority == 'Low'
                    ? context.muted
                    : DesignColor.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Text(
          task.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: task.person.startsWith('Ibrahim')
                  ? DesignColor.blue
                  : task.person.startsWith('Tunde')
                  ? DesignColor.teal
                  : DesignColor.amber,
              child: Text(
                task.person.split(' ').map((v) => v[0]).take(2).join(),
                style: const TextStyle(
                  fontSize: 10,
                  color: DesignColor.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${taskProjectLabel(context, task.project)} · ${task.id}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: context.muted),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              taskDueLabel(context, task.due),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: task.due.contains('overdue')
                    ? DesignColor.red
                    : task.due == 'Today'
                    ? DesignColor.amber
                    : context.muted,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
