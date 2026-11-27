import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../application/local_workspaces.dart';
import '../application/workspace_preview.dart';
import '../../../shared/kit/kit.dart';
import 'widgets/workspace_picker.dart';
import 'workspace_tools.dart';
import '../domain/workspace_kind.dart';
import 'widgets/workspace_ui.dart';
import '../../../shared/design/tms_icons.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspacePreviewProvider);
    final workspace = ref.watch(localWorkspacesProvider).asData?.value.active;
    final head = workspace?.kind == WorkspaceKind.family
        ? workspace!
              .items(WorkspaceSection.household)
              .where((m) => m.fields['householdRole'] == 'head')
              .firstOrNull
        : null;
    final headFace = head == null ? null : kitPerson(head.title);
    final solo = workspace?.kind == WorkspaceKind.individual;
    final church = workspace?.kind == WorkspaceKind.church;
    final alumni = workspace?.kind == WorkspaceKind.alumni;
    final estate = workspace?.kind == WorkspaceKind.estate;
    final event = workspace?.kind == WorkspaceKind.event;
    final committee = workspace?.kind == WorkspaceKind.committee;
    final club = workspace?.kind == WorkspaceKind.club;
    // Family and Individual workspaces show the prototype's logo card.
    final logoColor = head != null
        ? DesignColor.teal
        : solo
        ? KitColor.avatar(5)
        : church
        ? KitColor.avatar(1)
        : alumni
        ? KitColor.avatar(2)
        : estate
        ? KitColor.avatar(3)
        : event
        ? KitColor.avatar(4)
        : committee
        ? KitColor.avatar(7)
        : club
        ? KitColor.avatar(6)
        : null;
    Widget online(Widget avatar) => Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: DesignColor.green,
              shape: BoxShape.circle,
              border: Border.all(color: context.panel, width: 2.5),
            ),
          ),
        ),
      ],
    );
    return DesignPage(
      title: context.tr('common.more'),
      tab: TmsRoute.more,
      navigation: workspace == null
          ? null
          : WorkspaceNavigation(kind: workspace.kind, active: TmsRoute.more),
      children: [
        DesignSection(
          children: [
            if (head != null)
              DesignTile(
                title: head.title,
                subtitle: context.tr('household.roles.head'),
                leading: online(
                  DesignAvatar(headFace!.$1, size: 52, color: headFace.$2),
                ),
                onTap: () => TmsRoute.household.open(context),
              )
            else if (solo ||
                church ||
                alumni ||
                estate ||
                event ||
                committee ||
                club)
              DesignTile(
                title: '${state.firstName} ${state.lastName}',
                subtitle:
                    '${state.jobTitle} · ${workspaceName(context, workspace!)}',
                leading: online(
                  DesignAvatar(
                    kitPerson('${state.firstName} ${state.lastName}').$1,
                    size: 52,
                    color: KitColor.avatar(solo ? 5 : 2),
                  ),
                ),
                onTap: () => TmsRoute.profile.open(context),
              )
            else
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
            if (logoColor != null)
              _FamilyWorkspaceTile(
                name: workspaceName(context, workspace!),
                label: context.tr(
                  solo
                      ? 'more.individual_workspace'
                      : church
                      ? 'more.church_workspace'
                      : alumni
                      ? 'more.alumni_workspace'
                      : estate
                      ? 'more.estate_workspace'
                      : event
                      ? 'more.event_workspace'
                      : committee
                      ? 'more.committee_workspace'
                      : club
                      ? 'more.club_workspace'
                      : 'more.family_workspace',
                ),
                color: logoColor,
                onSwitch: () => showWorkspacePicker(
                  context,
                  ref,
                  state.workspace,
                  returnHome: true,
                ),
              )
            else
              DesignTile(
                title: workspace == null
                    ? state.workspace
                    : workspaceName(context, workspace),
                subtitle: workspace == null
                    ? context.tr('more.workspace')
                    : workspace.kind.label(context),
                leading: workspace == null
                    ? const DesignAvatar('AG', color: DesignColor.teal)
                    : head != null
                    ? _Logo(workspaceName(context, workspace))
                    : null,
                icon: head != null ? null : workspace?.kind.icon,
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

/// Square workspace logo with initials (`.ws-logo`).
class _Logo extends StatelessWidget {
  const _Logo(this.name, {this.color = DesignColor.teal});
  final String name;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      name
          .replaceFirst(RegExp(r'^The\s+'), '')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join(),
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: DesignColor.ink,
      ),
    ),
  );
}

/// Family workspace card: logo, "Family workspace" above the name, Switch.
class _FamilyWorkspaceTile extends StatelessWidget {
  const _FamilyWorkspaceTile({
    required this.name,
    required this.label,
    required this.color,
    required this.onSwitch,
  });
  final String name, label;
  final Color color;
  final VoidCallback onSwitch;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onSwitch,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        spacing: 12,
        children: [
          _Logo(name, color: color),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: context.muted),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            context.tr('more.switch'),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: context.lavender,
            ),
          ),
        ],
      ),
    ),
  );
}
