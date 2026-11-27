import 'package:auto_route/auto_route.dart';
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
import '../application/family_plan_controller.dart';
import 'widgets/family_plan_builder.dart';
import 'widgets/family_plan_card.dart';

class FamilyPlansScreen extends ConsumerWidget {
  const FamilyPlansScreen({super.key, required this.workspace});
  final LocalWorkspace workspace;
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final d = ref.watch(familyPlanControllerProvider(workspace.id));
    return Scaffold(
      backgroundColor: const Color(0xff1d1f2a),
      bottomNavigationBar: const WorkspaceNavigation(
        kind: WorkspaceKind.family,
        active: TmsRoute.home,
        badges: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Row(
                children: [
                  DesignIcon(
                    icon: TmsIcons.chevronBack,
                    label: c.tr('common.back'),
                    onPressed: () => c.router.maybePop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.tr('family_plans.title'),
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          c.tr('family_plans.subtitle'),
                          style: TextStyle(color: c.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                children: [
                  if (d.plan != null) ...[
                    FamilyPlanCard(
                      plan: d.plan!,
                      onToggle: (step) async {
                        final ok = await d.toggleDone(step);
                        if (!ok && c.mounted) {
                          designToast(c, c.tr('workspaces.try_again'));
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    c.tr('family_plans.start').toUpperCase(),
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var row = 0; row < 3; row++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          for (var col = 0; col < 2; col++)
                            Expanded(
                              child: FamilyPlanTemplate(
                                index: row * 2 + col,
                                onTap: () {
                                  d.start(row * 2 + col);
                                  showFamilyPlanBuilder(c, d);
                                },
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
}

class FamilyPlanTemplate extends StatelessWidget {
  const FamilyPlanTemplate({
    super.key,
    required this.index,
    required this.onTap,
  });
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final color = [
      DesignColor.blue,
      DesignColor.red,
      DesignColor.amber,
      DesignColor.teal,
      DesignColor.green,
      DesignColor.purple,
    ][index];
    return Material(
      color: c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: c.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 164,
          child: Stack(
            children: [
              if (index != 5)
                Positioned(
                  right: -20,
                  bottom: -24,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: .16),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: index == 5
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  mainAxisAlignment: index == 5
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    if (index == 5) const SizedBox(width: double.infinity),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: color.withValues(alpha: .25)),
                      ),
                      child: Icon(
                        [
                          TmsIcons.map,
                          TmsIcons.birthday,
                          TmsIcons.school,
                          TmsIcons.home,
                          TmsIcons.christmas,
                          TmsIcons.add,
                        ][index],
                        color: color,
                        size: 21,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.tr('family_plans.${familyPlanTemplates[index]}.title'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (index != 5) ...[
                      const SizedBox(height: 6),
                      Text(
                        c.tr(
                          'family_plans.${familyPlanTemplates[index]}.description',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
