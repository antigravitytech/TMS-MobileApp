import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit.dart';
import '../../../shared/kit/kit_visuals.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../application/gigs_controller.dart';
import 'widgets/gig_card.dart';

/// Template icon and tile tint, in catalog order (`null` is the lavender tile).
const _templates = <(IconData, Color?)>[
  (TmsIcons.edit, null),
  (TmsIcons.laptop, DesignColor.blue),
  (TmsIcons.calendar, DesignColor.teal),
  (TmsIcons.camera, DesignColor.red),
  (TmsIcons.barChart, DesignColor.amber),
  (TmsIcons.shoppingCart, DesignColor.green),
  (TmsIcons.work, null),
  (TmsIcons.school, DesignColor.blue),
  (TmsIcons.chat, DesignColor.teal),
  (TmsIcons.heart, DesignColor.red),
];

class GigsScreen extends ConsumerWidget {
  const GigsScreen({super.key, required this.workspace});
  final LocalWorkspace workspace;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final gigs = ref.watch(gigsProvider(workspace.id));
    final actions = ref.read(gigsControllerProvider(workspace.id));
    Future<void> start(int i) async {
      final key = 'studio.gigs.g$i';
      final name = c.tr('$key.name');
      final ok = await actions.start(
        name: name,
        description: c.tr('$key.description'),
        milestones: [for (var j = 0; j < 3; j++) c.tr('$key.m$j')],
        client: c.tr('individual.new_client'),
      );
      if (!c.mounted) return;
      designToast(
        c,
        ok
            ? c.tr('studio.gig_started', namedArgs: {'name': name})
            : c.tr('workspaces.try_again'),
      );
    }

    Widget heading(String title, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          ?trailing,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: const WorkspaceNavigation(
        kind: WorkspaceKind.individual,
        active: TmsRoute.workspacePlan,
        section: WorkspaceSection.gigs,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitHeader(
              large: true,
              title: c.tr('workspaces.sections.gigs.title'),
              subtitle: workspaceName(c, workspace),
              action: KitIconButton(
                primary: true,
                icon: TmsIcons.add,
                tooltip: c.tr('workspaces.sections.gigs.add'),
                onPressed: () =>
                    designToast(c, c.tr('individual.pick_template')),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 30),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.tr('studio.start_gig'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          c.tr(
                            'individual.templates',
                            namedArgs: {'n': '$gigTemplateCount'},
                          ),
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 182,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: gigTemplateCount,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => DesignEntrance(
                        order: i,
                        child: _Template(index: i, onTap: () => start(i)),
                      ),
                    ),
                  ),
                  heading(
                    c.tr('individual.running'),
                    trailing: KitCount(gigs.length),
                  ),
                  if (gigs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: KitCard(
                        child: Text(
                          c.tr('workspaces.sections.gigs.empty'),
                          style: TextStyle(color: c.muted),
                        ),
                      ),
                    ),
                  for (final (i, gig) in gigs.indexed)
                    Padding(
                      key: ValueKey(gig.id),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: DesignEntrance(
                        order: i,
                        child: GigCard(
                          gig: gig,
                          onMilestone: (m) async {
                            final ok = await actions.toggleMilestone(gig, m);
                            if (!ok && c.mounted) {
                              designToast(c, c.tr('workspaces.try_again'));
                            }
                          },
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
}

/// `.gtpl`: a 150px template card in the horizontal rail.
class _Template extends StatelessWidget {
  const _Template({required this.index, required this.onTap});
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final (icon, color) = _templates[index];
    final key = 'studio.gigs.g$index';
    return Material(
      color: c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              KitTile(icon, color: color, size: 36),
              Text(
                c.tr('$key.name'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                c.tr('$key.description'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, height: 1.4, color: c.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
