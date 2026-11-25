part of 'design_widgets.dart';

class DesignTabs extends StatelessWidget {
  const DesignTabs({
    super.key,
    required this.active,
    required this.items,
    this.onSelect,
    this.activeLabel,
  });
  final void Function(DesignTab tab)? onSelect;
  final String? activeLabel;
  final TmsRoute active;
  final List<DesignTab> items;
  static const companyTabs = <DesignTab>[
    (TmsRoute.home, 'common.home', TmsIcons.dashboard, 0),
    (TmsRoute.tasks, 'navigation.my_tasks', TmsIcons.checkSquare, 0),
    (TmsRoute.chat, 'common.chat', TmsIcons.chat, 11),
    (TmsRoute.approvals, 'navigation.approvals', TmsIcons.checkCircle, 3),
    (TmsRoute.more, 'common.more', TmsIcons.more, 0),
  ];
  @override
  Widget build(BuildContext context) => Material(
    color: context.dark ? const Color(0xff12131e) : Colors.white,
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 24),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            children: [
              for (final (route, label, icon, badge) in items)
                Expanded(
                  child: Semantics(
                    selected:
                        (route == active &&
                        (activeLabel == null || activeLabel == label)),
                    button: true,
                    child: InkWell(
                      onTap: () {
                        if (onSelect != null) {
                          onSelect!((route, label, icon, badge));
                        } else {
                          route.open(context);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _TabGlyph(
                                  key: ValueKey((
                                    route,
                                    (route == active &&
                                        (activeLabel == null ||
                                            activeLabel == label)),
                                  )),
                                  icon: icon,
                                  active:
                                      (route == active &&
                                      (activeLabel == null ||
                                          activeLabel == label)),
                                ),
                                if (badge > 0)
                                  Positioned(
                                    top: -2,
                                    right: 1,
                                    child: Badge(
                                      label: Text('$badge'),
                                      backgroundColor: route == TmsRoute.chat
                                          ? DesignColor.red
                                          : DesignColor.amber,
                                      textColor: DesignColor.ink,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              context.tr(label),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color:
                                    (route == active &&
                                        (activeLabel == null ||
                                            activeLabel == label))
                                    ? context.foreground
                                    : context.muted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            AnimatedOpacity(
                              duration: DesignMotion.duration(
                                context,
                                DesignMotion.fast,
                              ),
                              opacity:
                                  (route == active &&
                                      (activeLabel == null ||
                                          activeLabel == label))
                                  ? 1
                                  : 0,
                              child: CircleAvatar(
                                radius: 2.5,
                                backgroundColor: context.lavender,
                              ),
                            ),
                          ],
                        ),
                      ),
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

/// The design's active pill expands horizontally as its icon lifts and tilts.
class _TabGlyph extends StatelessWidget {
  const _TabGlyph({super.key, required this.icon, required this.active});
  final IconData icon;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final glyph = Icon(
      icon,
      size: active ? 21 : 20,
      color: active ? context.lavender : context.muted,
    );
    if (!active) return SizedBox(width: 50, height: 32, child: glyph);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: DesignMotion.duration(
        context,
        const Duration(milliseconds: 600),
      ),
      child: glyph,
      builder: (context, t, child) {
        final rise = t < .35
            ? Curves.easeOut.transform(t / .35)
            : 1 - Curves.easeOut.transform((t - .35) / .65);
        final width = Curves.easeOutBack.transform((t / .92).clamp(0.0, 1.0));
        return SizedBox(
          width: 50,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scaleX: .4 + .6 * width,
                child: Container(
                  decoration: BoxDecoration(
                    color: DesignColor.purple.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -5 * rise),
                child: Transform.rotate(angle: -.14 * rise, child: child),
              ),
            ],
          ),
        );
      },
    );
  }
}
