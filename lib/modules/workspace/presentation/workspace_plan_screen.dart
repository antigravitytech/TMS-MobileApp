import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../application/local_workspaces.dart';
import '../application/workspace_preview.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import 'workspace_picker.dart';
import 'workspace_dashboard_header.dart';
import 'workspace_focus_timer.dart';
import 'workspace_gigs.dart';
import 'workspace_invoice_list.dart';
import 'workspace_section_rail.dart';
import 'workspace_guest_import.dart';
import 'workspace_seating.dart';
import 'workspace_record_form.dart';
import 'workspace_record_widgets.dart';
import 'workspace_ui.dart';
import '../../../shared/design/tms_icons.dart';

part 'workspace_plan_actions.dart';

class WorkspacePlanScreen extends ConsumerWidget {
  const WorkspacePlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directory = ref.watch(localWorkspacesProvider);
    final workspace = directory.asData?.value.active;
    if (workspace == null) {
      return DesignPage(
        title: context.tr('workspaces.plan'),
        children: [
          if (directory.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            DesignButton(
              context.tr('more.switch_workspace'),
              onPressed: () => showWorkspacePicker(
                context,
                ref,
                ref.read(workspacePreviewProvider).workspace,
                returnHome: true,
              ),
            ),
        ],
      );
    }
    final query = context.routeData.queryParams.getString('section', '');
    final initial = workspace.kind.sections.firstWhere(
      (section) => section.name == query,
      orElse: () => workspace.kind.sections.first,
    );
    final initialFilter =
        initial.view == WorkspaceView.review &&
            context.routeData.queryParams.getString('status', '') ==
                WorkspaceStatus.submitted.name
        ? WorkspaceStatus.submitted
        : null;
    final itemId = context.routeData.queryParams.getString('item', '');
    return _WorkspaceSections(
      itemId: itemId,
      key: ValueKey((workspace.id, query, initialFilter, itemId)),
      workspace: workspace,
      initial: initial,
      initialFilter: initialFilter,
    );
  }
}

class _WorkspaceSections extends ConsumerStatefulWidget {
  const _WorkspaceSections({
    super.key,
    required this.workspace,
    required this.initial,
    required this.initialFilter,
    required this.itemId,
  });

  final LocalWorkspace workspace;
  final WorkspaceSection initial;
  final WorkspaceStatus? initialFilter;
  final String itemId;

  @override
  ConsumerState<_WorkspaceSections> createState() => _WorkspaceSectionsState();
}

class _WorkspaceSectionsState extends _WorkspacePlanActions {
  @override
  Widget build(BuildContext context) {
    final sections = workspace.kind.sections;
    final items = workspace.items(section).toList();
    if (section.view == WorkspaceView.schedule) {
      items.sort((a, b) => a.date!.compareTo(b.date!));
    }
    final term = search.text.trim().toLowerCase();
    final visible = items
        .where(
          (r) =>
              (filter == null || r.status == filter) &&
              (!checkIn || r.status == WorkspaceStatus.confirmed) &&
              (term.isEmpty ||
                  [
                    r.title,
                    r.group,
                    r.person,
                    r.notes,
                    ...r.fields.values,
                  ].any((v) => v.toLowerCase().contains(term))),
        )
        .toList();
    final filters = switch (section.view) {
      WorkspaceView.review => const [
        WorkspaceStatus.todo,
        WorkspaceStatus.submitted,
        WorkspaceStatus.returned,
        WorkspaceStatus.done,
      ],
      WorkspaceView.people when section.tracksPeopleStatus =>
        section.peopleStatuses,
      WorkspaceView.checklist => [
        WorkspaceStatus.todo,
        if (section.tracksProgress) WorkspaceStatus.inProgress,
        WorkspaceStatus.done,
      ],
      _ => <WorkspaceStatus>[],
    };

    if (section == WorkspaceSection.invoices) {
      return WorkspaceInvoiceList(
        workspace: workspace,
        records: items,
        navigation: WorkspaceNavigation(
          kind: workspace.kind,
          active: TmsRoute.workspacePlan,
          section: section,
          onSection: selectSection,
        ),
        create: () => edit(section),
        open: showRecord,
        payment: recordPayment,
      );
    }
    final special = WorkspaceKind.specials.contains(workspace.kind);
    return DesignPage(
      title: special
          ? workspaceName(context, workspace)
          : section.label(context),
      subtitle: special
          ? workspace.kind.label(context)
          : workspaceName(context, workspace),
      tab: TmsRoute.workspacePlan,
      navigation: WorkspaceNavigation(
        kind: workspace.kind,
        active: special ? TmsRoute.home : TmsRoute.workspacePlan,
        section: section,
        onSection: selectSection,
      ),
      actions: [
        if (items.isNotEmpty && section.view != WorkspaceView.seating)
          IconButton(
            tooltip: context.tr('common.search'),
            icon: Icon(searching ? TmsIcons.close : TmsIcons.search),
            onPressed: () => setState(() {
              searching = !searching;
              search.clear();
            }),
          ),
        if (section.view != WorkspaceView.seating && items.isNotEmpty)
          DesignIcon(
            icon: TmsIcons.add,
            label: section.addLabel(context),
            onPressed: () => edit(section),
          ),
      ],
      children: [
        if (special)
          WorkspaceOverviewRail(
            workspace: workspace,
            section: section,
            select: selectSection,
          )
        else
          WorkspaceSectionRail(
            sections: sections,
            selected: section,
            onChanged: selectSection,
          ),
        if (section == WorkspaceSection.gigs)
          GigTemplates(workspace: workspace),
        if (section == WorkspaceSection.time)
          WorkspaceFocusTimer(workspace: workspace),
        if (searching)
          DesignField(
            label: context.tr('common.search'),
            controller: search,
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
        if (section == WorkspaceSection.guests ||
            section == WorkspaceSection.programme && items.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (section == WorkspaceSection.guests) ...[
                DesignPill(
                  context.tr('workspaces.import_guests'),
                  icon: TmsIcons.upload,
                  onTap: importGuests,
                ),
                if (items.isNotEmpty)
                  DesignPill(
                    context.tr('workspaces.check_in_mode'),
                    selected: checkIn,
                    icon: TmsIcons.badge,
                    onTap: () => setState(() {
                      checkIn = !checkIn;
                      filter = null;
                    }),
                  ),
              ] else
                DesignPill(
                  context.tr('workspaces.line_up'),
                  icon: TmsIcons.clock,
                  onTap: () => alignProgramme(items),
                ),
            ],
          ),
        if (section.view == WorkspaceView.seating)
          WorkspaceSeatingList(
            workspace: workspace,
            editGuest: showRecord,
            openGuests: () => selectSection(WorkspaceSection.guests),
          )
        else ...[
          if (!checkIn && items.isNotEmpty && filters.isNotEmpty)
            DesignChoices(
              items: [
                context.tr('common.all'),
                for (final value in filters)
                  section.statusLabel(context, value),
              ],
              selected: filter == null ? 0 : filters.indexOf(filter!) + 1,
              onChanged: (index) => setState(
                () => filter = index == 0 ? null : filters[index - 1],
              ),
            ),
          if (items.isNotEmpty && section.view == WorkspaceView.money)
            WorkspacePaymentSummary(items: items),
          if (items.isNotEmpty && section.view == WorkspaceView.time)
            WorkspaceTimeSummary(
              hourlyRate: workspace.hourlyRate,
              editRate: changeRate,
              items: workspace.weeklyTime(DateTime.now()).toList(),
            ),
          if (visible.isEmpty)
            DesignEmpty(
              context.tr('workspaces.no_records'),
              filter == null && !checkIn && term.isEmpty
                  ? context.tr('workspaces.sections.${section.name}.empty')
                  : context.tr('workspaces.no_matching_records'),
              icon: section.icon,
            ),
          if (items.isEmpty)
            DesignButton(
              section.addLabel(context),
              icon: TmsIcons.add,
              onPressed: () => edit(section),
            ),
          if (section.view == WorkspaceView.poll)
            for (final item in visible)
              WorkspacePollCard(
                key: ValueKey(item.id),
                item: item,
                showRecord: () => showRecord(item),
                onVote: (vote) => update(
                  item,
                  (current) =>
                      current.vote == null && vote < current.options.length
                      ? current.copyWith(vote: vote)
                      : current,
                ),
              )
          else if (visible.isNotEmpty)
            WorkspaceContentTransition(
              identity: (workspace.id, section, filter, checkIn),
              child: DesignSection(
                children: [
                  for (final item in visible)
                    DesignTile(
                      key: ValueKey(item.id),
                      title: item.title,
                      icon: section.icon,
                      color: workspace.kind.ink(context),
                      subtitle: workspaceRecordSubtitle(context, item),
                      onTap: () => showRecord(item),
                      trailing: checkIn
                          ? IconButton(
                              tooltip: context.tr(
                                item.flagged
                                    ? 'workspaces.undo_check_in'
                                    : 'workspaces.check_in_guest',
                              ),
                              icon: WorkspaceSelectionIcon(
                                key: ValueKey(item.flagged),
                                icon: item.flagged
                                    ? TmsIcons.checkCircleFilled
                                    : TmsIcons.circle,
                                color: workspace.kind.ink(context),
                              ),
                              onPressed: () => update(
                                item,
                                (r) => r.copyWith(flagged: !r.flagged),
                              ),
                            )
                          : null,
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
