import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import 'workspace_ui.dart';

/// A workspace's primary figure and its two related drill-downs.
class WorkspaceBrief extends StatelessWidget {
  const WorkspaceBrief({super.key, required this.workspace});
  final LocalWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final sections = switch (workspace.kind) {
      WorkspaceKind.individual => [
        if (workspace.withClients)
          WorkspaceSection.clients
        else
          WorkspaceSection.gigs,
        WorkspaceSection.invoices,
        WorkspaceSection.time,
        WorkspaceSection.proposals,
      ],
      WorkspaceKind.family => [
        WorkspaceSection.chores,
        WorkspaceSection.school,
        WorkspaceSection.bills,
        WorkspaceSection.plans,
      ],
      WorkspaceKind.church => [
        WorkspaceSection.services,
        WorkspaceSection.giving,
        WorkspaceSection.units,
        WorkspaceSection.prayers,
      ],
      WorkspaceKind.alumni => [
        WorkspaceSection.dues,
        WorkspaceSection.committees,
        WorkspaceSection.poll,
        WorkspaceSection.directory,
      ],
      WorkspaceKind.estate => [
        WorkspaceSection.levies,
        WorkspaceSection.passes,
        WorkspaceSection.issues,
        WorkspaceSection.notices,
      ],
      WorkspaceKind.committee => [
        WorkspaceSection.meetings,
        WorkspaceSection.actions,
        WorkspaceSection.minutes,
        WorkspaceSection.decisions,
      ],
      WorkspaceKind.club => [
        WorkspaceSection.sessions,
        WorkspaceSection.fees,
        WorkspaceSection.attendance,
        WorkspaceSection.notices,
      ],
      WorkspaceKind.event => [
        WorkspaceSection.guests,
        WorkspaceSection.seating,
        WorkspaceSection.vendors,
        WorkspaceSection.programme,
      ],
      WorkspaceKind.business => throw StateError(
        'Company uses its own dashboard',
      ),
    };
    return LayoutBuilder(
      builder: (context, bounds) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final (i, section) in sections.indexed)
            SizedBox(
              width: (bounds.maxWidth - 10) / 2,
              child: DesignCard(
                padding: const EdgeInsets.all(14),
                onTap: () => section.open(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: [
                          DesignColor.blue,
                          DesignColor.green,
                          DesignColor.amber,
                          DesignColor.purple,
                        ][i].withValues(alpha: .16),
                      ),
                      child: Icon(
                        section.icon,
                        color: [
                          DesignColor.blue,
                          DesignColor.green,
                          DesignColor.amber,
                          DesignColor.purple,
                        ][i],
                        size: 19,
                      ),
                    ),
                    Text(
                      _value(context, section),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.6,
                      ),
                    ),
                    Text(
                      section.label(context),
                      style: TextStyle(fontSize: 12, color: context.muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _value(BuildContext context, WorkspaceSection section) {
    final all = workspace.items(section);
    int count;
    switch (section) {
      case WorkspaceSection.giving:
      case WorkspaceSection.dues:
      case WorkspaceSection.fees:
      case WorkspaceSection.levies:
      case WorkspaceSection.vendors:
        return workspaceAmount(context, all.fold(0, (n, r) => n + r.paid));
      case WorkspaceSection.invoices:
        return workspaceAmount(
          context,
          all.fold(0, (n, r) => n + r.outstanding),
        );
      case WorkspaceSection.time:
        final minutes = workspace
            .weeklyTime(DateTime.now())
            .where((r) => r.flagged)
            .fold(0, (n, r) => n + r.duration);
        return context.plural('workspaces.duration', minutes, name: 'count');
      case WorkspaceSection.seating:
        count = workspace
            .items(WorkspaceSection.guests)
            .where(
              (r) =>
                  r.status == WorkspaceStatus.confirmed && r.group.isNotEmpty,
            )
            .fold(0, (n, r) => n + r.duration);
      case WorkspaceSection.guests:
        count = all
            .where((r) => r.status == WorkspaceStatus.confirmed)
            .fold(0, (n, r) => n + r.duration);
      case WorkspaceSection.attendance:
        count = all.where((r) => r.status == WorkspaceStatus.confirmed).length;
      case WorkspaceSection.school:
        count = all.where((r) => r.status == WorkspaceStatus.submitted).length;
      case WorkspaceSection.passes:
        count = all
            .where(
              (r) =>
                  !r.flagged &&
                  r.date != null &&
                  DateUtils.isSameDay(r.date, DateTime.now()),
            )
            .length;
      default:
        count = switch (section.view) {
          WorkspaceView.schedule =>
            all
                .where(
                  (r) => r.date != null && !r.date!.isBefore(DateTime.now()),
                )
                .length,
          WorkspaceView.checklist || WorkspaceView.review =>
            all.where((r) => r.status != WorkspaceStatus.done).length,
          _ => all.length,
        };
    }
    return NumberFormat.decimalPattern(context.locale.toString()).format(count);
  }
}
