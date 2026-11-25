import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import '../application/local_workspaces.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import 'workspace_ui.dart';
import 'workspace_section_rail.dart';
import '../../../shared/design/tms_icons.dart';

Future<void> showWorkspacePicker(
  BuildContext context,
  WidgetRef ref,
  String companyName, {
  bool returnHome = false,
  bool specialsOnly = false,
}) async {
  final selection = await designSheet<String>(
    context,
    title: context.tr(
      specialsOnly ? 'workspaces.specials' : 'more.switch_workspace',
    ),
    builder: (_) => Consumer(
      builder: (context, ref, _) => ref
          .watch(localWorkspacesProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => DesignButton(
              context.tr('workspaces.try_again'),
              onPressed: () => ref.invalidate(localWorkspacesProvider),
            ),
            data: (directory) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                if (!specialsOnly) ...[
                  _WorkspaceOptions(
                    title: WorkspaceKind.business.label(context),
                    workspaces: const [
                      LocalWorkspace(
                        id: WorkspaceDirectory.companyId,
                        kind: WorkspaceKind.business,
                      ),
                    ],
                    activeId: directory.activeId,
                    companyName: companyName,
                  ),
                  for (final kind in [
                    WorkspaceKind.individual,
                    WorkspaceKind.family,
                  ])
                    _WorkspaceOptions(
                      title: context.tr(
                        kind == WorkspaceKind.individual
                            ? 'workspaces.individuals'
                            : 'workspaces.families',
                      ),
                      workspaces: directory.workspaces.where(
                        (space) => space.kind == kind,
                      ),
                      activeId: directory.activeId,
                    ),
                ],
                _WorkspaceOptions(
                  title: specialsOnly
                      ? null
                      : context.tr('workspaces.specials'),
                  workspaces: directory.workspaces.where(
                    (space) => WorkspaceKind.specials.contains(space.kind),
                  ),
                  activeId: directory.activeId,
                ),
                if (!specialsOnly)
                  DesignButton(
                    context.tr('onboarding.new_workspace'),
                    icon: TmsIcons.add,
                    secondary: true,
                    onPressed: () => Navigator.pop(context, ''),
                  ),
              ],
            ),
          ),
    ),
  );
  if (!context.mounted || selection == null) return;
  if (selection.isEmpty) {
    context.router.pushPath('${TmsRoute.setup.path}?from=switch');
    return;
  }
  final saved = await saveWorkspaceChange(
    context,
    () => specialsOnly
        ? ref.read(localWorkspacesProvider.notifier).enterDemo(selection)
        : ref.read(localWorkspacesProvider.notifier).select(selection),
  );
  if (saved && returnHome && context.mounted) TmsRoute.home.reset(context);
}

class _WorkspaceOptions extends StatelessWidget {
  const _WorkspaceOptions({
    required this.title,
    required this.workspaces,
    required this.activeId,
    this.companyName,
  });

  final String? title;
  final Iterable<LocalWorkspace> workspaces;
  final String activeId;
  final String? companyName;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 6,
    children: [
      if (title != null) DesignTitle(title!),
      DesignSection(
        children: [
          for (final workspace in workspaces)
            DesignTile(
              title: companyName ?? workspaceName(context, workspace),
              subtitle: workspace.kind.description(context),
              icon: workspace.kind.icon,
              color: workspace.kind.ink(context),
              trailing: workspace.id == activeId
                  ? WorkspaceSelectionIcon(
                      icon: TmsIcons.checkCircleFilled,
                      color: workspace.kind.ink(context),
                    )
                  : null,
              onTap: () => Navigator.pop(context, workspace.id),
            ),
        ],
      ),
    ],
  );
}
