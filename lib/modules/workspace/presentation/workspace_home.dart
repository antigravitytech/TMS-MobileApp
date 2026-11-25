import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/design_tokens.dart';
import '../application/local_workspaces.dart';
import '../application/workspace_preview.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import 'workspace_brief.dart';
import 'workspace_dashboard_header.dart';
import 'workspace_agenda.dart';
import 'workspace_event_invitation.dart';
import 'workspace_picker.dart';
import 'workspace_ui.dart';
import '../../../shared/design/tms_icons.dart';

part 'workspace_event_overview.dart';

typedef _EventDetails = ({
  String name,
  DateTime? date,
  String venue,
  int capacity,
  int budget,
});

class WorkspaceHome extends ConsumerWidget {
  const WorkspaceHome({
    super.key,
    required this.workspace,
    required this.companyName,
  });

  final LocalWorkspace workspace;
  final String companyName;

  Future<void> _editEvent(BuildContext context, WidgetRef ref) async {
    final details = await designSheet<_EventDetails>(
      context,
      title: context.tr('workspaces.event_details'),
      builder: (_) => _EventDetailsForm(workspace: workspace),
    );
    if (details == null || !context.mounted) return;
    await saveWorkspaceChange(
      context,
      () => ref
          .read(localWorkspacesProvider.notifier)
          .setEventDetails(
            workspace.id,
            name: details.name,
            date: details.date,
            venue: details.venue,
            capacity: details.capacity,
            budget: details.budget,
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = workspace.kind == WorkspaceKind.family;
    final event = workspace.kind == WorkspaceKind.event;
    final sections = workspace.kind.sections;

    return DesignPage(
      title: workspaceName(context, workspace),
      subtitle: workspace.occupation.isNotEmpty
          ? context.tr('workspaces.jobs.${workspace.occupation}')
          : workspace.name.isEmpty
          ? DateFormat.MMMMEEEEd(
              context.locale.toString(),
            ).format(DateTime.now())
          : workspace.kind.label(context),
      leading: workspace.kind == WorkspaceKind.family
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignColor.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                [
                  TmsIcons.home,
                  TmsIcons.heart,
                  TmsIcons.star,
                  TmsIcons.flame,
                ][workspace.crest.clamp(0, 3)],
                color: DesignColor.ink,
              ),
            )
          : null,
      tab: TmsRoute.home,
      navigation: WorkspaceNavigation(
        kind: workspace.kind,
        active: TmsRoute.home,
      ),
      actions: [
        DesignIcon(
          icon: TmsIcons.switchWorkspace,
          label: context.tr('more.switch_workspace'),
          onPressed: () => showWorkspacePicker(context, ref, companyName),
        ),
      ],
      children: [
        if (WorkspaceKind.specials.contains(workspace.kind)) ...[
          WorkspaceOverviewRail(workspace: workspace),
          if (!event) WorkspaceCountdown(workspace: workspace),
        ] else ...[
          DesignTitle(
            context.tr(
              'home.greeting',
              namedArgs: {
                'name': ref.watch(workspacePreviewProvider).firstName,
              },
            ),
          ),
          WorkspaceShortcuts(workspace: workspace),
          if (!family) DesignTitle(context.tr('dashboard.your_business')),
        ],
        if (family) DesignTitle(context.tr('workspaces.today_at_home')),
        if (!event) WorkspaceBrief(workspace: workspace),
        if (event)
          _EventOverview(
            workspace: workspace,
            onEdit: () => _editEvent(context, ref),
          ),
        if (family) _FamilyOverview(workspace: workspace),
        if (!family &&
            !event &&
            WorkspaceKind.specials.contains(workspace.kind))
          DesignTile(
            title: context.tr('common.reports'),
            icon: TmsIcons.report,
            onTap: () => TmsRoute.reports.open(context),
          ),
        if (family)
          DesignButton(
            context.tr('more.tools.kid_view'),
            secondary: true,
            icon: TmsIcons.smile,
            onPressed: () => TmsRoute.kidHome.open(context),
          ),
        if (!WorkspaceKind.specials.contains(workspace.kind))
          DesignTitle(context.tr('workspaces.your_sections')),
        if (!WorkspaceKind.specials.contains(workspace.kind))
          DesignSection(
            children: [
              for (final section in sections)
                DesignTile(
                  title: section.label(context),
                  subtitle: _sectionSummary(context, section),
                  icon: section.icon,
                  color: workspace.kind.ink(context),
                  onTap: () => section.open(context),
                ),
            ],
          ),
        if (workspace.records.any((r) => r.date != null))
          WorkspaceAgenda(workspace: workspace),
        DesignLabel(context.tr('workspaces.local_data')),
      ],
    );
  }

  String? _sectionSummary(BuildContext context, WorkspaceSection section) {
    final items = workspace.items(section);
    if (section.view == WorkspaceView.money && items.isNotEmpty) {
      final outstanding = items.fold(0, (sum, item) => sum + item.outstanding);
      return outstanding == 0
          ? context.tr('workspaces.paid_in_full')
          : context.tr(
              'workspaces.balance_amount',
              namedArgs: {'amount': workspaceAmount(context, outstanding)},
            );
    }
    if (section.view == WorkspaceView.checklist ||
        section.view == WorkspaceView.review) {
      return context.plural(
        'workspaces.open_items',
        items.where((item) => item.status != WorkspaceStatus.done).length,
        name: 'count',
      );
    }
    if (section.view != WorkspaceView.seating && items.isNotEmpty) {
      return context.plural(
        'workspaces.item_count',
        items.length,
        name: 'count',
      );
    }
    return null;
  }
}

class _FamilyOverview extends StatelessWidget {
  const _FamilyOverview({required this.workspace});
  final LocalWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final reviews = workspace.records.where(
      (item) => item.section.view == WorkspaceView.review,
    );
    final submitted = reviews
        .where((item) => item.status == WorkspaceStatus.submitted)
        .toList();
    final points = {
      for (final item in reviews)
        if (item.status == WorkspaceStatus.done && item.person.isNotEmpty)
          item.person: workspace.availablePoints(item.person),
    };
    final leaders = points.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 9,
        children: [
          DesignTitle(context.tr('dashboard.needs_you')),
          DesignLabel(
            context.plural(
              'workspaces.waiting_review',
              submitted.length,
              name: 'count',
            ),
          ),
          if (submitted.isNotEmpty)
            DesignButton(
              context.tr('workspaces.check_work'),
              secondary: true,
              onPressed: () => submitted.first.section.open(
                context,
                filter: WorkspaceStatus.submitted,
              ),
            ),
          if (leaders.isNotEmpty) ...[
            DesignTitle(context.tr('workspaces.points_board')),
            for (final entry in leaders)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8,
                children: [
                  Expanded(child: DesignLabel(entry.key)),
                  DesignPill(
                    context.plural(
                      'workspaces.points',
                      entry.value,
                      name: 'count',
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
