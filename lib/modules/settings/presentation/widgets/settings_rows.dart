part of '../settings_screen.dart';

class _SettingsHeading extends StatelessWidget {
  const _SettingsHeading(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        color: context.muted,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => DesignCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0)
            Divider(height: 1, color: context.outline.withValues(alpha: .08)),
          child,
        ],
      ],
    ),
  );
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.icon, this.color);
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      border: Border.all(color: color.withValues(alpha: .22)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, size: 20, color: color),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    this.detail,
    this.leading,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? detail;
  final Widget? leading, trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        spacing: 12,
        children: [
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                if (detail case final sub?)
                  Text(
                    sub,
                    style: TextStyle(
                      color: context.muted,
                      fontSize: 12,
                      height: 1.4,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
          if (onTap != null)
            Icon(TmsIcons.chevronNext, size: 15, color: context.muted),
        ],
      ),
    ),
  );
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    toggled: value,
    child: InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 52,
        height: 40,
        child: Center(
          child: AnimatedContainer(
            duration: DesignMotion.duration(context, DesignMotion.fast),
            height: 32,
            width: 52,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value
                  ? DesignColor.purple
                  : context.dark
                  ? const Color(0xff3f424d)
                  : const Color(0xffd5d8e6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedAlign(
              duration: DesignMotion.duration(context, DesignMotion.fast),
              curve: DesignMotion.curve,
              alignment: value
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xffe9e9ed),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66000000),
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: SizedBox.square(dimension: 26),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ThemeSegments extends StatelessWidget {
  const _ThemeSegments({required this.mode, required this.select});
  final ThemeMode mode;
  final ValueChanged<ThemeMode> select;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: context.panel,
      border: Border.all(color: context.outline),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      spacing: 4,
      children: [
        for (final option in _SettingsScreenState.modes)
          Expanded(
            child: Semantics(
              selected: mode == option,
              child: AnimatedContainer(
                duration: DesignMotion.duration(context, DesignMotion.fast),
                decoration: BoxDecoration(
                  color: mode == option ? context.raised : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    foregroundColor: mode == option
                        ? context.foreground
                        : context.muted,
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 13.5,
                      letterSpacing: 0,
                    ),
                  ),
                  onPressed: () => select(option),
                  child: Text(context.tr('settings.${option.name}')),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
