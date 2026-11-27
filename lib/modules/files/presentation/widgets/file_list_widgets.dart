part of '../files_screen.dart';

class _FileChip extends StatelessWidget {
  const _FileChip(
    this.label, {
    required this.onTap,
    this.selected = false,
    this.dropdown = false,
    this.icon,
  });
  final String label;
  final VoidCallback onTap;
  final bool selected, dropdown;
  final IconData? icon;
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
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: context.muted),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? context.background : context.muted,
              ),
            ),
            if (dropdown) ...[
              const SizedBox(width: 10),
              Icon(TmsIcons.chevronDown, size: 14, color: context.muted),
            ],
          ],
        ),
      ),
    ),
  );
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.name,
    required this.owner,
    required this.category,
  });
  final String name, owner, category;
  @override
  Widget build(BuildContext context) {
    final ext = name.split('.').last.toUpperCase();
    final color = switch (ext) {
      'PDF' => const Color(0xffeeabb0),
      'PNG' => const Color(0xff86d6cb),
      'MP4' => const Color(0xffa3c8f1),
      _ => const Color(0xffc4bdf6),
    };
    final (task, date, size) = switch (name) {
      'webhook-retry-tests.pdf' => (
        'files.webhook_task',
        DateTime(2026, 11, 23),
        '240 KB',
      ),
      'form-errors.png' => (
        'files.errors_task',
        DateTime(2026, 11, 23),
        '420 KB',
      ),
      'usability-findings.pdf' => (
        'files.usability_task',
        DateTime(2026, 11, 22),
        '2.3 MB',
      ),
      'session-3-clip.mp4' => (
        'files.usability_task',
        DateTime(2026, 11, 22),
        '48.0 MB',
      ),
      'checkout-step2.png' => (
        'files.checkout_task',
        DateTime(2026, 11, 19),
        '640 KB',
      ),
      'retry-sequence.png' => (
        'files.webhook_task',
        DateTime(2026, 11, 17),
        '1.1 MB',
      ),
      _ => ('files.checkout_task', DateTime(2026, 11, 16), '3.4 MB'),
    };
    return InkWell(
      onTap: () => TmsRoute.task.open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ext,
                style: const TextStyle(
                  color: DesignColor.ink,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.tr(task),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: context.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.tr(
                      'files.metadata',
                      namedArgs: {
                        'owner': owner,
                        'date': DateFormat(
                          'd MMM',
                          context.locale.toString(),
                        ).format(date),
                        'size': size,
                      },
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.muted.withValues(alpha: .7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(TmsIcons.download, size: 16, color: context.muted),
          ],
        ),
      ),
    );
  }
}
