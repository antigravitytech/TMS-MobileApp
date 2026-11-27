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
  final TaskItem task;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = taskStatusTone(task.status);
    final overdue = task.overdueDays(DateTime.now()) > 0;
    final today =
        task.due != null && DateUtils.isSameDay(task.due, DateTime.now());
    final person = task.assignee?.name ?? '';
    return DesignCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        ref.read(openedTaskProvider.notifier).open(task);
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
                  color: tone.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tone,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      taskStatusText(context, task.status),
                      style: TextStyle(
                        fontSize: 11,
                        color: tone,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                taskPriorityText(context, task.priority),
                style: TextStyle(
                  fontSize: 12,
                  color: task.priority == TaskPriority.low
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
                backgroundColor: kitPerson(person).$2,
                child: Text(
                  kitPerson(person).$1,
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
                  '${taskPlaceText(context, task)} · ${task.reference}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: context.muted),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                taskDueText(context, task.due, done: task.done),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: overdue
                      ? DesignColor.red
                      : today
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
}
