part of '../search_screen.dart';

class _SearchItem {
  const _SearchItem(
    this.titleKey,
    this.subtitleKey,
    this.icon,
    this.color,
    this.route, {
    this.rawTitle = false,
    this.task,
  });
  final String titleKey, subtitleKey;
  final IconData icon;
  final Color color;
  final TmsRoute route;
  final bool rawTitle;
  final PreviewTask? task;
  String title(BuildContext context) =>
      rawTitle ? titleKey : context.tr(titleKey);
  String subtitle(BuildContext context) => context.tr(subtitleKey);
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: context.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group(this.label, this.items, this.preview);
  final String label;
  final List<_SearchItem> items;
  final WorkspacePreview preview;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        Container(
          decoration: BoxDecoration(
            color: context.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: context.outline,
                  ),
                _ResultRow(items[i], preview),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.item, this.preview);
  final _SearchItem item;
  final WorkspacePreview preview;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {
      if (item.task != null) preview.selectTask(item.task!);
      item.route.open(context);
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: item.color.withValues(alpha: .22)),
            ),
            child: Icon(item.icon, size: 19, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(TmsIcons.chevronNext, size: 17, color: context.muted),
        ],
      ),
    ),
  );
}
