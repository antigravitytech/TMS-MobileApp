part of '../birthdays_screen.dart';

class _BirthdayOverview extends StatelessWidget {
  const _BirthdayOverview({
    required this.sent,
    required this.onSend,
    required this.onWish,
  });
  final Set<String> sent;
  final ValueChanged<String> onSend;
  final VoidCallback onWish;
  Widget heading(BuildContext context, String key) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 14),
    child: Text(
      context.tr(key).toUpperCase(),
      style: TextStyle(
        color: context.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading(context, 'birthdays.today_3'),
      _TodayBirthday(
        initials: 'TB',
        name: 'Tunde Bakare',
        subtitle: context.tr('birthdays.tech_team_colleague'),
        color: const Color(0xff86d6cb),
        action: context.tr(
          sent.contains('Tunde Bakare')
              ? 'birthdays.card_sent_label'
              : 'common.send_a_card',
        ),
        complete: sent.contains('Tunde Bakare'),
        onTap: () => onSend('Tunde Bakare'),
      ),
      const SizedBox(height: 12),
      _TodayBirthday(
        initials: 'MB',
        name: 'Mama Bisi',
        subtitle: context.tr('birthdays.mama_bisi_details'),
        color: DesignColor.amber,
        action: context.tr(
          sent.contains('Mama Bisi')
              ? 'birthdays.wished'
              : 'birthdays.mark_as_wished',
        ),
        complete: sent.contains('Mama Bisi'),
        onTap: onWish,
      ),
      const SizedBox(height: 12),
      _TodayBirthday(
        initials: 'CO',
        name: context.tr('birthdays.you'),
        subtitle: context.tr('birthdays.expect_cards'),
        color: const Color(0xffc4bdf6),
        action: context.tr('birthdays.three_cards'),
        complete: true,
        highlighted: true,
        onTap: () => designSheet<void>(
          context,
          title: context.tr('birthdays.three_cards'),
          builder: (_) => DesignLabel(context.tr('birthdays.expect_cards')),
        ),
      ),
      const SizedBox(height: 12),
      heading(context, 'birthdays.coming_up'),
      DesignCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final (name, date, subtitle, remaining) in [
              (
                'Amaka Eze',
                DateTime(2026, 11, 26),
                'birthdays.colleague',
                'birthdays.in_three_days',
              ),
              (
                'Chidi Okeke',
                DateTime(2026, 11, 26),
                'birthdays.friend_turns_36',
                'birthdays.in_three_days',
              ),
              (
                'David Mensah',
                DateTime(2026, 12, 2),
                'birthdays.colleague',
                'birthdays.in_nine_days',
              ),
              (
                'Ngozi Adeyemi',
                DateTime(2026, 12, 14),
                'birthdays.colleague',
                'birthdays.in_three_weeks',
              ),
            ]) ...[
              if (name != 'Amaka Eze')
                Divider(height: 1, color: context.outline),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          Text(
                            DateFormat.MMM(
                              context.locale.toString(),
                            ).format(date).toUpperCase(),
                            style: TextStyle(
                              color: context.lavender,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            DateFormat.d(
                              context.locale.toString(),
                            ).format(date),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(subtitle),
                            style: TextStyle(
                              color: context.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      context.tr(remaining),
                      style: TextStyle(color: context.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _TodayBirthday extends StatelessWidget {
  const _TodayBirthday({
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.action,
    required this.complete,
    required this.onTap,
    this.highlighted = false,
  });
  final String initials, name, subtitle, action;
  final Color color;
  final bool complete, highlighted;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: highlighted
          ? DesignColor.purple.withValues(alpha: .17)
          : context.panel,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(
        color: highlighted
            ? DesignColor.purple.withValues(alpha: .45)
            : context.outline,
      ),
    ),
    child: Row(
      children: [
        DesignAvatar(initials, size: 52, color: color),
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
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: highlighted ? context.lavender : context.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (complete)
          OutlinedButton(
            onPressed: highlighted ? onTap : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.foreground,
              disabledForegroundColor: context.foreground,
              backgroundColor: context.raised,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              side: BorderSide(color: context.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              action,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          )
        else
          DesignButton(action, onPressed: onTap),
      ],
    ),
  );
}
