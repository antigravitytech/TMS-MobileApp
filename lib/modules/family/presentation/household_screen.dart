import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/local_workspaces.dart';
import '../application/family_task_draft.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit.dart';
import '../../../shared/kit/kit_visuals.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import 'widgets/household_sheets.dart';

class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(localWorkspacesProvider).asData?.value.active;
    if (space == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final people = space.items(WorkspaceSection.household).toList();
    return Scaffold(
      backgroundColor: context.background,
      bottomNavigationBar: const WorkspaceNavigation(
        kind: WorkspaceKind.family,
        active: TmsRoute.more,
        badges: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitHeader(
              title: context.tr('household.title'),
              subtitle: context.tr(
                'household.subtitle',
                namedArgs: {'count': '${people.length}', 'name': space.name},
              ),
              back: context.tr('common.back'),
              action: KitIconButton(
                primary: true,
                icon: TmsIcons.add,
                tooltip: context.tr('household.add_member'),
                onPressed: () => WorkspaceSection.household.open(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                children: [
                  for (final (group, icon, color) in [
                    ('parents', TmsIcons.heart, null),
                    ('children', TmsIcons.star, DesignColor.amber),
                    ('helpers', TmsIcons.shoppingBag, DesignColor.teal),
                  ]) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 10),
                      child: Row(
                        spacing: 10,
                        children: [
                          KitTile(icon, color: color, size: 32),
                          Expanded(
                            child: Text(
                              context.tr('household.$group'),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          KitCount(
                            people.where((r) => _group(r) == group).length,
                          ),
                        ],
                      ),
                    ),
                    KitList(
                      children: [
                        for (final member in people.where(
                          (r) => _group(r) == group,
                        ))
                          _MemberRow(
                            member: member,
                            points: space.availablePoints(
                              member.title.split(' ').first,
                            ),
                            onTap: () => _member(context, ref, space, member),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  DesignEntrance(
                    order: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => showHouseholdTablet(context),
                        child: KitCard(
                          child: Row(
                            spacing: 12,
                            children: [
                              const KitTile(
                                TmsIcons.tablet,
                                color: DesignColor.teal,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('household.tablet'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      context.tr('household.tablet_detail'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              KitStatus(
                                context.tr('household.on'),
                                KitColor.done,
                              ),
                            ],
                          ),
                        ),
                      ),
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

  String _group(WorkspaceRecord r) => switch (r.fields['householdRole']) {
    'head' || 'cohead' || 'spouse' => 'parents',
    'child' => 'children',
    _ => 'helpers',
  };
  Future<void> _member(
    BuildContext context,
    WidgetRef ref,
    LocalWorkspace space,
    WorkspaceRecord member,
  ) async {
    final action = await designSheet<String>(
      context,
      title: '',
      builder: (_) => HouseholdMemberSheet(member: member),
    );
    if (!context.mounted || action == null) return;
    if (action == 'task') {
      ref
          .read(familyTaskDraftProvider(space.id))
          .togglePerson(member.title.split(' ').first);
      TmsRoute.familyTask.open(context);
    } else {
      TmsRoute.conversation.open(context);
    }
  }
}

/// `.mem` row: avatar, name and role, points and a chevron.
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.points,
    required this.onTap,
  });
  final WorkspaceRecord member;
  final int points;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final (initials, color) = kitPerson(member.title);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 66),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            spacing: 12,
            children: [
              DesignAvatar(initials, size: 36, color: color),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      c.tr(
                        'household.roles.${member.fields['householdRole'] ?? 'child'}',
                      ),
                      style: TextStyle(color: c.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              KitPoints(points),
              Icon(TmsIcons.chevronNext, size: 16, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}
