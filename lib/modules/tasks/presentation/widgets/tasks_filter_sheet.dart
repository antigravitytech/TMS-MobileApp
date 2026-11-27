part of '../tasks_screen.dart';

class _TaskFilterSheet extends StatefulWidget {
  const _TaskFilterSheet({
    required this.priority,
    required this.project,
    required this.sort,
    required this.tasks,
  });
  final int priority, project, sort;
  final List<PreviewTask> tasks;
  @override
  State<_TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<_TaskFilterSheet> {
  late int p = widget.priority, j = widget.project, s = widget.sort;
  @override
  Widget build(BuildContext context) {
    final count = widget.tasks
        .where(
          (t) =>
              (p == 0 || t.priority == _TasksScreenState.priorities[p]) &&
              (j == 0 || t.project == _TasksScreenState.projects[j]),
        )
        .length;
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
                    p = 0;
                    j = 0;
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
                for (var i = 1; i < 5; i++)
                  _FilterChoice(
                    taskPriorityLabel(context, _TasksScreenState.priorities[i]),
                    selected: p == i,
                    dot: [
                      DesignColor.red,
                      const Color(0xfff59562),
                      DesignColor.amber,
                      context.muted,
                    ][i - 1],
                    onTap: () => setState(() => p = p == i ? 0 : i),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            DesignLabel(context.tr('common.project')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in [0, 3, 4, 1, 2])
                  _FilterChoice(
                    i == 0
                        ? context.tr('common.all_projects')
                        : taskProjectLabel(
                            context,
                            _TasksScreenState.projects[i],
                          ),
                    selected: j == i,
                    onTap: () => setState(() => j = i),
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
              onPressed: () => Navigator.pop(context, (p, j, s)),
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
