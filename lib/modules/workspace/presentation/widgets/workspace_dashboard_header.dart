import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../router/tms_routes.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../domain/workspace_kind.dart';
import '../../domain/local_workspace.dart';
import 'workspace_ui.dart';

class WorkspaceOverviewRail extends StatelessWidget {
  const WorkspaceOverviewRail({
    super.key,
    required this.workspace,
    this.section,
    this.select,
  });
  final LocalWorkspace workspace;
  final WorkspaceSection? section;
  final ValueChanged<WorkspaceSection>? select;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      spacing: 8,
      children: [
        DesignPill(
          context.tr('dashboard.overview'),
          selected: section == null,
          onTap: () => TmsRoute.home.open(context),
        ),
        for (final s in workspace.kind.sections)
          DesignPill(
            s.label(context),
            selected: section == s,
            onTap: () {
              if (select != null) {
                select!(s);
              } else {
                s.open(context);
              }
            },
          ),
      ],
    ),
  );
}
