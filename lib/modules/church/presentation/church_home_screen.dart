import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../specials/presentation/special_home_shell.dart';
import '../../specials/presentation/widgets/special_notices.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../../shared/kit/kit.dart';
import '../application/church_controller.dart';
import 'widgets/church_care.dart';
import 'widgets/church_giving.dart';
import 'widgets/church_overview.dart';
import 'widgets/church_services.dart';

/// Victory Chapel's home: seven tabs on the shared Specials shell.
class ChurchHomeScreen extends ConsumerWidget {
  const ChurchHomeScreen({
    super.key,
    required this.workspace,
    this.initial = ChurchTab.overview,
  });
  final LocalWorkspace workspace;
  final ChurchTab initial;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final args = (workspace.id, initial);
    final state = ref.watch(churchControllerProvider(args));
    final actions = ref.read(churchControllerProvider(args).notifier);
    final view = ref.watch(churchViewProvider(workspace.id));
    return SpecialHomeShell<ChurchTab>(
      workspace: workspace,
      logoColor: KitColor.avatar(1),
      tabs: ChurchTab.values,
      selected: state.tab,
      label: (t) => c.tr('church.tabs.${t.name}'),
      onTab: actions.tab,
      body: view == null
          ? const SizedBox()
          : switch (state.tab) {
              ChurchTab.overview => ChurchOverview(
                view: view,
                onTab: actions.tab,
              ),
              ChurchTab.services => ChurchServices(
                view: view,
                actions: actions,
              ),
              ChurchTab.giving => ChurchGiving(view: view, actions: actions),
              ChurchTab.units => ChurchUnits(view: view),
              ChurchTab.prayer => ChurchPrayer(
                view: view,
                state: state,
                actions: actions,
              ),
              ChurchTab.firstTimers => ChurchFirstTimers(
                view: view,
                actions: actions,
              ),
              ChurchTab.notices => SpecialNotices(
                workspaceId: workspace.id,
                notices: view.notices,
                members: view.members,
              ),
            },
    );
  }
}
