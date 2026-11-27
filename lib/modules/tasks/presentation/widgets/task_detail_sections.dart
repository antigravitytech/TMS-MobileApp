part of '../task_detail_screen.dart';

class _SmallTag extends StatelessWidget {
  const _SmallTag(this.label, this.color, {this.dot = false});
  final String label;
  final Color color;
  final bool dot;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          CircleAvatar(radius: 3, backgroundColor: color),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _PersonCard extends StatelessWidget {
  const _PersonCard(this.initials, this.name, this.role, this.color);
  final String initials, name, role;
  final Color color;
  @override
  Widget build(BuildContext context) => DesignCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color,
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: DesignColor.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role, style: TextStyle(color: context.muted, fontSize: 11)),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard(this.task);
  final PreviewTask task;
  @override
  Widget build(BuildContext context) {
    final current = switch (task.status) {
      'Completed' => 3,
      'Submitted' => 2,
      'In progress' => 1,
      _ => 0,
    };
    final steps = [
      context.tr('common.not_started'),
      context.tr('common.in_progress'),
      context.tr('common.submitted'),
      context.tr('common.completed'),
    ];
    return DesignCard(
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 32,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (i > 0)
                              Positioned(
                                left: 0,
                                right: 16,
                                child: Container(
                                  height: 2,
                                  color: i <= current
                                      ? DesignColor.purple
                                      : context.outline,
                                ),
                              ),
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: i < current
                                  ? DesignColor.purple
                                  : (i == current
                                        ? context.background
                                        : context.raised),
                              child: i < current
                                  ? const Icon(
                                      TmsIcons.check,
                                      size: 16,
                                      color: DesignColor.ink,
                                    )
                                  : i == current
                                  ? Container(
                                      width: 11,
                                      height: 11,
                                      decoration: const BoxDecoration(
                                        color: DesignColor.purple,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        steps[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: i == current
                              ? context.foreground
                              : context.muted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: context.outline, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _TargetCell(
                context.tr('tasks.original_target'),
                context.tr('tasks.original_target_date'),
                context.tr('tasks.never_changes'),
              ),
              _TargetCell(
                context.tr('tasks.current_target'),
                taskDueLabel(context, task.due),
                context.tr('tasks.on_original_date'),
                highlight: true,
              ),
              _TargetCell(
                context.tr('common.completed'),
                current == 3
                    ? context.tr('common.today')
                    : context.tr('tasks.not_yet'),
                context.tr('tasks.set_on_approval'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetCell extends StatelessWidget {
  const _TargetCell(
    this.label,
    this.value,
    this.caption, {
    this.highlight = false,
  });
  final String label, value, caption;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          style: TextStyle(fontSize: 11, color: context.muted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: highlight ? DesignColor.amber : context.foreground,
          ),
        ),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: context.muted),
        ),
      ],
    ),
  );
}
