import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/design/design_widgets.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import 'workspace_ui.dart';

/// Surfaces the next scheduled work and outstanding deadlines with direct access
/// to the corresponding record in Plan.
class WorkspaceAgenda extends StatelessWidget {
  const WorkspaceAgenda({super.key, required this.workspace});
  final LocalWorkspace workspace;
  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final items = workspace.records.where((r) {
      final date = r.date;
      if (date == null || r.status == WorkspaceStatus.done) return false;
      return switch (r.section.view) {
        WorkspaceView.schedule => !date.isBefore(today),
        WorkspaceView.money => r.outstanding > 0,
        WorkspaceView.checklist || WorkspaceView.review => true,
        _ => false,
      };
    }).toList()..sort((a, b) => a.date!.compareTo(b.date!));
    if (items.isEmpty) return const SizedBox.shrink();
    final dates = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        DesignTitle(context.tr('workspaces.agenda')),
        DesignSection(
          children: [
            for (final item in items.take(3))
              DesignTile(
                title: item.title,
                icon: item.section.icon,
                color: workspace.kind.ink(context),
                subtitle: [
                  dates.formatMediumDate(item.date!),
                  if (item.section.view == WorkspaceView.schedule)
                    TimeOfDay.fromDateTime(item.date!).format(context),
                  if (item.person.isNotEmpty) item.person,
                ].join(' · '),
                onTap: () => item.section.open(context, recordId: item.id),
              ),
          ],
        ),
      ],
    );
  }
}
