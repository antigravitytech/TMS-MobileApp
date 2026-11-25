import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../application/local_workspaces.dart';
import '../domain/workspace_kind.dart';
import 'workspace_ui.dart';

/// Local preview of the guest invitation or an individual vendor's brief.
class WorkspaceEventInvitation extends ConsumerWidget {
  const WorkspaceEventInvitation({
    super.key,
    required this.workspaceId,
    this.recordId,
  });
  final String workspaceId;
  final String? recordId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(localWorkspacesProvider).asData?.value.active;
    if (w == null || w.id != workspaceId) return const SizedBox.shrink();
    final record = w.records.where((r) => r.id == recordId).firstOrNull;
    final vendor = record?.section == WorkspaceSection.vendors;
    final programme =
        w
            .items(WorkspaceSection.programme)
            .where(
              (r) => vendor
                  ? r.fields['vendor'] == record!.title
                  : r.fields['visibility'] != 'team',
            )
            .toList()
          ..sort((a, b) => a.date!.compareTo(b.date!));
    final date = w.eventDate, name = workspaceName(context, w);
    final invitation = [
      name,
      if (date != null) MaterialLocalizations.of(context).formatFullDate(date),
      if (w.eventVenue.isNotEmpty) w.eventVenue,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        DesignCard(
          color: w.kind.accent.withValues(alpha: .18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Icon(
                vendor ? TmsIcons.work : TmsIcons.celebration,
                color: w.kind.ink(context),
                size: 28,
              ),
              DesignLabel(
                context.tr(
                  vendor ? 'workspaces.vendor_brief' : 'workspaces.invited',
                ),
              ),
              DesignTitle(name),
              if (date != null)
                DesignLabel(
                  MaterialLocalizations.of(context).formatFullDate(date),
                ),
              if (w.eventVenue.isNotEmpty) DesignLabel(w.eventVenue),
            ],
          ),
        ),
        if (record != null) ...[
          DesignTitle(record.title),
          if (vendor) ...[
            if (record.fields['arrival'] case final arrival?)
              DesignLabel(
                context.tr(
                  'workspaces.arrive_by',
                  namedArgs: {'time': arrival},
                ),
              ),
            DesignLabel(
              context.tr(
                'workspaces.paid_of_total',
                namedArgs: {
                  'paid': workspaceAmount(context, record.paid),
                  'total': workspaceAmount(context, record.amount),
                },
              ),
            ),
            if (record.notes.isNotEmpty) Text(record.notes),
          ] else ...[
            DesignLabel(context.tr('workspaces.rsvp_question')),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final status in [
                  WorkspaceStatus.confirmed,
                  WorkspaceStatus.maybe,
                  WorkspaceStatus.declined,
                ])
                  DesignPill(
                    WorkspaceSection.guests.statusLabel(context, status),
                    selected: record.status == status,
                    onTap: () => saveWorkspaceChange(
                      context,
                      () => ref
                          .read(localWorkspacesProvider.notifier)
                          .respondToInvite(w.id, record.id, status),
                    ),
                  ),
              ],
            ),
            if (record.group.isNotEmpty &&
                record.status == WorkspaceStatus.confirmed)
              DesignLabel(
                context.tr(
                  'workspaces.table_name',
                  namedArgs: {'table': record.group},
                ),
              ),
          ],
        ],
        if (programme.isNotEmpty) ...[
          DesignTitle(WorkspaceSection.programme.label(context)),
          DesignSection(
            children: [
              for (final item in programme)
                DesignTile(
                  title: item.title,
                  subtitle: [
                    TimeOfDay.fromDateTime(item.date!).format(context),
                    item.group,
                  ].where((s) => s.isNotEmpty).join(' · '),
                  icon: TmsIcons.clock,
                ),
            ],
          ),
        ],
        if (!vendor)
          DesignButton(
            context.tr('workspaces.copy_invite'),
            secondary: true,
            icon: TmsIcons.copy,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: invitation.join('\n')),
              );
              if (context.mounted) {
                designToast(context, context.tr('workspaces.invite_copied'));
              }
            },
          ),
      ],
    );
  }
}
