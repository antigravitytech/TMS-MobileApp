part of '../task_detail_screen.dart';

class _TaskTabs extends StatelessWidget {
  const _TaskTabs(this.selected, this.onSelect);
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    final labels = [
      context.tr('tasks.activity'),
      context.tr('tasks.comments'),
      context.tr('common.files'),
      context.tr('tasks.details'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.panel,
        border: Border.all(color: context.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: DesignMotion.duration(context, DesignMotion.fast),
                  curve: DesignMotion.curve,
                  height: 39,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == i ? context.raised : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected == i
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected == i ? context.foreground : context.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.submitted});
  final bool submitted;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (submitted)
        _ActivityRow(
          'CO',
          DesignColor.purple,
          context.tr('tasks.you_submitted_for_review'),
          context.tr('tasks.just_now'),
        ),
      _ActivityRow(
        'CO',
        DesignColor.purple,
        context.tr('tasks.chioma_started_work'),
        context.tr('tasks.started_at'),
      ),
      _ActivityRow(
        'IM',
        DesignColor.blue,
        context.tr('tasks.ibrahim_created_task'),
        context.tr('tasks.created_at'),
      ),
    ],
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.initials, this.color, this.title, this.time);
  final String initials, title, time;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color,
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: DesignColor.ink,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 3),
              Text(time, style: TextStyle(fontSize: 11, color: context.muted)),
            ],
          ),
        ),
      ],
    ),
  );
}
