import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../router/tms_routes.dart';
import '../design/design_tokens.dart';
import '../design/tms_icons.dart';

/// Shared building blocks for the Family prototype screens (`tms.css`).
abstract final class KitColor {
  static const done = DesignColor.green;
  static const progress = DesignColor.blue;
  static const submitted = DesignColor.amber;
  static const overdue = DesignColor.red;
  static const tick = Color(0xff5fd3c4);

  /// Avatar fills `.a1`–`.a8`.
  static const avatars = [
    Color(0xffc4bdf6),
    Color(0xff86d6cb),
    Color(0xffeccb84),
    Color(0xffeeabb0),
    Color(0xffa3c8f1),
    Color(0xffbcd995),
    Color(0xffd8b4ec),
    Color(0xffb2b6ca),
  ];
  static Color avatar(int n) => avatars[(n - 1) % avatars.length];
}

/// Initials and avatar fill for a household member's first name.
(String, Color) kitPerson(String name) {
  const known = {
    'Ibrahim': ('IM', 2),
    'Funmi': ('FI', 4),
    'Tobi': ('TI', 3),
    'Ada': ('AI', 6),
    'Bisi': ('BO', 7),
    'Kwame': ('KM', 5),
    'Sule': ('SG', 8),
    // Victory Chapel's workers.
    'Dayo': ('DC', 3),
    'Chinwe': ('CE', 4),
    'Ade': ('AB', 1),
    'Grace': ('GO', 6),
    'Emeka': ('EO', 5),
  };
  final first = name.trim().split(' ').first;
  // Couples ("Chinwe & Dayo") take both initials, not one person's.
  final hit = name.contains('&') ? null : known[first];
  if (hit != null) return (hit.$1, KitColor.avatar(hit.$2));
  final initials = name
      .trim()
      .split(RegExp(r'\s+'))
      // Skip joiners like "&" so "Ngozi & Tunde" reads NT.
      .where(
        (p) => p.isNotEmpty && RegExp(r'^\p{L}', unicode: true).hasMatch(p),
      )
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();
  // A stable colour per name, so a list of people isn't all one shade.
  final shade = name.codeUnits.fold(0, (a, b) => a + b) % 8 + 1;
  return (initials.isEmpty ? '?' : initials, KitColor.avatar(shade));
}

/// Spring curve used by chips, ticks and cheer buttons.
const kitSpring = Cubic(.34, 1.56, .64, 1);

/// Square outlined `.icon-btn`; [primary] gives the filled add button.
class KitIconButton extends StatelessWidget {
  const KitIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.primary = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool primary;
  @override
  Widget build(BuildContext c) => SizedBox.square(
    dimension: 44,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: primary ? DesignColor.purple : c.panel,
        side: primary ? BorderSide.none : BorderSide(color: c.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(
        icon,
        size: 20,
        color: primary ? DesignColor.ink : c.foreground,
      ),
    ),
  );
}

/// `.top` header: optional back button, title with a subtitle, trailing action.
class KitHeader extends StatelessWidget {
  const KitHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.back,
    this.action,
    this.large = false,
  });
  final String title, subtitle;
  final String? back;
  final Widget? action;

  /// Tab screens put the workspace name above a 26px title.
  final bool large;
  @override
  Widget build(BuildContext c) {
    final small = Text(
      subtitle,
      style: TextStyle(fontSize: 12, color: c.muted),
    );
    final heading = Text(
      title,
      style: TextStyle(
        fontSize: large ? 26 : 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -.4,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        spacing: 10,
        children: [
          if (back != null)
            KitIconButton(
              icon: TmsIcons.chevronBack,
              tooltip: back!,
              onPressed: () => kitBack(c),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: large ? [small, heading] : [heading, small],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Pops to the caller, or returns Home when the screen was opened directly.
void kitBack(BuildContext context) {
  final router = context.router;
  router.canPop() ? router.maybePop() : router.replacePath(TmsRoute.home.path);
}

/// `.chip` pill with an optional `.n` count; selected chips pop in.
class KitChip extends StatelessWidget {
  const KitChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.compact = false,
  });
  final String label;
  final bool selected, compact;
  final int? count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final chip = Material(
      color: selected ? c.foreground : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? c.foreground : c.outline),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: compact ? 32 : 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 7,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 12.5 : 13.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? c.background : c.foreground,
                ),
              ),
              if (count != null)
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? c.background : c.raised,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: c.foreground,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return selected ? KitPop(key: ValueKey(label), child: chip) : chip;
  }
}

/// Horizontally scrolling `.mtabs` row of chips.
class KitTabs extends StatelessWidget {
  const KitTabs({super.key, required this.children, this.padding = 20});
  final List<Widget> children;
  final double padding;
  @override
  Widget build(BuildContext c) => SizedBox(
    height: 42,
    // Built eagerly: tab rows are short, and every tab stays reachable.
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(spacing: 8, children: children),
    ),
  );
}

/// `.mini-btn`, raised by default or filled when [primary].
class KitMiniButton extends StatelessWidget {
  const KitMiniButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.primary = false,
  });
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  @override
  Widget build(BuildContext c) => SizedBox(
    height: 36,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: primary ? DesignColor.purple : c.raised,
        foregroundColor: primary ? DesignColor.ink : c.foreground,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
        side: BorderSide(color: primary ? DesignColor.purple : c.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: Theme.of(c).textTheme.labelLarge?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    ),
  );
}

/// `chipOn` spring pop: 0.88 → 1.06 → 1 over 400ms.
class KitPop extends StatelessWidget {
  const KitPop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext c) {
    if (MediaQuery.disableAnimationsOf(c)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .88, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: kitSpring,
      child: child,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
    );
  }
}

/// `.tag` pill: a short label such as an agenda point or a gig detail.
class KitTag extends StatelessWidget {
  const KitTag(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext c) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      color: c.raised,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: c.muted,
          ),
        ),
      ],
    ),
  );
}

/// Small rounded count, as beside a section title.
class KitCount extends StatelessWidget {
  const KitCount(this.n, {super.key});
  final int n;
  @override
  Widget build(BuildContext c) => Container(
    constraints: const BoxConstraints(minWidth: 22),
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 7),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: c.raised,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      '$n',
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
