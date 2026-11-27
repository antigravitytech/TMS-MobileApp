part of '../reports_screen.dart';

class _TeamSummaries extends StatelessWidget {
  const _TeamSummaries({required this.nudged, required this.onNudge});
  final Set<String> nudged;
  final ValueChanged<String> onNudge;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
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
              context.tr('reports.today_tech_team'),
              style: TextStyle(color: context.lavender, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('common.2_of_5_sent_1_blocker'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: .4,
              minHeight: 6,
              color: context.foreground,
              backgroundColor: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      for (final (initials, name, color, detail, done) in [
        ('TB', 'Tunde', DesignColor.teal, 'reports.tunde_summary', true),
        ('DM', 'David', const Color(0xffbcd995), 'reports.david_summary', true),
        ('AE', 'Amaka', const Color(0xffeeabb0), 'reports.no_summary', false),
        ('SJ', 'Sarah', DesignColor.amber, 'reports.no_summary', false),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DesignCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DesignAvatar(initials, color: color, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(detail),
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
                    if (done)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (name == 'Tunde'
                                      ? DesignColor.green
                                      : DesignColor.amber)
                                  .withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '•  ${context.tr(name == 'Tunde' ? 'common.on_time' : 'reports.late')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: name == 'Tunde'
                                ? DesignColor.green
                                : DesignColor.amber,
                          ),
                        ),
                      )
                    else
                      OutlinedButton(
                        onPressed: nudged.contains(name)
                            ? null
                            : () => onNudge(name),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.foreground,
                          side: BorderSide(color: context.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          context.tr(
                            nudged.contains(name)
                                ? 'reports.sent'
                                : 'reports.nudge',
                          ),
                        ),
                      ),
                  ],
                ),
                if (done) ...[
                  const SizedBox(height: 14),
                  Text(
                    context.tr(
                      name == 'Tunde'
                          ? 'reports.tunde_done'
                          : 'reports.david_done',
                    ),
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
                if (name == 'Tunde') ...[
                  const SizedBox(height: 8),
                  Text(
                    context.tr('reports.tunde_blocker'),
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
