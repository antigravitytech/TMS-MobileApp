import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/design/design_widgets.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';

class GuestImportForm extends StatefulWidget {
  const GuestImportForm({super.key});
  @override
  State<GuestImportForm> createState() => _GuestImportFormState();
}

class _GuestImportFormState extends State<GuestImportForm> {
  String input = '';
  List<WorkspaceRecord>? get guests {
    final guests = <WorkspaceRecord>[];
    for (final line in input.split('\n').where((s) => s.trim().isNotEmpty)) {
      final parts = line.split(',').map((s) => s.trim()).toList();
      if (parts.first.isEmpty || parts.length > 3) return null;
      final last = int.tryParse(parts.last);
      final hasSeats =
          parts.length == 3 ||
          (parts.length == 2 && last != null && parts.last.length <= 3);
      final seats = hasSeats ? last : 1;
      if (seats == null || seats < 1 || seats > 100) return null;
      final contact = parts.length == 3 || (parts.length == 2 && !hasSeats)
          ? parts[1]
          : '';
      guests.add(
        WorkspaceRecord(
          id: '',
          section: WorkspaceSection.guests,
          title: parts.first,
          duration: seats,
          status: WorkspaceStatus.pending,
          fields: {
            if (contact.isNotEmpty)
              (contact.contains('@') ? 'email' : 'phone'): contact,
          },
        ),
      );
    }
    return guests;
  }

  @override
  Widget build(BuildContext context) {
    final entries = guests;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        DesignLabel(context.tr('workspaces.import_hint')),
        DesignField(
          label: context.tr('workspaces.guest_list'),
          lines: 6,
          onChanged: (s) => setState(() => input = s),
        ),
        if (entries == null)
          DesignLabel(context.tr('workspaces.invalid_guest_list')),
        if (entries != null && entries.isNotEmpty)
          DesignLabel(
            context.plural(
              'workspaces.import_count',
              entries.length,
              name: 'count',
            ),
          ),
        DesignButton(
          context.tr('workspaces.import_guests'),
          onPressed: entries == null || entries.isEmpty
              ? null
              : () => Navigator.pop(context, entries),
        ),
      ],
    );
  }
}
