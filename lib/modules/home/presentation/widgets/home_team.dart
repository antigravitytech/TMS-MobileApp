part of '../home_screen.dart';

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.state});
  final WorkspacePreview state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    child: Row(
      spacing: 10,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeCaption(context.tr('common.monday_23_november')),
              Text(
                state.workspace,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -.4,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            DesignIcon(
              icon: TmsIcons.notifications,
              label: context.tr('common.notifications'),
              onPressed: () => TmsRoute.notifications.open(context),
            ),
            if (state.readNotifications.length < 6)
              const Positioned(
                top: 10,
                right: 11,
                child: IgnorePointer(child: _Dot(DesignColor.red, size: 6)),
              ),
          ],
        ),
        Tooltip(
          message: context.tr('home.my_profile'),
          child: InkWell(
            onTap: () => TmsRoute.profile.open(context),
            borderRadius: BorderRadius.circular(22),
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DesignAvatar(
                      [state.firstName, state.lastName]
                          .where((name) => name.isNotEmpty)
                          .map((name) => name.characters.first.toUpperCase())
                          .join(),
                      size: 40,
                      color: const Color(0xffc4bdf6),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -1,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: DesignColor.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.background,
                            width: 3,
                          ),
                        ),
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
  );
}

class _TeamSummary extends StatelessWidget {
  const _TeamSummary();
  @override
  Widget build(BuildContext context) => DesignCard(
    padding: const EdgeInsets.all(16),
    onTap: () => TmsRoute.reports.open(context),
    child: Row(
      spacing: 14,
      children: [
        SizedBox(
          width: 66,
          height: 28,
          child: Stack(
            children: [
              for (final (index, (initial, color)) in const [
                ('TB', Color(0xff86d6cb)),
                ('DM', Color(0xffbcd995)),
                ('+3', Color(0xffb2b6ca)),
              ].indexed)
                Positioned(
                  left: 19.0 * index,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.panel,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: DesignAvatar(initial, size: 24, color: color),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('home.team_summary_count'),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _HomeCaption(
                context.tr('home.blocker_count'),
                color: _returnColor,
              ),
            ],
          ),
        ),
        Icon(TmsIcons.chevronNext, color: context.muted, size: 16),
      ],
    ),
  );
}

class _ComingUp extends StatelessWidget {
  const _ComingUp({required this.task, required this.open});
  final PreviewTask task;
  final VoidCallback open;
  @override
  Widget build(BuildContext context) {
    final date = DateTime(2026, 11, 25);
    final locale = context.locale.toString();
    return DesignCard(
      padding: const EdgeInsets.all(16),
      onTap: open,
      child: Row(
        spacing: 14,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  DateFormat.E(locale).format(date).toUpperCase(),
                  style: TextStyle(
                    color: context.lavender,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  DateFormat.d(locale).format(date),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _HomeCaption(
                  '${taskProjectLabel(context, task.project)} · ${task.id} · ${taskPriorityLabel(context, task.priority)}',
                ),
              ],
            ),
          ),
          _StatusBadge(taskStatusLabel(context, task.status), context.muted),
        ],
      ),
    );
  }
}
