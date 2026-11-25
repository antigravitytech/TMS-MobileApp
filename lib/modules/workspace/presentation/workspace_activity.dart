import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../application/local_workspaces.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_entry.dart';
import '../domain/workspace_kind.dart';
import 'workspace_ui.dart';

class WorkspaceActivity extends ConsumerWidget {
  const WorkspaceActivity({
    super.key,
    required this.workspaceId,
    required this.record,
  });
  final String workspaceId;
  final WorkspaceRecord record;
  Future<void> add(
    BuildContext context,
    WidgetRef ref,
    EntryKind kind, [
    int? pledge,
  ]) async {
    final entry = await designSheet<WorkspaceEntry>(
      context,
      title: context.tr('workspaces.entry.action.${kind.name}'),
      builder: (_) => _EntryForm(kind: kind, record: record, pledge: pledge),
    );
    if (context.mounted && entry != null) {
      await saveWorkspaceChange(
        context,
        () => ref
            .read(localWorkspacesProvider.notifier)
            .addEntry(workspaceId, record.id, entry),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = switch (record.section) {
      WorkspaceSection.giving => [EntryKind.payment, EntryKind.pledge],
      WorkspaceSection.units => [EntryKind.duty, EntryKind.notice],
      WorkspaceSection.firstTimers => [EntryKind.followUp],
      _ => <EntryKind>[],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        if (actions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in actions)
                DesignPill(
                  context.tr('workspaces.entry.action.${kind.name}'),
                  icon: TmsIcons.add,
                  onTap: () => add(context, ref, kind),
                ),
            ],
          ),
        if (record.entries.isNotEmpty)
          DesignSection(
            children: [
              for (final (index, e) in record.entries.indexed.toList().reversed)
                DesignTile(
                  title: [
                    context.tr('workspaces.entry.kind.${e.kind.name}'),
                    if (e.name.isNotEmpty) e.name,
                  ].join(' · '),
                  subtitle: [
                    MaterialLocalizations.of(context).formatMediumDate(e.date),
                    if (e.amount > 0) workspaceAmount(context, e.amount),
                    if (e.method.isNotEmpty)
                      context.tr('workspaces.entry.method.${e.method}'),
                    if (e.note.isNotEmpty) e.note,
                    if (e.kind == EntryKind.pledge)
                      context.tr(
                        'workspaces.balance_amount',
                        namedArgs: {
                          'amount': workspaceAmount(
                            context,
                            record.pledgeBalance(index),
                          ),
                        },
                      ),
                  ].join(' · '),
                  onTap:
                      e.kind == EntryKind.pledge &&
                          record.pledgeBalance(index) > 0
                      ? () => add(context, ref, EntryKind.payment, index)
                      : null,
                ),
            ],
          ),
      ],
    );
  }
}

class _EntryForm extends StatefulWidget {
  const _EntryForm({
    required this.kind,
    required this.record,
    required this.pledge,
  });
  final EntryKind kind;
  final WorkspaceRecord record;
  final int? pledge;
  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  late String name = widget.pledge == null
      ? ''
      : widget.record.entries[widget.pledge!].name;
  String note = '', amount = '', method = 'cash';
  DateTime date = DateTime.now();
  bool attempted = false;
  bool get financial =>
      widget.kind == EntryKind.pledge || widget.kind == EntryKind.payment;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      if (financial || widget.kind == EntryKind.duty)
        DesignField(
          label: context.tr('workspaces.name'),
          initialValue: name,
          onChanged: (s) => name = s.trim(),
        ),
      if (financial)
        DesignField(
          label: context.tr('workspaces.amount_ngn'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (s) => amount = s,
        ),
      if (widget.kind == EntryKind.payment)
        DropdownButtonFormField<String>(
          initialValue: method,
          decoration: InputDecoration(
            labelText: context.tr('workspaces.entry.method_label'),
          ),
          items: [
            for (final m in ['cash', 'transfer', 'card', 'pos'])
              DropdownMenuItem(
                value: m,
                child: Text(context.tr('workspaces.entry.method.$m')),
              ),
          ],
          onChanged: (m) {
            if (m != null) method = m;
          },
        ),
      DesignButton(
        MaterialLocalizations.of(context).formatMediumDate(date),
        icon: TmsIcons.calendar,
        secondary: true,
        onPressed: () async {
          final d = await pickWorkspaceDate(context, date);
          if (mounted && d != null) setState(() => date = d);
        },
      ),
      DesignField(
        label: context.tr('common.notes'),
        lines: 3,
        onChanged: (s) => note = s.trim(),
      ),
      if (attempted) DesignLabel(context.tr('workspaces.entry.invalid')),
      DesignButton(
        context.tr('workspaces.save'),
        onPressed: () {
          final value = parseWorkspaceAmount(amount) ?? 0;
          if (financial &&
                  (value <= 0 ||
                      (widget.pledge != null &&
                          value >
                              widget.record.pledgeBalance(widget.pledge!))) ||
              widget.kind == EntryKind.pledge && name.isEmpty ||
              !financial && note.isEmpty) {
            setState(() => attempted = true);
            return;
          }
          Navigator.pop(
            context,
            WorkspaceEntry(
              kind: widget.kind,
              name: name,
              note: note,
              amount: value,
              date: date,
              method: widget.kind == EntryKind.payment ? method : '',
              pledgeIndex: widget.pledge,
            ),
          );
        },
      ),
    ],
  );
}
