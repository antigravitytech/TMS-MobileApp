import 'package:flutter/widgets.dart';

import '../../bills/presentation/bills_screen.dart';
import '../../chores/presentation/chores_screen.dart';
import '../../alumni/application/alumni_controller.dart';
import '../../alumni/presentation/alumni_home_screen.dart';
import '../../church/application/church_controller.dart';
import '../../church/presentation/church_home_screen.dart';
import '../../club/application/club_controller.dart';
import '../../club/presentation/club_home_screen.dart';
import '../../committee/application/committee_controller.dart';
import '../../committee/presentation/committee_home_screen.dart';
import '../../estate/application/estate_controller.dart';
import '../../estate/presentation/estate_home_screen.dart';
import '../../event/application/event_controller.dart';
import '../../event/presentation/event_home_screen.dart';
import '../../family_plans/presentation/family_plans_screen.dart';
import '../../individual/presentation/clients_screen.dart';
import '../../individual/presentation/gigs_screen.dart';
import '../../individual/presentation/time_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../school/presentation/school_screen.dart';
import '../../shopping/presentation/shopping_screen.dart';
import '../../tasks/presentation/tasks_screen.dart';
import '../../visitors/presentation/visitors_screen.dart';
import '../../family/presentation/household_screen.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';

/// Sections with a dedicated prototype screen, or null for the generic
/// section list.
Widget? sectionScreen(LocalWorkspace workspace, WorkspaceSection section) =>
    switch (workspace.kind) {
      WorkspaceKind.individual => switch (section) {
        WorkspaceSection.gigs => GigsScreen(workspace: workspace),
        WorkspaceSection.time => TimeScreen(workspace: workspace),
        WorkspaceSection.clients => ClientsScreen(workspace: workspace),
        WorkspaceSection.proposals => ClientsScreen(
          workspace: workspace,
          proposals: true,
        ),
        WorkspaceSection.tasks => const TasksScreen(),
        _ => null,
      },
      WorkspaceKind.church => switch (section) {
        WorkspaceSection.services => ChurchHomeScreen(
          workspace: workspace,
          initial: ChurchTab.services,
        ),
        WorkspaceSection.giving => ChurchHomeScreen(
          workspace: workspace,
          initial: ChurchTab.giving,
        ),
        WorkspaceSection.units => ChurchHomeScreen(
          workspace: workspace,
          initial: ChurchTab.units,
        ),
        WorkspaceSection.prayers => ChurchHomeScreen(
          workspace: workspace,
          initial: ChurchTab.prayer,
        ),
        WorkspaceSection.firstTimers => ChurchHomeScreen(
          workspace: workspace,
          initial: ChurchTab.firstTimers,
        ),
        WorkspaceSection.notices => ChurchHomeScreen(
          workspace: workspace,
          initial: ChurchTab.notices,
        ),
        _ => null,
      },
      WorkspaceKind.alumni => switch (section) {
        WorkspaceSection.dues => AlumniHomeScreen(
          workspace: workspace,
          initial: AlumniTab.dues,
        ),
        WorkspaceSection.committees => AlumniHomeScreen(
          workspace: workspace,
          initial: AlumniTab.committees,
        ),
        WorkspaceSection.poll => AlumniHomeScreen(
          workspace: workspace,
          initial: AlumniTab.poll,
        ),
        WorkspaceSection.notices => AlumniHomeScreen(
          workspace: workspace,
          initial: AlumniTab.notices,
        ),
        WorkspaceSection.directory => AlumniHomeScreen(
          workspace: workspace,
          initial: AlumniTab.directory,
        ),
        _ => null,
      },
      WorkspaceKind.estate => switch (section) {
        WorkspaceSection.levies => EstateHomeScreen(
          workspace: workspace,
          initial: EstateTab.levies,
        ),
        WorkspaceSection.passes => EstateHomeScreen(
          workspace: workspace,
          initial: EstateTab.passes,
        ),
        WorkspaceSection.issues => EstateHomeScreen(
          workspace: workspace,
          initial: EstateTab.issues,
        ),
        WorkspaceSection.notices => EstateHomeScreen(
          workspace: workspace,
          initial: EstateTab.notices,
        ),
        WorkspaceSection.poll => EstateHomeScreen(
          workspace: workspace,
          initial: EstateTab.poll,
        ),
        _ => null,
      },
      WorkspaceKind.club => switch (section) {
        WorkspaceSection.sessions => ClubHomeScreen(
          workspace: workspace,
          initial: ClubTab.sessions,
        ),
        WorkspaceSection.fees => ClubHomeScreen(
          workspace: workspace,
          initial: ClubTab.fees,
        ),
        WorkspaceSection.attendance => ClubHomeScreen(
          workspace: workspace,
          initial: ClubTab.attendance,
        ),
        WorkspaceSection.notices => ClubHomeScreen(
          workspace: workspace,
          initial: ClubTab.notices,
        ),
        _ => null,
      },
      WorkspaceKind.committee => switch (section) {
        WorkspaceSection.meetings => CommitteeHomeScreen(
          workspace: workspace,
          initial: CommitteeTab.meetings,
        ),
        WorkspaceSection.actions => CommitteeHomeScreen(
          workspace: workspace,
          initial: CommitteeTab.actions,
        ),
        WorkspaceSection.minutes => CommitteeHomeScreen(
          workspace: workspace,
          initial: CommitteeTab.minutes,
        ),
        WorkspaceSection.decisions => CommitteeHomeScreen(
          workspace: workspace,
          initial: CommitteeTab.decisions,
        ),
        _ => null,
      },
      WorkspaceKind.event => switch (section) {
        WorkspaceSection.guests => EventHomeScreen(
          workspace: workspace,
          initial: EventTab.guests,
        ),
        WorkspaceSection.seating => EventHomeScreen(
          workspace: workspace,
          initial: EventTab.seating,
        ),
        WorkspaceSection.vendors => EventHomeScreen(
          workspace: workspace,
          initial: EventTab.vendors,
        ),
        WorkspaceSection.programme => EventHomeScreen(
          workspace: workspace,
          initial: EventTab.programme,
        ),
        _ => null,
      },
      WorkspaceKind.family => switch (section) {
        WorkspaceSection.bills => BillsScreen(workspace: workspace),
        WorkspaceSection.rewards => RewardsScreen(workspace: workspace),
        WorkspaceSection.chores => ChoresScreen(workspace: workspace),
        WorkspaceSection.shopping => ShoppingScreen(workspace: workspace),
        WorkspaceSection.plans => FamilyPlansScreen(workspace: workspace),
        WorkspaceSection.school => SchoolScreen(workspace: workspace),
        WorkspaceSection.household => const HouseholdScreen(),
        WorkspaceSection.visitors => const VisitorsScreen(),
        _ => null,
      },
      _ => null,
    };
