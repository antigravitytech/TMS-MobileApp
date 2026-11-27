import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../bills/presentation/widgets/bills_widgets.dart' show naira;
import '../../../specials/presentation/widgets/special_widgets.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/dated_row.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/event_controller.dart';
import 'event_guest_page.dart';
import 'event_hero.dart';

class EventOverview extends StatelessWidget {
  const EventOverview({super.key, required this.view, required this.onTab});
  final EventView view;
  final ValueChanged<EventTab> onTab;
  @override
  Widget build(BuildContext c) {
    final space = view.space;
    final info = view.info;
    final date = space.eventDate;
    final locale = c.locale.toString();
    final rsvpBy = DateTime.tryParse(info?.fields['rsvpBy'] ?? '');
    final budget = space.eventBudget;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        if (date != null)
          DesignEntrance(
            child: EventHero(
              days: daysUntil(date, view.today),
              hosts: info?.fields['hosts'] ?? '',
              title: info?.title ?? space.name,
              line: [
                DateFormat.MMMEd(locale).format(date),
                DateFormat.jm(locale).format(date).toLowerCase(),
                if (space.eventVenue.isNotEmpty) space.eventVenue,
              ].join(' · '),
              style: info?.fields['style'] ?? '',
              onShare: () => showGuestPage(c, space.id),
            ),
          ),
        const SizedBox(height: 12),
        DesignEntrance(
          order: 1,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                _Stat(
                  label: c.tr('event.seats_confirmed'),
                  value: '${view.seatsConfirmed}',
                  suffix: space.eventCapacity > 0
                      ? ' / ${space.eventCapacity}'
                      : '',
                  sub: c.tr(
                    rsvpBy == null ? 'event.awaiting' : 'event.awaiting_by',
                    namedArgs: {
                      'n': '${view.awaiting}',
                      'date': rsvpBy == null
                          ? ''
                          : DateFormat.MMMd(locale).format(rsvpBy),
                    },
                  ),
                  onTap: () => onTab(EventTab.guests),
                ),
                _Stat(
                  label: c.tr('event.budget_used'),
                  value: budget == 0
                      ? '–'
                      : '${(view.committed * 100 / budget).round()}%',
                  sub: c.tr(
                    'event.budget_line',
                    namedArgs: {
                      'committed': specialMoney(c, view.committed),
                      'budget': specialMoney(c, budget),
                      'paid': specialMoney(c, view.paid),
                    },
                  ),
                  onTap: () => onTab(EventTab.vendors),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        DesignEntrance(order: 2, child: _RsvpCard(view: view)),
        if (view.dueSoon.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
            child: Text(
              c.tr('event.due_soon').toUpperCase(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: c.muted,
              ),
            ),
          ),
          KitList(
            children: [
              for (final v in view.dueSoon)
                DatedRow(
                  key: ValueKey(v.id),
                  date: v.date!,
                  title: v.title,
                  trailing: Text(
                    naira(c, v.outstanding),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => onTab(EventTab.vendors),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// `.kpi` with the label first, as on the Event overview.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.sub,
    required this.onTap,
    this.suffix = '',
  });
  final String label, value, suffix, sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: KitCard(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: c.muted,
              ),
            ),
            Text.rich(
              TextSpan(
                text: value,
                children: [
                  TextSpan(
                    text: suffix,
                    style: TextStyle(fontSize: 15, color: c.muted),
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 26,
                height: 1,
                letterSpacing: -.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(sub, style: TextStyle(fontSize: 12, color: c.muted)),
          ],
        ),
      ),
    ),
  );
}

/// RSVP progress: a segmented bar and a count per reply.
class _RsvpCard extends StatelessWidget {
  const _RsvpCard({required this.view});
  final EventView view;
  @override
  Widget build(BuildContext c) {
    Color tone(WorkspaceStatus s) => switch (s) {
      WorkspaceStatus.confirmed => KitColor.done,
      WorkspaceStatus.maybe => KitColor.submitted,
      WorkspaceStatus.pending => KitColor.progress,
      WorkspaceStatus.declined => KitColor.overdue,
      _ => c.dark ? const Color(0xff3f424d) : const Color(0xffd5d8e6),
    };
    return KitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.tr('event.rsvp_progress'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 2,
                children: [
                  for (final s in rsvpOrder)
                    if (view.count(s) > 0)
                      Expanded(
                        flex: view.count(s),
                        child: ColoredBox(color: tone(s)),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final s in rsvpOrder)
                Text.rich(
                  TextSpan(
                    text: '${view.count(s)} ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(
                        text: c.tr('event.rsvp_count.${s.name}'),
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
