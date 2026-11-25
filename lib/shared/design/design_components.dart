part of 'design_widgets.dart';

class DesignCard extends StatelessWidget {
  const DesignCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.onTap,
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? context.panel,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: context.outline),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class DesignTitle extends StatelessWidget {
  const DesignTitle(this.title, {super.key, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
    ],
  );
}

class DesignLabel extends StatelessWidget {
  const DesignLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: color ?? context.muted, fontSize: 13, height: 1.4),
  );
}

class DesignPill extends StatelessWidget {
  const DesignPill(
    this.label, {
    super.key,
    this.selected = false,
    this.color,
    this.onTap,
    this.icon,
  });
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: onTap != null ? selected : null,
    button: onTap != null,
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: DesignMotion.duration(context, DesignMotion.fast),
          curve: DesignMotion.curve,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          constraints: BoxConstraints(minHeight: onTap == null ? 0 : 42),
          decoration: BoxDecoration(
            color: selected
                ? DesignColor.purple.withValues(alpha: .22)
                : (color?.withValues(alpha: .13) ?? context.panel),
            border: Border.all(
              color: selected ? DesignColor.purple : context.outline,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color ?? context.lavender),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color ?? context.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DesignChoices extends StatelessWidget {
  const DesignChoices({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.scroll = true,
  });
  final List<String> items;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool scroll;
  @override
  Widget build(BuildContext context) {
    final children = [
      for (var i = 0; i < items.length; i++)
        DesignPill(
          items[i],
          selected: i == selected,
          onTap: () => onChanged(i),
        ),
    ];
    if (!scroll) return Wrap(spacing: 8, runSpacing: 8, children: children);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(spacing: 8, children: children),
    );
  }
}

class DesignAvatar extends StatelessWidget {
  const DesignAvatar(
    this.initials, {
    super.key,
    this.color = DesignColor.purple,
    this.size = 40,
  });
  final String initials;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: color,
    foregroundColor: DesignColor.ink,
    child: Text(
      initials,
      style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * .32),
    ),
  );
}

class DesignTile extends StatelessWidget {
  const DesignTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.color,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading, trailing;
  final VoidCallback? onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) => ListTile(
    minVerticalPadding: 10,
    leading:
        leading ??
        (icon == null
            ? null
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (color ?? DesignColor.purple).withValues(alpha: .19),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color ?? context.lavender, size: 20),
              )),
    title: Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    subtitle: subtitle == null ? null : DesignLabel(subtitle!),
    trailing:
        trailing ??
        (onTap == null
            ? null
            : Icon(TmsIcons.chevronNext, color: context.muted)),
    onTap: onTap,
  );
}

class DesignSection extends StatelessWidget {
  const DesignSection({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => DesignCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: context.outline,
            ),
          children[i],
        ],
      ],
    ),
  );
}
