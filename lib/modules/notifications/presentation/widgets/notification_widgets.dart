part of '../notifications_screen.dart';

class _NotificationFilter extends StatelessWidget {
  const _NotificationFilter({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedInk = context.dark ? DesignColor.ink : Colors.white;
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: DesignMotion.duration(context, DesignMotion.fast),
        decoration: ShapeDecoration(
          color: selected ? context.foreground : Colors.transparent,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? context.foreground : context.outline,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 38),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                spacing: 7,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? selectedInk : context.muted,
                      letterSpacing: 0,
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected ? selectedInk : context.raised,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      NumberFormat.decimalPattern(
                        context.locale.toString(),
                      ).format(count),
                      style: TextStyle(
                        color: context.foreground,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadToggle extends StatelessWidget {
  const _UnreadToggle({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('notifications.unread_only'),
              style: TextStyle(
                color: context.muted,
                fontSize: 13.5,
                letterSpacing: 0,
              ),
            ),
            AnimatedContainer(
              duration: DesignMotion.duration(context, DesignMotion.fast),
              width: 52,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: selected
                    ? DesignColor.purple
                    : context.dark
                    ? const Color(0xff3f424d)
                    : const Color(0xffd5d8e6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedAlign(
                duration: DesignMotion.duration(
                  context,
                  const Duration(milliseconds: 300),
                ),
                curve: DesignMotion.curve,
                alignment: selected
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xffe9e9ed),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.unread,
    required this.onTap,
  });
  final NotificationPreview item;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, badge) = switch (item.kind) {
      NotificationKind.review => (TmsIcons.check, DesignColor.amber),
      NotificationKind.mention => (TmsIcons.mention, DesignColor.purple),
      NotificationKind.birthday => (TmsIcons.add, DesignColor.rose),
    };
    final avatar = switch (item.initials) {
      'TB' => const Color(0xff86d6cb),
      'AE' => const Color(0xffeeabb0),
      'DM' => const Color(0xffbcd995),
      _ => DesignColor.amber,
    };
    final age = item.ageMinutes;
    final time = age == null
        ? context.tr('notifications.just_now')
        : context.plural(
            age < 60
                ? 'notifications.minutes_ago_compact'
                : 'notifications.hours_ago_compact',
            age < 60 ? age : age ~/ 60,
            name: 'count',
          );
    return _NotificationTile(
      initials: item.initials,
      avatar: avatar,
      icon: icon,
      badge: badge,
      message: context.tr('notifications.${item.message}'),
      time: time,
      unread: unread,
      onTap: onTap,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    super.key,
    required this.initials,
    required this.avatar,
    required this.icon,
    required this.badge,
    required this.message,
    required this.time,
    required this.unread,
    required this.onTap,
  });

  final String initials, message, time;
  final Color avatar, badge;
  final IconData icon;
  final bool unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(18));
    return AnimatedContainer(
      duration: DesignMotion.duration(
        context,
        const Duration(milliseconds: 400),
      ),
      decoration: BoxDecoration(
        color: unread ? const Color(0x149184d9) : Colors.transparent,
        borderRadius: radius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DesignAvatar(initials, color: avatar, size: 36),
                    PositionedDirectional(
                      end: -4,
                      bottom: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: badge,
                          border: Border.all(
                            color: context.background,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(icon, color: DesignColor.ink, size: 11),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          letterSpacing: 0,
                        ),
                      ),
                      Text(
                        time,
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
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: AnimatedScale(
                    scale: unread ? 1 : 0,
                    duration: DesignMotion.duration(context, DesignMotion.page),
                    child: const CircleAvatar(
                      radius: 4.5,
                      backgroundColor: DesignColor.purple,
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
}
