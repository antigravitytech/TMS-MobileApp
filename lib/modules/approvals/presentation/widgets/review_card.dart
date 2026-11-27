part of '../approvals_screen.dart';

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.task,
    required this.dx,
    required this.onOpen,
  });
  final PreviewTask task;
  final double dx;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      DesignCard(
        padding: const EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              spacing: 10,
              children: [
                DesignAvatar(
                  task.person.split(' ').map((name) => name[0]).take(2).join(),
                  color: DesignColor.teal,
                  size: 46,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DesignTitle(task.person),
                      DesignLabel('${task.project} · ${task.id}'),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.18,
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ReviewChip(
                  context.tr('common.submitted'),
                  color: DesignColor.amber,
                ),
                _ReviewChip(
                  context.tr(
                    task.id == 'TK-142'
                        ? 'approvals.round_2'
                        : 'approvals.round_1',
                  ),
                ),
                _ReviewChip(
                  context.tr('approvals.just_now'),
                  icon: TmsIcons.clock,
                ),
              ],
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.raised,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('“${task.note}”'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  _ReviewChip(
                    context.tr('approvals.2_files'),
                    icon: TmsIcons.attachment,
                  ),
                  TextButton(
                    onPressed: onOpen,
                    child: Text(context.tr('approvals.open_task_link')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (dx.abs() > 10)
        Positioned(
          top: 20,
          left: dx > 0 ? 18 : null,
          right: dx < 0 ? 18 : null,
          child: IgnorePointer(
            child: Opacity(
              opacity: (dx.abs() / 95).clamp(0, 1),
              child: Transform.rotate(
                angle: dx > 0 ? -.18 : .18,
                child: _ReviewChip(
                  dx > 0
                      ? context.tr('approvals.approve_swipe')
                      : context.tr('approvals.return_swipe'),
                  color: dx > 0 ? DesignColor.green : DesignColor.rose,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip(
    this.label, {
    this.selected = false,
    this.color,
    this.icon,
    this.onTap,
  });
  final String label;
  final bool selected;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? context.foreground
        : color?.withValues(alpha: .14) ?? Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(onTap == null ? 7 : 24),
      side: onTap == null
          ? BorderSide.none
          : BorderSide(color: context.outline),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: onTap == null ? 8 : 14,
          vertical: onTap == null ? 5 : 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null || color != null) ...[
              Icon(
                icon ?? TmsIcons.dot,
                size: 13,
                color: color ?? context.muted,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? context.background : color ?? context.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
