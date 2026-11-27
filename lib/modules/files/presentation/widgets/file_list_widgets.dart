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

/// "240 KB" or "2.3 MB".
String _size(int bytes) => bytes < 1024 * 1024
    ? '${(bytes / 1024).round()} KB'
    : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onTap});
  final FileItem file;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toUpperCase()
        : '';
    final color = switch (file.kind) {
      FileKind.pdf => const Color(0xffeeabb0),
      FileKind.image => const Color(0xff86d6cb),
      FileKind.video => const Color(0xffa3c8f1),
      FileKind.document => const Color(0xffc4bdf6),
    };
    return InkWell(
      onTap: onTap,
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
                maxLines: 1,
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
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    file.taskTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: context.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.tr(
                      'files.metadata',
                      namedArgs: {
                        'owner': file.uploader,
                        'date': DateFormat(
                          'd MMM',
                          context.locale.toString(),
                        ).format(file.createdAt),
                        'size': _size(file.size),
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
