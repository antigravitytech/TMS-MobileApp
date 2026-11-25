import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

enum TmsRoute {
  splash('/'),
  welcome('/welcome'),
  setup('/setup'),
  personalize('/setup/details'),
  building('/setup/building'),
  signIn('/sign-in'),
  profileSetup('/profile/setup'),
  businessReady('/profile/setup/ready'),
  home('/home'),
  tasks('/tasks'),
  task('/tasks/detail'),
  newTask('/tasks/new'),
  approvals('/approvals'),
  search('/search'),
  chat('/chat'),
  conversation('/chat/conversation'),
  notifications('/notifications'),
  attendance('/attendance'),
  reports('/reports'),
  performance('/performance'),
  more('/more'),
  projects('/projects'),
  teams('/teams'),
  files('/files'),
  journal('/journal'),
  birthdays('/birthdays'),
  visitors('/visitors'),
  profile('/profile'),
  settings('/settings'),
  familyTask('/family/task/new'),
  kidHome('/family/kid'),
  workspacePlan('/workspace/plan');

  const TmsRoute(this.path);
  final String path;

  bool get isTab =>
      const {home, tasks, chat, approvals, more, workspacePlan}.contains(this);

  void open(BuildContext context) {
    if (name == context.router.current.name) return;
    if (isTab &&
        TmsRoute.values.any(
          (route) => route.name == context.router.current.name && route.isTab,
        )) {
      context.router.replacePath(path);
    } else {
      context.router.pushPath(path);
    }
  }

  void reset(BuildContext context) =>
      context.router.replaceAll([NamedRoute(name)]);
}
