part of '../projects_screen.dart';

Color _healthColor(ProjectHealth health) => switch (health) {
  ProjectHealth.offTrack => DesignColor.red,
  ProjectHealth.atRisk => DesignColor.amber,
  ProjectHealth.onTrack => DesignColor.green,
};

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    super.key,
    required this.project,
    required this.open,
    required this.onToggle,
  });
  final ProjectItem project;
  final bool open;
  final VoidCallback onToggle;

  /// "Next promise · Discovery · 19 working days late", or its due date.
  String _promise(BuildContext context) {
    final m = project.milestone;
    if (m == null) return context.tr('projects.no_milestone');
    final late = m.workingDaysLate(DateTime.now());
    if (late > 0) {
      return context.tr(
        'projects.promise_summary',
        namedArgs: {'milestone': m.name, 'days': '$late'},
      );
    }
    return context.tr(
      'projects.next_promise_due',
      namedArgs: {'due': '${m.name} · ${_day(context, m.due)}'},
    );
  }

  static String _day(BuildContext context, DateTime date) =>
      DateFormat('d MMM', context.locale.toString()).format(date);

  @override
  Widget build(BuildContext context) {
    final color = _healthColor(project.health);
    final milestone = project.milestone;
    final (initials, avatar) = kitPerson(project.owner);
    return DesignCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 9,
        children: [
          InkWell(
            onTap: onToggle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('projects.${project.health.code}'),
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (project.mode case final mode?) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: context.raised,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          context.tr('projects.modes.${mode.toLowerCase()}'),
                          style: TextStyle(color: context.muted, fontSize: 12),
                        ),
                      ),
                    ],
                    const Spacer(),
                    DesignAvatar(initials, size: 28, color: avatar),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _promise(context),
                  style: TextStyle(color: context.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            spacing: 14,
            children: [
              Expanded(
                child: _Metric(
                  context.tr('projects.tasks_done'),
                  project.progress,
                  DesignColor.purple,
                ),
              ),
              Expanded(
                child: _Metric(
                  context.tr('projects.accepted'),
                  project.accepted,
                  DesignColor.teal,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: DesignMotion.duration(context, DesignMotion.page),
            curve: DesignMotion.curve,
            child: !open
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      Divider(height: 18, color: context.outline),
                      if (milestone != null)
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: DesignColor.blue.withValues(alpha: .13),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: DesignColor.blue.withValues(alpha: .3),
                                ),
                              ),
                              child: const Icon(
                                TmsIcons.flag,
                                size: 20,
                                color: DesignColor.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(
                                      'projects.milestone_named',
                                      namedArgs: {'name': milestone.name},
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    milestone.forecast == null
                                        ? context.tr(
                                            'projects.milestone_promised_due',
                                            namedArgs: {
                                              'due': _day(
                                                context,
                                                milestone.due,
                                              ),
                                            },
                                          )
                                        : context.tr(
                                            'projects.promised_forecast',
                                            namedArgs: {
                                              'due': _day(
                                                context,
                                                milestone.due,
                                              ),
                                              'forecast': _day(
                                                context,
                                                milestone.forecast!,
                                              ),
                                            },
                                          ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      Row(
                        spacing: 6,
                        children: [
                          for (final (label, route) in [
                            (context.tr('common.tasks'), TmsRoute.tasks),
                            (context.tr('common.files'), TmsRoute.files),
                            (context.tr('common.chat'), TmsRoute.conversation),
                          ])
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => route.open(context),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: context.raised,
                                  foregroundColor: context.foreground,
                                  minimumSize: const Size(0, 48),
                                  padding: EdgeInsets.zero,
                                  side: BorderSide(color: context.outline),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
