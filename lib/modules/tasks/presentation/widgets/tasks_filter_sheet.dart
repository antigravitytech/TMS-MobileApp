part of '../tasks_screen.dart';

class _TaskFilterSheet extends StatefulWidget {
  const _TaskFilterSheet({
    required this.filters,
    required this.tasks,
    required this.place,
    required this.narrow,
  });
  final TaskFilters filters;
  final List<TaskItem> tasks;
  final String Function(TaskItem) place;
  final List<TaskItem> Function(List<TaskItem>, TaskFilters) narrow;
  @override
  State<_TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<_TaskFilterSheet> {
  late TaskPriority? p = widget.filters.priority;
  late String? j = widget.filters.place;
  late int s = widget.filters.sort;

  /// Projects, teams and task types in the loaded tab, with how each reads.
  late final places = {
    for (final t in widget.tasks) widget.place(t): taskPlaceText(context, t),
  };

  @override
  Widget build(BuildContext context) {
    final count = widget.narrow(widget.tasks, (
      priority: p,
      place: j,
      sort: s,
    )).length;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: context.muted.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('tasks.sort_filter'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    p = null;
                    j = null;
                    s = 0;
                  }),
                  child: Text(
                    context.tr('tasks.reset'),
                    style: TextStyle(color: context.lavender, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DesignLabel(context.tr('tasks.sort_by')),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.background.withValues(alpha: .25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.outline),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => s = i),
                        child: AnimatedContainer(
                          duration: DesignMotion.fast,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: s == i ? context.raised : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            context.tr(_TasksScreenState.sorts[i]),
                            style: TextStyle(
                              fontSize: 13,
                              color: s == i
                                  ? context.foreground
                                  : context.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            DesignLabel(context.tr('common.priority')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, priority)
                    in TaskPriority.values.reversed.indexed)
                  _FilterChoice(
                    taskPriorityText(context, priority),
                    selected: p == priority,
                    dot: [
                      DesignColor.red,
                      const Color(0xfff59562),
                      DesignColor.amber,
                      context.muted,
                    ][i],
                    onTap: () =>
                        setState(() => p = p == priority ? null : priority),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            DesignLabel(context.tr('common.project')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChoice(
                  context.tr('common.all_projects'),
                  selected: j == null,
                  onTap: () => setState(() => j = null),
                ),
                for (final MapEntry(:key, :value) in places.entries)
                  _FilterChoice(
                    value,
                    selected: j == key,
                    onTap: () => setState(() => j = key),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            DesignButton(
              context.tr(
                'tasks.show_count_tasks',
                namedArgs: {
                  'count': NumberFormat.decimalPattern(
                    context.locale.toString(),
                  ).format(count),
                },
              ),
              onPressed: () => Navigator.pop<TaskFilters>(context, (
                priority: p,
                place: j,
                sort: s,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChoice extends StatelessWidget {
  const _FilterChoice(
    this.label, {
    required this.selected,
    required this.onTap,
    this.dot,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? context.background : context.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
