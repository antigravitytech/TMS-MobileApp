part of '../task_forms.dart';

class _TaskChip extends StatelessWidget {
  const _TaskChip(
    this.label, {
    this.selected = false,
    this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? context.foreground : Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: selected ? context.foreground : context.outline),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? context.background : context.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TaskPrivacy extends StatelessWidget {
  const _TaskPrivacy({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  Widget tile(BuildContext context, IconData icon) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: context.raised,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: context.outline),
    ),
    child: Icon(icon, size: 20, color: context.lavender),
  );
  @override
  Widget build(BuildContext context) => DesignCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              tile(context, TmsIcons.lock),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('tasks.confidential'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.tr(
                        'tasks.only_the_assignee_assigner_and_watchers',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: context.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => onChanged(!value),
                child: Semantics(
                  label: context.tr('tasks.confidential'),
                  toggled: value,
                  child: AnimatedContainer(
                    duration: DesignMotion.fast,
                    width: 52,
                    height: 32,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: value
                          ? DesignColor.purple
                          : context.foreground.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AnimatedAlign(
                      duration: DesignMotion.fast,
                      alignment: value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: context.foreground,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.outline),
        InkWell(
          onTap: () => TmsRoute.files.open(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                tile(context, TmsIcons.attachment),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('tasks.attach_files'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(TmsIcons.chevronNext, size: 16, color: context.muted),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Standalone, Project, Team or Recurring.
class _TaskTypeSwitch extends StatelessWidget {
  const _TaskTypeSwitch({required this.type, required this.onChanged});
  final TaskType type;
  final ValueChanged<TaskType> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: context.panel,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.outline),
    ),
    child: Row(
      children: [
        for (final t in TaskType.values)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t),
              child: AnimatedContainer(
                duration: DesignMotion.fast,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: type == t ? context.raised : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  child: Text(
                    taskTypeText(context, t),
                    style: TextStyle(
                      fontSize: 12,
                      color: type == t ? context.foreground : context.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
