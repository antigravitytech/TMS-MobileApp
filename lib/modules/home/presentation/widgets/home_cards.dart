part of '../home_screen.dart';

const _returnColor = Color(0xfff29962);

class _HomeCaption extends StatelessWidget {
  const _HomeCaption(this.label, {this.color});
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: color ?? context.muted,
      fontSize: 12,
      height: 1.4,
      letterSpacing: 0,
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, {required this.trailing, this.count});
  final String title;
  final Widget trailing;
  final int? count;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 24),
    child: Row(
      spacing: 8,
      children: [
        Expanded(
          child: Wrap(
            spacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.2,
                ),
              ),
              if (count case final value?)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.raised,
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    NumberFormat.decimalPattern(
                      context.locale.toString(),
                    ).format(value),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );
}

class _HomeLink extends StatelessWidget {
  const _HomeLink(this.label, this.route);
  final String label;
  final TmsRoute route;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => route.open(context),
    style: TextButton.styleFrom(
      foregroundColor: context.lavender,
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 38),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontSize: 13.5, letterSpacing: 0),
    ),
    child: Text(label),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        _Dot(color, size: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    ),
  );
}

class _CardButton extends StatelessWidget {
  const _CardButton(
    this.label, {
    required this.color,
    this.background,
    this.border,
    this.icon,
    required this.onPressed,
  });
  final String label;
  final Color color;
  final Color? background, border;
  final IconData? icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: color,
      backgroundColor: background,
      minimumSize: const Size(0, 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      side: border == null ? null : BorderSide(color: border!),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        if (icon case final glyph?) Icon(glyph, size: 16),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}

class _DueTask extends StatelessWidget {
  const _DueTask({required this.task, required this.open});
  final PreviewTask task;
  final VoidCallback open;
  @override
  Widget build(BuildContext context) => DesignCard(
    onTap: open,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Row(
          spacing: 8,
          children: [
            _StatusBadge(
              taskStatusLabel(context, task.status),
              taskStatusColor(task.status),
            ),
            Expanded(
              child: Row(
                spacing: 5,
                children: [
                  const Icon(TmsIcons.flag, size: 14, color: _returnColor),
                  Flexible(
                    child: Text(
                      taskPriorityLabel(context, task.priority),
                      style: const TextStyle(
                        color: _returnColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _HomeCaption(task.id),
          ],
        ),
        Text(
          task.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        Row(
          spacing: 8,
          children: [
            DesignAvatar(
              task.person == 'Ibrahim' ? 'IM' : _initials(task.person),
              size: 28,
              color: const Color(0xffa3c8f1),
            ),
            Expanded(
              child: _HomeCaption(
                context.tr(
                  'home.task_source',
                  namedArgs: {
                    'person': assigneeLabel(context, task.person),
                    'project': taskProjectLabel(context, task.project),
                  },
                ),
              ),
            ),
            _HomeCaption(
              taskDueLabel(context, task.due),
              color: DesignColor.amber,
            ),
          ],
        ),
      ],
    ),
  );
}

String _initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part.characters.first.toUpperCase())
    .join();

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({super.key, required this.task, required this.onApprove});
  final PreviewTask task;
  final VoidCallback onApprove;
  @override
  Widget build(BuildContext context) {
    final color = switch (task.id) {
      'TK-133' => DesignColor.amber,
      'TK-158' => DesignColor.rose,
      _ => const Color(0xff86d6cb),
    };
    final detail = switch (task.id) {
      'TK-133' => context.plural('home.waiting_hours', 20, name: 'count'),
      'TK-142' => context.tr('home.round_2_now'),
      _ => context.tr('approvals.just_now').toLowerCase(),
    };
    return DesignCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 12,
        children: [
          Row(
            spacing: 12,
            children: [
              DesignAvatar(_initials(task.person), size: 36, color: color),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _HomeCaption('${task.person} · $detail'),
                  ],
                ),
              ),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: _CardButton(
                  context.tr('common.return'),
                  color: _returnColor,
                  border: _returnColor.withValues(alpha: .45),
                  onPressed: () => TmsRoute.approvals.open(context),
                ),
              ),
              Expanded(
                child: _CardButton(
                  context.tr('common.approve'),
                  color: DesignColor.ink,
                  background: DesignColor.green,
                  icon: TmsIcons.check,
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
