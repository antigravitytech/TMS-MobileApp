import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/tms_routes.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../application/local_workspaces.dart';
import '../../domain/local_workspace.dart';
import '../../domain/workspace_kind.dart';
import 'workspace_ui.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';

Future<void> showWorkspacePicker(
  BuildContext context,
  WidgetRef ref,
  String companyName, {
  bool returnHome = false,
  bool specialsOnly = false,
}) async {
  final selection = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.panel,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .78,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheet) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: context.muted.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            DesignTitle(
              context.tr(
                specialsOnly
                    ? 'workspaces.specials'
                    : 'workspaces.your_workspaces',
              ),
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) => ref
                  .watch(localWorkspacesProvider)
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => DesignButton(
                      context.tr('workspaces.try_again'),
                      onPressed: () => ref.invalidate(localWorkspacesProvider),
                    ),
                    data: (directory) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: [
                        Text(
                          context.tr('workspaces.one_sign_in'),
                          style: TextStyle(color: context.muted, fontSize: 14),
                        ),
                        _WorkspaceOptions(
                          title: null,
                          workspaces: [
                            if (!specialsOnly)
                              const LocalWorkspace(
                                id: WorkspaceDirectory.companyId,
                                kind: WorkspaceKind.business,
                              ),
                            ...directory.workspaces.where(
                              (space) =>
                                  !specialsOnly ||
                                  WorkspaceKind.specials.contains(space.kind),
                            ),
                          ],
                          activeId: directory.activeId,
                          companyName: companyName,
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
      for (final workspace in workspaces)
        _WorkspaceRow(
          workspace: workspace,
          active: workspace.id == activeId,
          name: workspace.id == WorkspaceDirectory.companyId
              ? companyName ?? workspaceName(context, workspace)
              : workspaceName(context, workspace),
        ),
    ],
  );
}

class _WorkspaceRow extends StatelessWidget {
  const _WorkspaceRow({
    required this.workspace,
    required this.active,
    required this.name,
  });
  final LocalWorkspace workspace;
  final bool active;
  final String name;
  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0])
        .join()
        .toUpperCase();
    return InkWell(
      onTap: () => Navigator.pop(context, workspace.id),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: workspace.kind.ink(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: DesignColor.ink,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    workspace.kind.label(context),
                    style: TextStyle(color: context.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (active)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: DesignColor.green.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 3,
                      backgroundColor: DesignColor.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('workspaces.here'),
                      style: const TextStyle(
                        color: DesignColor.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
