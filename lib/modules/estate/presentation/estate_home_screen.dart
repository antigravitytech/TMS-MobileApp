import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../specials/presentation/special_home_shell.dart';
import '../../specials/presentation/widgets/special_widgets.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit.dart';
import '../application/estate_controller.dart';
import 'widgets/estate_tabs.dart';

/// Palm Grove Estate's home: six tabs on the shared Specials shell.
class EstateHomeScreen extends ConsumerWidget {
  const EstateHomeScreen({
    super.key,
    required this.workspace,
    this.initial = EstateTab.overview,
  });
  final LocalWorkspace workspace;
  final EstateTab initial;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final args = (workspace.id, initial);
    final state = ref.watch(estateControllerProvider(args));
    final actions = ref.read(estateControllerProvider(args).notifier);
    final view = ref.watch(estateViewProvider(workspace.id));
    return SpecialHomeShell<EstateTab>(
      workspace: workspace,
      logoColor: KitColor.avatar(3),
      tabs: EstateTab.values,
      selected: state.tab,
      label: (t) => c.tr('estate.tabs.${t.name}'),
      onTab: actions.tab,
      body: view == null
          ? const SizedBox()
          : switch (state.tab) {
              EstateTab.overview => EstateOverview(
                view: view,
                onTab: actions.tab,
              ),
              EstateTab.levies => SpecialCollectionTab(
                workspace: workspace,
                section: WorkspaceSection.levies,
                records: view.levies,
                target: view.target,
                intro: 'estate.levies_intro',
                record: 'estate.record_levy',
                add: 'estate.add_house',
              ),
              EstateTab.passes => EstatePasses(view: view, actions: actions),
              EstateTab.issues => SpecialStageList(
                workspace: workspace,
                section: WorkspaceSection.issues,
                records: view.issues,
                stages: issueStages,
                copy: 'estate.issues',
              ),
              EstateTab.notices => SpecialNotices(
                workspaceId: workspace.id,
                notices: view.notices,
                members: view.houses,
              ),
              EstateTab.poll => SpecialPoll(
                workspace: workspace,
                poll: view.poll,
                voters: 6,
              ),
            },
    );
  }
}
