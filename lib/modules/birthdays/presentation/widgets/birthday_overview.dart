part of '../birthdays_screen.dart';

/// This month: who is celebrating today (including me), then the next 30
/// days.
class _BirthdayOverview extends StatelessWidget {
  const _BirthdayOverview({
    required this.calendar,
    required this.me,
    required this.dateOf,
    required this.onSend,
    required this.onCelebrate,
  });
  final BirthdayCalendar calendar;
  final String me;
  final DateTime Function(int daysAway) dateOf;
  final ValueChanged<BirthdayPerson> onSend;
  final ValueChanged<BirthdayEntry> onCelebrate;

  Widget heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 14),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: context.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  );

  /// "Family · turns 64 · loves ofada rice" for a calendar entry.
  static String entryDetails(BuildContext context, BirthdayEntry entry) => [
    context.tr('birthdays.relations.${entry.relation}'),
    if (entry.turning != null)
      context.plural('birthdays.turns', entry.turning!),
    if (entry.note.isNotEmpty) entry.note,
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final members = calendar.members.where((p) => p.isToday).toList();
    final entries = calendar.entries.where((e) => e.isToday).toList();
    final today =
        members.length + entries.length + (calendar.mineIsToday ? 1 : 0);
    final soon = [
      for (final p in calendar.members)
        if (p.daysAway > 0 && p.daysAway <= 30)
          (p.name, p.daysAway, p.jobTitle),
      for (final e in calendar.entries)
        if (e.daysAway > 0 && e.daysAway <= 30)
          (e.name, e.daysAway, entryDetails(context, e)),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    if (today == 0 && soon.isEmpty) {
      return DesignEmpty(
        context.tr('birthdays.nothing_to_celebrate_this_month'),
        context.tr('birthdays.choose_another_month'),
        icon: TmsIcons.birthday,
      );
    }
    final locale = context.locale.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (today > 0)
          heading(
            context,
            context.tr('birthdays.today_count', namedArgs: {'n': '$today'}),
          ),
        for (final p in members) ...[
          _TodayBirthday(
            initials: kitPerson(p.name).$1,
            name: p.name,
            subtitle: p.jobTitle,
            color: kitPerson(p.name).$2,
            action: context.tr(
              p.iWished ? 'birthdays.card_sent_label' : 'common.send_a_card',
            ),
            complete: p.iWished,
            onTap: () => onSend(p),
          ),
          const SizedBox(height: 12),
        ],
        for (final e in entries) ...[
          _TodayBirthday(
            initials: kitPerson(e.name).$1,
            name: e.name,
            subtitle: entryDetails(context, e),
            color: DesignColor.amber,
            action: context.tr(
              e.celebrated ? 'birthdays.wished' : 'birthdays.mark_as_wished',
            ),
            complete: e.celebrated,
            onTap: () => onCelebrate(e),
          ),
          const SizedBox(height: 12),
        ],
        if (calendar.mineIsToday) ...[
          _TodayBirthday(
            initials: kitPerson(me).$1,
            name: context.tr('birthdays.you'),
            subtitle: context.tr('birthdays.expect_cards'),
            color: const Color(0xffc4bdf6),
            action: context.plural(
              'birthdays.cards_count',
              calendar.wishesReceived,
            ),
            complete: true,
            highlighted: true,
            onTap: () => designSheet<void>(
              context,
              title: context.plural(
                'birthdays.cards_count',
                calendar.wishesReceived,
              ),
              builder: (_) => DesignLabel(context.tr('birthdays.expect_cards')),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (soon.isNotEmpty) ...[
          heading(context, context.tr('birthdays.coming_up')),
          DesignCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, (name, away, subtitle)) in soon.indexed) ...[
                  if (i > 0) Divider(height: 1, color: context.outline),
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
                                  locale,
                                ).format(dateOf(away)).toUpperCase(),
                                style: TextStyle(
                                  color: context.lavender,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                DateFormat.d(locale).format(dateOf(away)),
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
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: context.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          away < 14
                              ? context.plural('birthdays.in_days', away)
                              : context.plural('birthdays.in_weeks', away ~/ 7),
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
      ],
    );
  }
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
