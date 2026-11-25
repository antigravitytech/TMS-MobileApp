import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../application/local_workspaces.dart';
import '../domain/event_seating.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import 'workspace_ui.dart';
import 'workspace_floor_plan.dart';

class WorkspaceSeatingList extends ConsumerStatefulWidget {
  const WorkspaceSeatingList({
    super.key,
    required this.workspace,
    required this.editGuest,
    required this.openGuests,
  });
  final LocalWorkspace workspace;
  final ValueChanged<WorkspaceRecord> editGuest;
  final VoidCallback openGuests;

  @override
  ConsumerState<WorkspaceSeatingList> createState() =>
      _WorkspaceSeatingListState();
}

class _WorkspaceSeatingListState extends ConsumerState<WorkspaceSeatingList> {
  LocalWorkspace get workspace => widget.workspace;
  bool floor = false;

  Future<void> addTable(BuildContext context, WidgetRef ref) async {
    final table = await designSheet<WorkspaceRecord>(
      context,
      title: context.tr('workspaces.add_table'),
      builder: (_) => _TableForm(workspace: workspace),
    );
    if (context.mounted && table != null) {
      await saveWorkspaceChange(
        context,
        () => ref
            .read(localWorkspacesProvider.notifier)
            .saveRecord(workspace.id, table),
      );
    }
  }

  Future<void> moveGuest(
    BuildContext context,
    WidgetRef ref,
    WorkspaceRecord guest,
    Iterable<String> tables,
  ) async {
    final table = await designSheet<String>(
      context,
      title: guest.title,
      builder: (context) => Column(
        children: [
          for (final t in ['', ...tables.where((t) => t.isNotEmpty)])
            ListTile(
              title: Text(
                t.isEmpty
                    ? context.tr('workspaces.unassigned')
                    : context.tr(
                        'workspaces.table_name',
                        namedArgs: {'table': t},
                      ),
              ),
              enabled: workspace.canSeat(t, guest),
              trailing: t == guest.group
                  ? const Icon(TmsIcons.checkCircle)
                  : null,
              onTap: () => Navigator.pop(context, t),
            ),
        ],
      ),
    );
    if (context.mounted && table != null) {
      await saveWorkspaceChange(
        context,
        () => ref
            .read(localWorkspacesProvider.notifier)
            .seatGuest(workspace.id, guest.id, table),
      );
    }
  }

  Future<void> removeTable(
    BuildContext context,
    WidgetRef ref,
    WorkspaceRecord table,
  ) async {
    final remove = await designSheet<bool>(
      context,
      title: context.tr('workspaces.remove_table'),
      builder: (context) => Column(
        spacing: 12,
        children: [
          DesignLabel(
            context.tr(
              'workspaces.remove_table_hint',
              namedArgs: {'name': table.title},
            ),
          ),
          DesignButton(
            context.tr('workspaces.remove'),
            color: DesignColor.rose,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (context.mounted && remove == true) {
      await saveWorkspaceChange(
        context,
        () => ref
            .read(localWorkspacesProvider.notifier)
            .removeTable(workspace.id, table.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tables = {
      for (final r in workspace.items(WorkspaceSection.seating)) r.title: r,
    };
    final groups = <String, List<WorkspaceRecord>>{
      for (final name in tables.keys) name: [],
    };
    for (final g in workspace.arrivingGuests) {
      (groups[g.group] ??= []).add(g);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DesignPill(
              context.tr('workspaces.add_table'),
              icon: TmsIcons.add,
              onTap: () => addTable(context, ref),
            ),
            if (tables.isNotEmpty && (groups[''] ?? []).isNotEmpty)
              DesignPill(
                context.tr('workspaces.auto_seat'),
                icon: TmsIcons.seat,
                onTap: () async {
                  final count =
                      workspace
                          .autoSeat()
                          .where(
                            (r) =>
                                r.section == WorkspaceSection.guests &&
                                r.group.isNotEmpty,
                          )
                          .length -
                      workspace
                          .items(WorkspaceSection.guests)
                          .where((r) => r.group.isNotEmpty)
                          .length;
                  if (count == 0) {
                    designToast(
                      context,
                      context.tr('workspaces.no_table_fits'),
                    );
                    return;
                  }
                  await saveWorkspaceChange(
                    context,
                    () => ref
                        .read(localWorkspacesProvider.notifier)
                        .autoSeatGuests(workspace.id),
                  );
                },
              ),
          ],
        ),
        if (groups.keys.any((t) => t.isNotEmpty))
          DesignChoices(
            items: [
              context.tr('workspaces.tables'),
              context.tr('workspaces.floor_plan'),
            ],
            selected: floor ? 1 : 0,
            onChanged: (i) => setState(() => floor = i == 1),
          ),
        if (floor && groups.keys.any((t) => t.isNotEmpty))
          WorkspaceFloorPlan(
            tables: tables,
            guests: groups,
            onMove: (table, pos) async {
              await saveWorkspaceChange(
                context,
                () => ref
                    .read(localWorkspacesProvider.notifier)
                    .updateRecord(
                      workspace.id,
                      table.id,
                      (r) => r.copyWith(
                        fields: {
                          ...r.fields,
                          'x': pos.dx.toString(),
                          'y': pos.dy.toString(),
                        },
                      ),
                    ),
              );
            },
            onSelect: (table) async {
              final guest = await designSheet<WorkspaceRecord>(
                context,
                title: context.tr(
                  'workspaces.table_name',
                  namedArgs: {'table': table},
                ),
                builder: (context) => Column(
                  children: [
                    for (final r in workspace.arrivingGuests)
                      ListTile(
                        title: Text(r.title),
                        subtitle: Text(
                          context.plural(
                            'workspaces.seat_count',
                            r.duration,
                            name: 'count',
                          ),
                        ),
                        trailing: r.group == table
                            ? const Icon(TmsIcons.checkCircle)
                            : null,
                        enabled:
                            r.group == table || workspace.canSeat(table, r),
                        onTap: () => Navigator.pop(context, r),
                      ),
                  ],
                ),
              );
              if (context.mounted && guest != null) {
                await saveWorkspaceChange(
                  context,
                  () => ref
                      .read(localWorkspacesProvider.notifier)
                      .seatGuest(
                        workspace.id,
                        guest.id,
                        guest.group == table ? '' : table,
                      ),
                );
              }
            },
          ),
        if (groups.isEmpty)
          DesignEmpty(
            context.tr('workspaces.no_confirmed_guests'),
            context.tr('workspaces.confirm_for_seating'),
            icon: TmsIcons.seat,
          ),
        for (final entry in groups.entries.where(
          (e) => !floor || e.key.isEmpty,
        ))
          DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DesignTitle(
                        entry.key.isEmpty
                            ? context.tr('workspaces.unassigned')
                            : context.tr(
                                'workspaces.table_name',
                                namedArgs: {'table': entry.key},
                              ),
                      ),
                    ),
                    if (tables[entry.key] case final table?)
                      IconButton(
                        tooltip: context.tr('workspaces.remove_table'),
                        icon: const Icon(TmsIcons.removeCircle),
                        onPressed: () => removeTable(context, ref, table),
                      ),
                  ],
                ),
                if (tables[entry.key] case final table?) ...[
                  DesignLabel(
                    context.plural(
                      'workspaces.free_seats',
                      table.duration - workspace.seatsTaken(entry.key),
                      name: 'count',
                    ),
                  ),
                  LinearProgressIndicator(
                    value: workspace.seatsTaken(entry.key) / table.duration,
                  ),
                ],
                for (final guest in entry.value)
                  DesignTile(
                    title: guest.title,
                    subtitle: context.plural(
                      'workspaces.seat_count',
                      guest.duration,
                      name: 'count',
                    ),
                    icon: TmsIcons.seat,
                    onTap: () => widget.editGuest(guest),
                    trailing: IconButton(
                      tooltip: context.tr('workspaces.move_guest'),
                      icon: const Icon(TmsIcons.switchWorkspace),
                      onPressed: () =>
                          moveGuest(context, ref, guest, groups.keys),
                    ),
                  ),
              ],
            ),
          ),
        DesignButton(
          context.tr('workspaces.manage_guests'),
          secondary: true,
          onPressed: widget.openGuests,
        ),
      ],
    );
  }
}

class _TableForm extends StatefulWidget {
  const _TableForm({required this.workspace});
  final LocalWorkspace workspace;
  @override
  State<_TableForm> createState() => _TableFormState();
}

class _TableFormState extends State<_TableForm> {
  String name = '', size = '8';
  bool attempted = false;
  bool longTable = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      DesignField(
        label: context.tr('workspaces.table'),
        onChanged: (s) => name = s.trim(),
      ),
      DesignField(
        label: context.tr('workspaces.capacity'),
        initialValue: size,
        keyboardType: TextInputType.number,
        onChanged: (s) => size = s.trim(),
      ),
      DesignChoices(
        items: [
          context.tr('workspaces.round_table'),
          context.tr('workspaces.long_table'),
        ],
        selected: longTable ? 1 : 0,
        onChanged: (i) => setState(() => longTable = i == 1),
      ),
      if (attempted) DesignLabel(context.tr('workspaces.invalid_table')),
      DesignButton(
        context.tr('workspaces.save'),
        onPressed: () {
          final n = int.tryParse(size) ?? 0;
          if (name.isEmpty ||
              n < 1 ||
              n > 1000 ||
              n < widget.workspace.seatsTaken(name) ||
              widget.workspace
                  .items(WorkspaceSection.seating)
                  .any((r) => r.title.toLowerCase() == name.toLowerCase())) {
            setState(() => attempted = true);
            return;
          }
          Navigator.pop(
            context,
            WorkspaceRecord(
              id: '',
              section: WorkspaceSection.seating,
              title: name,
              duration: n,
              fields: {'shape': longTable ? 'long' : 'round'},
            ),
          );
        },
      ),
    ],
  );
}
