import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../../shared/kit/kit.dart';
import '../../workspace/presentation/widgets/workspace_quick_add.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';

/// The Specials home layout: logo header, tab chips on one page, quick add
/// and the Specials bottom bar. Each community supplies its tabs and body.
class SpecialHomeShell<T> extends StatelessWidget {
  const SpecialHomeShell({
    super.key,
    required this.workspace,
    required this.logoColor,
    required this.tabs,
    required this.selected,
    required this.label,
    required this.onTab,
    required this.body,
    this.logo,
  });
  final LocalWorkspace workspace;
  final Color logoColor;

  /// Logo text; defaults to the workspace's initials.
  final String? logo;
  final List<T> tabs;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onTab;
  final Widget body;

  @override
  Widget build(BuildContext c) {
    final name = workspaceName(c, workspace);
    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: WorkspaceQuickAdd(kind: workspace.kind),
      bottomNavigationBar: WorkspaceNavigation(
        kind: workspace.kind,
        active: TmsRoute.home,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Row(
                spacing: 10,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: logoColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      logo ?? kitPerson(name).$1,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: DesignColor.ink,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workspace.kind.label(c),
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      KitIconButton(
                        icon: TmsIcons.notifications,
                        tooltip: c.tr('common.notifications'),
                        onPressed: () => TmsRoute.notifications.open(c),
                      ),
                      const Positioned(
                        right: 10,
                        top: 10,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: DesignColor.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            KitTabs(
              children: [
                for (final t in tabs)
                  KitChip(
                    label: label(t),
                    selected: selected == t,
                    onTap: () => onTab(t),
                  ),
              ],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: DesignMotion.fast,
                child: KeyedSubtree(key: ValueKey(selected), child: body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
