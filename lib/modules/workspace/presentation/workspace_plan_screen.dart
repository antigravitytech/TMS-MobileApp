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
import 'section_screens.dart';
import 'widgets/workspace_picker.dart';
import 'widgets/workspace_dashboard_header.dart';
import '../../individual/presentation/widgets/new_invoice_sheet.dart';
import 'widgets/workspace_invoice_list.dart';
import 'widgets/workspace_section_rail.dart';
import 'widgets/workspace_record_form.dart';
import 'widgets/workspace_record_widgets.dart';
import 'widgets/workspace_ui.dart';
import '../../../shared/design/tms_icons.dart';

part 'widgets/workspace_plan_actions.dart';

class WorkspacePlanScreen extends ConsumerWidget {
  const WorkspacePlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tab switches replace this route with a new query; rebuild for them.
    context.watchRouter;
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
    final dedicated = sectionScreen(workspace, initial);
    if (dedicated != null) return dedicated;
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
        create: () => workspace.kind == WorkspaceKind.individual
            ? showNewInvoiceSheet(context, workspace.id)
            : edit(section),
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
        if (items.isNotEmpty)
          IconButton(
            tooltip: context.tr('common.search'),
            icon: Icon(searching ? TmsIcons.close : TmsIcons.search),
            onPressed: () => setState(() {
              searching = !searching;
              search.clear();
            }),
          ),
        if (items.isNotEmpty)
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
        if (searching)
          DesignField(
            label: context.tr('common.search'),
            controller: search,
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
        if (items.isNotEmpty && filters.isNotEmpty)
          DesignChoices(
            items: [
              context.tr('common.all'),
              for (final value in filters) section.statusLabel(context, value),
            ],
            selected: filter == null ? 0 : filters.indexOf(filter!) + 1,
            onChanged: (index) =>
                setState(() => filter = index == 0 ? null : filters[index - 1]),
          ),
        if (visible.isEmpty)
          DesignEmpty(
            context.tr('workspaces.no_records'),
            filter == null && term.isEmpty
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
        if (visible.isNotEmpty)
          WorkspaceContentTransition(
            identity: (workspace.id, section, filter),
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
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
