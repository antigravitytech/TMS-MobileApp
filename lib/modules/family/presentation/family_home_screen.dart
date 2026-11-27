import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../../workspace/presentation/widgets/workspace_quick_add.dart';
import '../../workspace/presentation/widgets/workspace_picker.dart';
import 'widgets/family_home_sections.dart';
import 'widgets/family_home_metric.dart';

class FamilyHomeScreen extends ConsumerWidget {
  const FamilyHomeScreen({
    super.key,
    required this.workspace,
    required this.companyName,
  });
  final LocalWorkspace workspace;
  final String companyName;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = workspace.records;
    final needs = records
        .where(
          (r) =>
              r.id.endsWith('fractions') ||
              r.id.endsWith('bill') ||
              r.id.endsWith('redo'),
        )
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xff1d1f2a),
      floatingActionButton: const WorkspaceQuickAdd(kind: WorkspaceKind.family),
      bottomNavigationBar: const WorkspaceNavigation(
        kind: WorkspaceKind.family,
        badges: true,
        active: TmsRoute.home,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => showWorkspacePicker(context, ref, companyName),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DesignColor.teal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        TmsIcons.home,
                        color: DesignColor.ink,
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.MMMMEEEEd(
                            context.locale.toString(),
                          ).format(DateTime.now()),
                          style: TextStyle(fontSize: 11, color: context.muted),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          workspace.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DesignIcon(
                    icon: TmsIcons.notifications,
                    label: context.tr('common.notifications'),
                    onPressed: () => TmsRoute.notifications.open(context),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => TmsRoute.household.open(context),
                    child: const DesignAvatar(
                      'IM',
                      color: DesignColor.teal,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                children: [
                  Text(
                    context.tr('family_reference.greeting'),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('family_reference.needs_today'),
                    style: TextStyle(color: context.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      for (final (key, icon, color, section) in [
                        (
                          'dashboard.add_task',
                          TmsIcons.add,
                          DesignColor.purple,
                          WorkspaceSection.chores,
                        ),
                        (
                          'more.tools.school',
                          TmsIcons.school,
                          DesignColor.blue,
                          WorkspaceSection.school,
                        ),
                        (
                          'family_reference.new_plan',
                          TmsIcons.calendar,
                          DesignColor.amber,
                          WorkspaceSection.plans,
                        ),
                        (
                          'more.tools.shopping',
                          TmsIcons.shoppingCart,
                          DesignColor.teal,
                          WorkspaceSection.shopping,
                        ),
                      ])
                        Expanded(
                          child: GestureDetector(
                            onTap: () => section == WorkspaceSection.chores
                                ? TmsRoute.familyTask.open(context)
                                : section.open(context),
                            child: Column(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: color.withValues(alpha: .25),
                                    ),
                                  ),
                                  child: Icon(icon, color: color, size: 23),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr(key),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _title(context, 'workspaces.today_at_home'),
                  const SizedBox(height: 14),
                  for (var row = 0; row < 2; row++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        spacing: 10,
                        children: [
                          for (var col = 0; col < 2; col++)
                            Expanded(
                              child: FamilyHomeMetric(
                                index: row * 2 + col,
                                workspace: workspace,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  _title(context, 'dashboard.needs_you', count: 4),
                  const SizedBox(height: 14),
                  DesignCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final r in needs)
                          FamilyRecordRow(record: r, workspace: workspace),
                        FamilyShoppingRow(workspace: workspace),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  DesignTitle(
                    context.tr('family_home.points_rewards'),
                    action: context.tr('workspaces.points_board'),
                    onTap: () => WorkspaceSection.rewards.open(context),
                  ),
                  const SizedBox(height: 14),
                  FamilyRewardPanel(workspace: workspace),
                  const SizedBox(height: 30),
                  DesignTitle(
                    context.tr('family_home.errands_money'),
                    action: context.tr('family_home.say_errand'),
                    onTap: () => WorkspaceSection.errands.open(context),
                  ),
                  const SizedBox(height: 14),
                  FamilyErrandsPanel(workspace: workspace),
                  const SizedBox(height: 12),
                  DesignCard(
                    color: DesignColor.purple.withValues(alpha: .18),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: DesignColor.purple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            TmsIcons.microphone,
                            color: DesignColor.ink,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr('family_reference.say'),
                            style: const TextStyle(fontSize: 12, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _title(context, 'family_home.coming_up', count: 5),
                  const SizedBox(height: 14),
                  FamilyUpcomingPanel(workspace: workspace),
                  const SizedBox(height: 12),
                  DesignCard(
                    onTap: () => TmsRoute.kidHome.open(context),
                    child: Row(
                      children: [
                        const DesignAvatar(
                          'TI',
                          size: 28,
                          color: DesignColor.amber,
                        ),
                        const DesignAvatar(
                          'AI',
                          size: 28,
                          color: DesignColor.green,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          context.tr('family_reference.kid'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _title(BuildContext c, String key, {int? count}) => Row(
    children: [
      Text(
        c.tr(key),
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      if (count != null) ...[
        const SizedBox(width: 6),
        CircleAvatar(
          radius: 10,
          backgroundColor: c.raised,
          child: Text('$count', style: const TextStyle(fontSize: 10)),
        ),
      ],
    ],
  );
}
