import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../specials/presentation/special_home_shell.dart';
import '../../specials/presentation/widgets/special_widgets.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../../shared/kit/kit.dart';
import '../application/alumni_controller.dart';
import 'widgets/alumni_groups.dart';
import 'widgets/alumni_money.dart';

/// The Class of 2006 home: six tabs on the shared Specials shell.
class AlumniHomeScreen extends ConsumerWidget {
  const AlumniHomeScreen({
    super.key,
    required this.workspace,
    this.initial = AlumniTab.overview,
  });
  final LocalWorkspace workspace;
  final AlumniTab initial;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final args = (workspace.id, initial);
    final tab = ref.watch(alumniControllerProvider(args));
    final actions = ref.read(alumniControllerProvider(args).notifier);
    final view = ref.watch(alumniViewProvider(workspace.id));
    final year = RegExp(r'\d{4}').firstMatch(workspace.name)?.group(0);
    return SpecialHomeShell<AlumniTab>(
      workspace: workspace,
      logoColor: KitColor.avatar(2),
      logo: year?.substring(2),
      tabs: AlumniTab.values,
      selected: tab,
      label: (t) => c.tr('alumni.tabs.${t.name}'),
      onTab: actions.tab,
      body: view == null
          ? const SizedBox()
          : switch (tab) {
              AlumniTab.overview => AlumniOverview(
                view: view,
                onTab: actions.tab,
              ),
              AlumniTab.dues => AlumniDues(view: view),
              AlumniTab.committees => AlumniCommittees(
                view: view,
                actions: actions,
              ),
              AlumniTab.poll => SpecialPoll(
                workspace: workspace,
                poll: view.poll,
                voters: view.classmates.length + 1,
              ),
              AlumniTab.notices => SpecialNotices(
                workspaceId: workspace.id,
                notices: view.notices,
                members: view.size,
              ),
              AlumniTab.directory => AlumniDirectory(
                view: view,
                actions: actions,
              ),
            },
    );
  }
}
