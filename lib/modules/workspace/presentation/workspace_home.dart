import 'package:flutter/material.dart';

import '../../alumni/presentation/alumni_home_screen.dart';
import '../../church/presentation/church_home_screen.dart';
import '../../club/presentation/club_home_screen.dart';
import '../../committee/presentation/committee_home_screen.dart';
import '../../estate/presentation/estate_home_screen.dart';
import '../../event/presentation/event_home_screen.dart';
import '../../individual/presentation/individual_home_screen.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import '../../family/presentation/family_home_screen.dart';

/// The Home tab for a personal workspace: each role's own design screen.
class WorkspaceHome extends StatelessWidget {
  const WorkspaceHome({
    super.key,
    required this.workspace,
    required this.companyName,
  });

  final LocalWorkspace workspace;
  final String companyName;

  @override
  Widget build(BuildContext context) => switch (workspace.kind) {
    WorkspaceKind.individual => IndividualHomeScreen(workspace: workspace),
    WorkspaceKind.church => ChurchHomeScreen(workspace: workspace),
    WorkspaceKind.alumni => AlumniHomeScreen(workspace: workspace),
    WorkspaceKind.estate => EstateHomeScreen(workspace: workspace),
    WorkspaceKind.event => EventHomeScreen(workspace: workspace),
    WorkspaceKind.committee => CommitteeHomeScreen(workspace: workspace),
    WorkspaceKind.club => ClubHomeScreen(workspace: workspace),
    WorkspaceKind.family || WorkspaceKind.business => FamilyHomeScreen(
      workspace: workspace,
      companyName: companyName,
    ),
  };
}
