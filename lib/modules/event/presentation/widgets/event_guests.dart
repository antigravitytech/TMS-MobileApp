import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';
import '../../../workspace/application/local_workspaces.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/kit_controls.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import 'event_guest_import.dart';
import '../../../workspace/presentation/widgets/workspace_ui.dart';
import '../../application/event_controller.dart';
import 'event_guest_page.dart';

Color rsvpTone(BuildContext c, WorkspaceStatus s) => switch (s) {
  WorkspaceStatus.confirmed => KitColor.done,
  WorkspaceStatus.maybe => KitColor.submitted,
  WorkspaceStatus.pending => KitColor.progress,
  WorkspaceStatus.declined => KitColor.overdue,
  _ => c.muted,
};

class EventGuests extends ConsumerWidget {
  const EventGuests({
    super.key,
    required this.view,
    required this.state,
    required this.actions,
  });
  final EventView view;
  final EventState state;
  final EventController actions;

  Future<void> _import(BuildContext c, WidgetRef ref) async {
    final guests = await designSheet<List<WorkspaceRecord>>(
      c,
      title: c.tr('workspaces.import_guests'),
      builder: (_) => const GuestImportForm(),
    );
    if (guests == null || !c.mounted) return;
    await saveWorkspaceChange(
      c,
      () => ref
          .read(localWorkspacesProvider.notifier)
          .importGuests(view.space.id, guests),
    );
  }

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final door = state.door;
    final list = view.guests
        .where((g) => state.filter == null || g.status == state.filter)
        .where((g) => !door || g.status == WorkspaceStatus.confirmed)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        KitSegment<bool>(
          values: const [false, true],
          selected: door,
          label: (d) => c.tr(d ? 'event.door' : 'event.guest_list'),
          onChanged: actions.door,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final s in [
                null,
                ...rsvpOrder.where((s) => s != WorkspaceStatus.notInvited),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: KitChip(
                      label: s == null
                          ? c.tr('common.all')
                          : c.tr('event.rsvp.${s.name}'),
                      count: s == null ? view.guests.length : view.count(s),
                      selected: state.filter == s,
                      onTap: () => actions.filter(s),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (door) ...[
          const SizedBox(height: 12),
          KitCard(
            color: c.dark ? const Color(0xff2a2846) : null,
            child: Row(
              spacing: 12,
              children: [
                Text(
                  '${view.checkedIn}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: Text(
                    c.tr(
                      'event.checked_in_of',
                      namedArgs: {'n': '${view.seatsConfirmed}'},
                    ),
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (list.isEmpty)
          const SpecialEmpty('guests')
        else
          KitList(
            children: [
              for (final g in list)
                _GuestRow(
                  key: ValueKey(g.id),
                  guest: g,
                  door: door,
                  onTap: !door
                      ? null
                      : () async {
                          final arrived = c.tr(
                            'event.checked_in',
                            namedArgs: {
                              'name': g.title,
                              'table': g.group.isEmpty
                                  ? c.tr('event.no_table')
                                  : g.group,
                            },
                          );
                          final ok = await actions.toggleCheckIn(g);
                          if (ok && !g.checkedIn && c.mounted) {
                            designToast(c, arrived);
                          }
                        },
                ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: DesignButton(
                c.tr('event.import'),
                secondary: true,
                onPressed: () => _import(c, ref),
              ),
            ),
            Expanded(
              child: DesignButton(
                c.tr('event.share_rsvp'),
                onPressed: () => showGuestPage(c, view.space.id),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `.gst` row: avatar, name ×party, side · meal · table and the reply.
class _GuestRow extends StatelessWidget {
  const _GuestRow({
    super.key,
    required this.guest,
    required this.door,
    required this.onTap,
  });
  final WorkspaceRecord guest;
  final bool door;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext c) {
    final g = guest;
    final (initials, color) = kitPerson(g.title);
    final meta = [
      g.fields['side'] ?? '',
      g.fields['meal'] ?? '',
      g.group,
    ].where((s) => s.isNotEmpty).join(' · ');
    final (label, tone) = door
        ? (
            c.tr(g.checkedIn ? 'event.status_in' : 'event.status_expected'),
            g.checkedIn ? KitColor.done : c.muted,
          )
        : (c.tr('event.rsvp.${g.status.name}'), rsvpTone(c, g.status));
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignMotion.fast,
        color: door && g.checkedIn
            ? KitColor.done.withValues(alpha: .1)
            : Colors.transparent,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            DesignAvatar(initials, size: 36, color: color),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: g.title,
                      children: [
                        TextSpan(
                          text: ' ×${g.duration < 1 ? 1 : g.duration}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (meta.isNotEmpty)
                    Text(meta, style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
            ),
            KitPop(key: ValueKey(label), child: KitStatus(label, tone)),
          ],
        ),
      ),
    );
  }
}
