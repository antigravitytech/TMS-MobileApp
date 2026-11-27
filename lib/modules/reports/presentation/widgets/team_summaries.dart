part of '../reports_screen.dart';

/// Who sent today's report, with what they did and what blocks them.
class _TeamSummaries extends StatefulWidget {
  const _TeamSummaries(this.team);
  final TeamReports team;
  @override
  State<_TeamSummaries> createState() => _TeamSummariesState();
}

class _TeamSummariesState extends State<_TeamSummaries> {
  final nudged = <String>{};

  @override
  Widget build(BuildContext context) {
    final team = widget.team;
    final total = team.people.length;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [Color(0xff203750), Color(0xff242445), Color(0xff44478d)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  'reports.today_named',
                  namedArgs: {'name': team.title},
                ),
                style: TextStyle(color: context.lavender, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  context.tr(
                    'reports.sent_of',
                    namedArgs: {'n': '${team.sent}', 'total': '$total'},
                  ),
                  if (team.blockers > 0)
                    context.plural('reports.blocker_count', team.blockers),
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: total == 0 ? 0 : team.sent / total,
                minHeight: 6,
                color: context.foreground,
                backgroundColor: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final person in team.people)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DesignCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DesignAvatar(
                        kitPerson(person.name).$1,
                        color: kitPerson(person.name).$2,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              person.detail.isNotEmpty
                                  ? person.detail
                                  : context.tr(
                                      person.sent
                                          ? 'reports.report_in'
                                          : 'reports.no_summary',
                                    ),
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: context.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (person.sent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (person.late
                                        ? DesignColor.amber
                                        : DesignColor.green)
                                    .withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '•  ${context.tr(person.late ? 'reports.late' : 'common.on_time')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: person.late
                                  ? DesignColor.amber
                                  : DesignColor.green,
                            ),
                          ),
                        )
                      else if (team.canNudge)
                        OutlinedButton(
                          onPressed: nudged.contains(person.name)
                              ? null
                              : () {
                                  setState(() => nudged.add(person.name));
                                  designToast(
                                    context,
                                    context.tr(
                                      'reports.reminder_sent_to_name',
                                      namedArgs: {'name': person.name},
                                    ),
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.foreground,
                            side: BorderSide(color: context.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            context.tr(
                              nudged.contains(person.name)
                                  ? 'reports.sent'
                                  : 'reports.nudge',
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (person.done.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      context.tr(
                        'reports.done_line',
                        namedArgs: {'text': person.done},
                      ),
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                  if (person.blockers.isNotEmpty &&
                      person.blockers.toLowerCase() != 'none') ...[
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        'reports.blocker_line',
                        namedArgs: {'text': person.blockers},
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: DesignColor.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
