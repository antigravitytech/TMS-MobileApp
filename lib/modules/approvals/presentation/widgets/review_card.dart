part of '../approvals_screen.dart';

/// "Just now", "3h ago" or "2d ago" since the task was submitted.
String _ago(BuildContext context, DateTime? at) {
  if (at == null) return context.tr('approvals.just_now');
  final age = DateTime.now().difference(at);
  if (age.inMinutes < 1) return context.tr('approvals.just_now');
  if (age.inHours < 1) {
    return context.tr(
      'approvals.minutes_ago',
      namedArgs: {'n': '${age.inMinutes}'},
    );
  }
  if (age.inDays < 1) {
    return context.tr(
      'approvals.hours_ago',
      namedArgs: {'n': '${age.inHours}'},
    );
  }
  return context.tr('approvals.days_ago', namedArgs: {'n': '${age.inDays}'});
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({
    required this.task,
    required this.dx,
    required this.onOpen,
  });
  final TaskItem task;
  final double dx;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = task.assignee?.name ?? '';
    final note = ref.watch(reviewNoteProvider(task)).value ?? '';
    return Stack(
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
                    kitPerson(person).$1,
                    color: kitPerson(person).$2,
                    size: 46,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DesignTitle(person),
                        DesignLabel(
                          '${taskPlaceText(context, task)} · ${task.reference}',
                        ),
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
                      'tasks.round',
                      namedArgs: {'n': '${task.round < 1 ? 1 : task.round}'},
                    ),
                  ),
                  _ReviewChip(
                    _ago(context, task.submittedAt),
                    icon: TmsIcons.clock,
                  ),
                ],
              ),
              if (note.isNotEmpty)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.raised,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('“$note”'),
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
                      context.plural('approvals.files_count', task.fileCount),
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
