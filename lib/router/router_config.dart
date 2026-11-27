import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/environment.dart';
import '../modules/authentication/application/account_session.dart';
import '../modules/authentication/presentation/account_link_screen.dart';
import '../modules/authentication/presentation/oauth_callback_screen.dart';
import '../modules/authentication/presentation/widgets/account_action_form.dart';
import '../modules/approvals/presentation/approvals_screen.dart';
import '../modules/attendance/presentation/attendance_screen.dart';
import '../modules/authentication/presentation/account_screen.dart';
import '../modules/authentication/presentation/sign_in_screen.dart';
import '../modules/authentication/presentation/welcome_screen.dart';
import '../modules/birthdays/presentation/birthdays_screen.dart';
import '../modules/chat/presentation/chat_screens.dart';
import '../modules/files/presentation/files_screen.dart';
import '../modules/home/presentation/home_screen.dart';
import '../modules/journal/presentation/journal_screen.dart';
import '../modules/notifications/presentation/notifications_screen.dart';
import '../modules/onboarding/presentation/account_screens.dart';
import '../modules/onboarding/presentation/business_ready_screen.dart';
import '../modules/onboarding/presentation/workspace_personalization.dart';
import '../modules/onboarding/presentation/building_screen.dart';
import '../modules/profile/presentation/profile_screen.dart';
import '../modules/projects/presentation/projects_screen.dart';
import '../modules/reports/presentation/reports_screen.dart';
import '../modules/search/presentation/search_screen.dart';
import '../modules/settings/presentation/settings_screen.dart';
import '../modules/tasks/presentation/task_forms.dart';
import '../modules/tasks/presentation/task_detail_screen.dart';
import '../modules/tasks/presentation/tasks_screen.dart';
import '../modules/teams/presentation/teams_screen.dart';
import '../modules/visitors/presentation/visitors_screen.dart';
import '../modules/workspace/presentation/more_screen.dart';
import '../modules/family/presentation/family_task_screen.dart';
import '../modules/family/presentation/household_screen.dart';
import '../modules/family/presentation/kid_home_screen.dart';
import '../modules/workspace/presentation/workspace_plan_screen.dart';
import '../shared/design/design_tokens.dart';
import 'tms_routes.dart';

final routerConfigProvider = Provider<AppRouter>((ref) {
  final router = AppRouter(
    liveDestination: ref.watch(environmentProvider).isLive
        ? () => ref.read(accountSessionProvider) == null
              ? TmsRoute.splash
              : TmsRoute.account
        : null,
  );
  ref.onDispose(router.dispose);
  return router;
});

class AppRouter extends RootStackRouter {
  AppRouter({this.liveDestination});

  final TmsRoute Function()? liveDestination;
  static const _liveRoutes = {
    TmsRoute.splash,
    TmsRoute.welcome,
    TmsRoute.signIn,
    TmsRoute.setup,
    TmsRoute.personalize,
    TmsRoute.resetPassword,
    TmsRoute.verifyEmail,
    TmsRoute.confirmEmailChange,
    TmsRoute.unsubscribe,
    TmsRoute.oauthCallback,
  };

  @override
  List<AutoRouteGuard> get guards => [
    if (liveDestination != null)
      AutoRouteGuard.redirect((resolver) {
        final destination = liveDestination!();
        final allowed =
            _liveRoutes.any((route) => route.name == resolver.routeName) ||
            (destination == TmsRoute.account &&
                {
                  TmsRoute.account.name,
                  TmsRoute.profileSetup.name,
                }.contains(resolver.routeName));
        return allowed ? null : NamedRoute(destination.name);
      }),
  ];

  static const screens = <TmsRoute, Widget>{
    TmsRoute.splash: SplashScreen(),
    TmsRoute.welcome: WelcomeScreen(),
    TmsRoute.setup: WorkspaceSetupScreen(),
    TmsRoute.building: BuildingScreen(),
    TmsRoute.personalize: WorkspacePersonalization(),
    TmsRoute.signIn: SignInScreen(),
    TmsRoute.account: AccountScreen(),
    TmsRoute.resetPassword: AccountLinkScreen(AccountAction.reset),
    TmsRoute.verifyEmail: AccountLinkScreen(AccountAction.verify),
    TmsRoute.confirmEmailChange: AccountLinkScreen(
      AccountAction.confirmEmailChange,
    ),
    TmsRoute.unsubscribe: AccountLinkScreen(AccountAction.unsubscribe),
    TmsRoute.oauthCallback: OAuthCallbackScreen(),
    TmsRoute.profileSetup: ProfileSetupScreen(),
    TmsRoute.businessReady: BusinessReadyScreen(),
    TmsRoute.home: HomeScreen(),
    TmsRoute.tasks: TasksScreen(),
    TmsRoute.task: TaskDetailScreen(),
    TmsRoute.newTask: NewTaskScreen(),
    TmsRoute.approvals: ApprovalsScreen(),
    TmsRoute.search: SearchScreen(),
    TmsRoute.chat: ChatScreen(),
    TmsRoute.conversation: ConversationScreen(),
    TmsRoute.notifications: NotificationsScreen(),
    TmsRoute.attendance: AttendanceScreen(),
    TmsRoute.reports: ReportsScreen(),
    TmsRoute.performance: PerformanceScreen(),
    TmsRoute.more: MoreScreen(),
    TmsRoute.projects: ProjectsScreen(),
    TmsRoute.teams: TeamsScreen(),
    TmsRoute.files: FilesScreen(),
    TmsRoute.journal: JournalScreen(),
    TmsRoute.birthdays: BirthdaysScreen(),
    TmsRoute.visitors: VisitorsScreen(),
    TmsRoute.profile: ProfileScreen(),
    TmsRoute.settings: SettingsScreen(),
    TmsRoute.household: HouseholdScreen(),
    TmsRoute.familyTask: FamilyTaskScreen(),
    TmsRoute.kidHome: KidHomeScreen(),
    TmsRoute.workspacePlan: WorkspacePlanScreen(),
  };

  @override
  RouteType get defaultRouteType => RouteType.custom(
    duration: DesignMotion.page,
    reverseDuration: DesignMotion.fast,
    transitionsBuilder: (context, primary, _, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final position = Tween(
        begin: const Offset(.04, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: DesignMotion.curve)).animate(primary);
      final fade = Tween(begin: .65, end: 1.0).animate(primary);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: position, child: child),
      );
    },
  );

  @override
  List<AutoRoute> get routes => [
    for (final route in TmsRoute.values)
      AutoRoute.named(
        route.name,
        (_, _) => screens[route]!,
        type: route == TmsRoute.welcome
            ? RouteType.custom(
                duration: const Duration(milliseconds: 700),
                transitionsBuilder: splashReveal,
              )
            : null,
        path: route.path,
        initial: route == TmsRoute.splash,
        fullMatch: true,
      ),
  ];
}
