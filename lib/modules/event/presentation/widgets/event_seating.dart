import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/event_controller.dart';
import 'event_floor.dart';

class EventSeating extends StatelessWidget {
  const EventSeating({
    super.key,
    required this.view,
    required this.state,
    required this.actions,
  });
  final EventView view;
  final EventState state;
  final EventController actions;
  @override
  Widget build(BuildContext c) {
    final unseated = view.unseated;
    final picked = view.guests.where((g) => g.id == state.pick).firstOrNull;
    final peek = view.tables.where((t) => t.title == state.peek).firstOrNull;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '${view.seated} ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  children: [
                    TextSpan(
                      text: c.tr(
                        'event.seats_filled',
                        namedArgs: {
                          'n': '${view.capacity}',
                          'tables': '${view.tables.length}',
                        },
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
            KitMiniButton(
              c.tr('event.auto_seat'),
              onPressed: () async {
                final n = unseated.length;
                final msg = n == 0
                    ? c.tr('event.all_seated_toast')
                    : c.plural('event.auto_seated', n);
                final ok = await actions.autoSeat();
                if (c.mounted) {
                  designToast(c, ok ? msg : c.tr('workspaces.try_again'));
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          picked == null
              ? c.tr('event.seat_hint')
              : c.tr('event.seat_now', namedArgs: {'name': picked.title}),
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: unseated.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: KitStatus(
                    c.tr('event.everyone_seated'),
                    KitColor.done,
                  ),
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final g in unseated)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _Chair(
                          guest: g,
                          on: g.id == state.pick,
                          onTap: () => actions.pickGuest(g.id),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        EventFloor(
          view: view,
          targeting: picked != null,
          onTable: (t) async {
            if (picked == null) return actions.peekTable(t.title);
            final done = c.tr(
              'event.seated_at',
              namedArgs: {'name': picked.title, 'table': t.title},
            );
            final full = c.tr('event.table_full');
            final ok = await actions.seatPicked(t.title);
            if (c.mounted) designToast(c, ok ? done : full);
          },
        ),
        const SizedBox(height: 10),
        Text(
          c.tr('event.floor_hint'),
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
        if (peek != null) ...[
          const SizedBox(height: 10),
          KitPop(
            key: ValueKey(peek.title),
            child: KitCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.tr(
                      'event.peek',
                      namedArgs: {
                        'table': peek.title,
                        'n': '${view.seatedAt(peek.title)}',
                        'seats': '${peek.duration}',
                      },
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(() {
                    final who = view.guests
                        .where((g) => g.group == peek.title)
                        .map((g) => g.title)
                        .join(', ');
                    return who.isEmpty ? c.tr('event.nobody') : who;
                  }(), style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// `.chairs` pill for a guest who still needs a seat.
class _Chair extends StatelessWidget {
  const _Chair({required this.guest, required this.on, required this.onTap});
  final WorkspaceRecord guest;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final (initials, color) = kitPerson(guest.title);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignMotion.fast,
        height: 40,
        padding: const EdgeInsets.fromLTRB(5, 0, 12, 0),
        decoration: BoxDecoration(
          color: on ? const Color(0xff2a2846) : c.panel,
          border: Border.all(color: on ? DesignColor.purple : c.outline),
          borderRadius: BorderRadius.circular(999),
          boxShadow: on
              ? const [BoxShadow(color: Color(0x2e9184d9), spreadRadius: 3)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            DesignAvatar(initials, size: 30, color: color),
            Text(
              '${guest.title} ×${guest.duration < 1 ? 1 : guest.duration}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
