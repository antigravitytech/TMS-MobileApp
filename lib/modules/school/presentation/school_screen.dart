import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../../../router/tms_routes.dart';
import '../application/school_controller.dart';
import '../../../shared/kit/kit.dart';
import 'widgets/school_widgets.dart';
import 'widgets/school_add_sheet.dart';

class SchoolScreen extends ConsumerWidget {
  const SchoolScreen({super.key, required this.workspace});
  final LocalWorkspace workspace;
  Future<void> feedback(BuildContext c, Future<bool> result, String key) async {
    final ok = await result;
    if (c.mounted) designToast(c, c.tr(ok ? key : 'workspaces.try_again'));
  }

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final d = ref.watch(schoolControllerProvider(workspace.id));
    final visible = d.visible;
    final open = visible.where((r) => !r.done).toList();
    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: WorkspaceNavigation(
        kind: WorkspaceKind.family,
        active: TmsRoute.workspacePlan,
        section: WorkspaceSection.school,
        badges: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workspace.name,
                              style: TextStyle(fontSize: 12, color: c.muted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.tr('school.title'),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox.square(
                        dimension: 44,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: DesignColor.purple,
                            foregroundColor: DesignColor.ink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          tooltip: c.tr('school.add'),
                          onPressed: () => showSchoolAdd(c, d),
                          icon: const Icon(TmsIcons.add),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    c.tr('school.intro'),
                    style: TextStyle(color: c.muted, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 10,
                      children: [
                        SchoolChildChip(
                          name: c.tr('family.everyone'),
                          initials: kitPerson(_head(workspace)).$1,
                          color: DesignColor.teal,
                          selected: d.child.isEmpty,
                          onTap: () => d.select(''),
                        ),
                        for (final child in _children(workspace))
                          SchoolChildChip(
                            name: child,
                            initials: kitPerson(child).$1,
                            color: kitPerson(child).$2,
                            selected: d.child == child,
                            onTap: () => d.select(child),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 100),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: c.panel,
                              border: Border.all(color: c.outline),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${[open.where((r) => r.type == 'hw').length, d.checked ? 0 : 1, open.where((r) => r.group == 'od').length, open.where((r) => r.group == 'wk').length][i]}',
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                    color: [
                                      c.foreground,
                                      c.lavender,
                                      DesignColor.red,
                                      DesignColor.amber,
                                    ][i],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c.tr(
                                    [
                                      'school.assignments',
                                      'school.waiting',
                                      'school.overdue',
                                      'school.this_week',
                                    ][i],
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.3,
                                    color: c.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (!d.checked && d.child != 'Ada')
                    SchoolReview(
                      onApprove: () =>
                          feedback(c, d.review(true), 'school.approved'),
                      onRedo: () =>
                          feedback(c, d.review(false), 'school.returned'),
                    ),
                  for (final group in ['od', 'wk', 'later'])
                    if (visible.any((r) => r.group == group)) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 6),
                        child: Row(
                          children: [
                            Text(
                              c.tr('school.group_$group').toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: group == 'od'
                                    ? DesignColor.red
                                    : c.muted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: c.raised,
                              child: Text(
                                '${open.where((r) => r.group == group).length}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final (i, item)
                          in visible.where((r) => r.group == group).indexed)
                        Padding(
                          key: ValueKey(item.id),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DesignEntrance(
                            order: i,
                            child: SchoolItemCard(
                              item: item,
                              onToggle: () =>
                                  feedback(c, d.toggle(item), 'school.updated'),
                            ),
                          ),
                        ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The household's children by first name, as the chips show them.
List<String> _children(LocalWorkspace space) => [
  for (final m in space.items(WorkspaceSection.household))
    if (m.fields['householdRole'] == 'child') m.title.split(' ').first,
];

/// The head of the house, whose initials stand for "Everyone".
String _head(LocalWorkspace space) =>
    space
        .items(WorkspaceSection.household)
        .where((m) => m.fields['householdRole'] == 'head')
        .firstOrNull
        ?.title ??
    space.name;
