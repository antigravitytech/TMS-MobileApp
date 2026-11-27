part of 'workspace_ui.dart';

class WorkspaceNavigation extends StatelessWidget {
  const WorkspaceNavigation({
    super.key,
    required this.kind,
    required this.active,
    this.section,
    this.onSection,
    this.badges = false,
  });
  final WorkspaceKind kind;
  final bool badges;
  final TmsRoute active;
  final WorkspaceSection? section;
  final ValueChanged<WorkspaceSection>? onSection;

  @override
  Widget build(BuildContext context) {
    final home = (
      TmsRoute.home,
      'common.home',
      kind == WorkspaceKind.family ? TmsIcons.home : TmsIcons.dashboard,
      0,
    );
    const more = (TmsRoute.more, 'common.more', TmsIcons.more, 0);
    final chat = (TmsRoute.chat, 'common.chat', TmsIcons.chat, badges ? 4 : 0);
    final sections = switch (kind) {
      WorkspaceKind.individual => [
        WorkspaceSection.gigs,
        WorkspaceSection.time,
        WorkspaceSection.invoices,
      ],
      WorkspaceKind.family => [
        WorkspaceSection.chores,
        WorkspaceSection.school,
      ],
      _ => <WorkspaceSection>[],
    };
    String label(WorkspaceSection s) => s == WorkspaceSection.time
        ? 'more.tools.time'
        : 'workspaces.sections.${s.name}.title';
    final List<DesignTab> tabs = switch (kind) {
      WorkspaceKind.business => DesignTabs.companyTabs,
      WorkspaceKind.individual || WorkspaceKind.family => [
        home,
        for (final s in sections)
          (
            TmsRoute.workspacePlan,
            label(s),
            s.icon,
            badges ? (s == WorkspaceSection.chores ? 2 : 1) : 0,
          ),
        if (kind == WorkspaceKind.family) chat,
        more,
      ],
      _ => [
        home,
        (TmsRoute.tasks, 'navigation.my_tasks', TmsIcons.checkSquare, 0),
        chat,
        (TmsRoute.approvals, 'more.tools.review', TmsIcons.checkCircle, 0),
        more,
      ],
    };
    return DesignTabs(
      active: active,
      items: tabs,
      activeLabel: active == TmsRoute.workspacePlan && section != null
          ? label(section!)
          : null,
      onSelect: (tab) {
        if (tab.$1 != TmsRoute.workspacePlan) {
          tab.$1.open(context);
          return;
        }
        final next = sections.firstWhere((s) => label(s) == tab.$2);
        if (onSection != null) {
          onSection!(next);
        } else {
          next.open(context, replace: true);
        }
      },
    );
  }
}
