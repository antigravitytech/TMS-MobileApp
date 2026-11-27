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

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.name,
    required this.manager,
    required this.progress,
    required this.color,
    required this.members,
    required this.expanded,
    required this.job,
    required this.toggle,
    required this.open,
  });
  final String name, manager;
  final int progress;
  final Color color;
  final List<_Member> members;
  final bool expanded;
  final String? job;
  final VoidCallback toggle;
  final ValueChanged<_Member> open;

  @override
  Widget build(BuildContext context) => DesignCard(
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
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _TeamCaption(
                        context.plural(
                          'teams.lead_members',
                          members.length,
                          name: 'count',
                          namedArgs: {'lead': manager},
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
                  ).format(progress),
                },
              ),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress / 100,
          minHeight: 6,
          backgroundColor: context.raised,
          color: DesignColor.purple,
          borderRadius: BorderRadius.circular(8),
        ),
        AnimatedSize(
          duration: DesignMotion.duration(context, DesignMotion.page),
          curve: DesignMotion.curve,
          alignment: Alignment.topCenter,
          child: expanded
              ? Column(
                  children: [
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: context.outline.withValues(alpha: .08),
                    ),
                    const SizedBox(height: 4),
                    for (final member in members)
                      InkWell(
                        onTap: () => open(member),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          child: Row(
                            spacing: 12,
                            children: [
                              DesignAvatar(
                                member.$1,
                                color: member.$4,
                                size: 36,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.$2,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    _TeamCaption(
                                      member.$6
                                          ? [
                                              context.tr('teams.team_lead'),
                                              ?job,
                                            ].join(' · ')
                                          : context.tr('common.member'),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
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
                                      ).format(member.$5),
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );
}
