part of '../search_screen.dart';

/// One row: what it shows and what tapping it does.
class _SearchItem {
  const _SearchItem(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.open,
  );
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback open;
}

/// Tones cycle within each group, as in the design.
const _taskTones = [DesignColor.blue, DesignColor.amber];
const _projectTones = [DesignColor.rose, DesignColor.amber];
const _personTones = [DesignColor.teal, DesignColor.purple];

Color _tone(List<Color> tones, int i) => tones[i % tones.length];

String _taskDetail(BuildContext context, SearchTask hit) =>
    hit.detailKey != null
    ? context.tr(hit.detailKey!)
    : [
        hit.task.reference,
        taskStatusText(context, hit.task.status),
      ].where((s) => s.isNotEmpty).join(' · ');

String _projectDetail(BuildContext context, SearchProject hit) =>
    hit.detailKey != null
    ? context.tr(hit.detailKey!)
    : context.tr(
        'search.project_detail',
        namedArgs: {
          'health': context.tr('projects.${hit.project.health.code}'),
          'progress': '${hit.project.progress}',
        },
      );

String _personDetail(BuildContext context, SearchPerson p) =>
    p.detailKey != null
    ? context.tr(p.detailKey!)
    : [p.jobTitle, p.team].where((s) => s.isNotEmpty).join(' · ');

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
  const _Group(this.label, this.items);
  final String label;
  final List<_SearchItem> items;
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
                _ResultRow(items[i]),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.item);
  final _SearchItem item;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: item.open,
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
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
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
