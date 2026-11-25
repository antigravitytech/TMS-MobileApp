import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../application/local_workspaces.dart';
import '../application/workspace_preview.dart';
import 'workspace_picker.dart';
import 'workspace_tools.dart';
import '../domain/workspace_kind.dart';
import 'workspace_ui.dart';
import '../../../shared/design/tms_icons.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspacePreviewProvider);
    final workspace = ref.watch(localWorkspacesProvider).asData?.value.active;
    return DesignPage(
      title: context.tr('common.more'),
      tab: TmsRoute.more,
      navigation: workspace == null
          ? null
          : WorkspaceNavigation(kind: workspace.kind, active: TmsRoute.more),
      children: [
        DesignSection(
          children: [
            DesignTile(
              title: '${state.firstName} ${state.lastName}',
              subtitle: '${state.jobTitle} · ${context.tr(state.status)}',
              leading: const DesignAvatar('CO', size: 48),
              onTap: () => TmsRoute.profile.open(context),
            ),
          ],
        ),
        DesignSection(
          children: [
            DesignTile(
              title: workspace == null
                  ? state.workspace
                  : workspaceName(context, workspace),
              subtitle: workspace == null
                  ? context.tr('more.workspace')
                  : workspace.kind.label(context),
              leading: workspace == null
                  ? const DesignAvatar('AG', color: DesignColor.teal)
                  : null,
              icon: workspace?.kind.icon,
              trailing: TextButton(
                onPressed: () => showWorkspacePicker(
                  context,
                  ref,
                  state.workspace,
                  returnHome: true,
                ),
                child: Text(context.tr('more.switch')),
              ),
            ),
          ],
        ),
        WorkspaceTools(kind: workspace?.kind ?? WorkspaceKind.business),
        DesignSection(
          children: [
            DesignTile(
              title: context.tr('common.settings'),
              icon: TmsIcons.settings,
              onTap: () => TmsRoute.settings.open(context),
            ),
            DesignTile(
              title: context.tr('common.notifications'),
              icon: TmsIcons.notifications,
              trailing: DesignPill(
                (6 - state.readNotifications.length).toString(),
              ),
              onTap: () => TmsRoute.notifications.open(context),
            ),
            DesignTile(
              title: context.tr('common.sign_out'),
              icon: TmsIcons.logout,
              color: DesignColor.rose,
              onTap: () => TmsRoute.welcome.reset(context),
            ),
          ],
        ),
        Center(child: DesignLabel(context.tr('more.sabi_pipu_tms'))),
      ],
    );
  }
}
