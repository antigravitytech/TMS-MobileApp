part of '../teams_screen.dart';

class _TeamCaption extends StatelessWidget {
  const _TeamCaption(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      color: context.muted,
      height: 1.4,
      letterSpacing: 0,
    ),
  );
}

/// A team's colour, from its `#rrggbb` code.
Color _teamColor(String hex) => Color(
  int.tryParse('ff${hex.replaceFirst('#', '')}', radix: 16) ?? 0xff6658c0,
);

class _TeamCard extends ConsumerWidget {
  const _TeamCard({
    required this.team,
    required this.expanded,
    required this.onOpen,
    required this.toggle,
    required this.open,
  });
  final TeamItem team;
  final bool expanded;

  /// Called when the card shows its members, so they stay loaded.
  final VoidCallback onOpen;
  final VoidCallback toggle;
  final ValueChanged<TeamMember> open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _teamColor(team.color);
    if (expanded) onOpen();
    final members = expanded ? ref.watch(teamMembersProvider(team)) : null;
    return DesignCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: expanded,
            button: true,
            child: InkWell(
              onTap: toggle,
              borderRadius: BorderRadius.circular(14),
              child: Row(
                spacing: 12,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      border: Border.all(color: color.withValues(alpha: .2)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(TmsIcons.people, color: color, size: 22),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _TeamCaption(
                          context.plural(
                            'teams.lead_members',
                            team.memberCount,
                            name: 'count',
                            namedArgs: {'lead': team.lead},
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? .25 : 0,
                    duration: DesignMotion.duration(context, DesignMotion.fast),
                    child: Icon(
                      TmsIcons.chevronNext,
                      color: context.muted,
                      size: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            spacing: 8,
            children: [
              Expanded(child: _TeamCaption(context.tr('teams.this_week'))),
              Text(
                context.tr(
                  'teams.complete',
                  namedArgs: {
                    'progress': NumberFormat.decimalPattern(
                      context.locale.toString(),
                    ).format(team.progress),
                  },
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: team.progress / 100,
            minHeight: 6,
            backgroundColor: context.raised,
            color: DesignColor.purple,
            borderRadius: BorderRadius.circular(8),
          ),
          AnimatedSize(
            duration: DesignMotion.duration(context, DesignMotion.page),
            curve: DesignMotion.curve,
            alignment: Alignment.topCenter,
            child: members == null
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: context.outline.withValues(alpha: .08),
                      ),
                      const SizedBox(height: 4),
                      if (members.value case final rows?)
                        for (final member in rows) _MemberRow(member, open)
                      else if (members.hasError)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextButton(
                            onPressed: () =>
                                ref.invalidate(teamMembersProvider(team)),
                            child: Text(context.tr('workspaces.try_again')),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow(this.member, this.open);
  final TeamMember member;
  final ValueChanged<TeamMember> open;
  @override
  Widget build(BuildContext context) {
    final (initials, color) = kitPerson(member.name);
    return InkWell(
      onTap: () => open(member),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          spacing: 12,
          children: [
            DesignAvatar(initials, color: color, size: 36),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _TeamCaption(
                    member.lead
                        ? [
                            context.tr('teams.team_lead'),
                            if (member.title.isNotEmpty) member.title,
                          ].join(' · ')
                        : context.tr('common.member'),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.raised,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _TeamCaption(
                context.tr(
                  'teams.open_count',
                  namedArgs: {
                    'count': NumberFormat.decimalPattern(
                      context.locale.toString(),
                    ).format(member.open),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
