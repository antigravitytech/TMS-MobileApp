import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../specials/presentation/special_home_shell.dart';
import '../../specials/presentation/widgets/special_widgets.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit.dart';
import '../application/committee_controller.dart';
import 'widgets/committee_minutes.dart';
import 'widgets/committee_tabs.dart';

/// Harvest Planning Committee's home: five tabs on the shared Specials shell.
class CommitteeHomeScreen extends ConsumerWidget {
  const CommitteeHomeScreen({
    super.key,
    required this.workspace,
    this.initial = CommitteeTab.overview,
  });
  final LocalWorkspace workspace;
  final CommitteeTab initial;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final args = (workspace.id, initial);
    final tab = ref.watch(committeeControllerProvider(args));
    final actions = ref.read(committeeControllerProvider(args).notifier);
    final view = ref.watch(committeeViewProvider(workspace.id));
    return SpecialHomeShell<CommitteeTab>(
      workspace: workspace,
      logoColor: KitColor.avatar(7),
      logo: _logo(workspace.name),
      tabs: CommitteeTab.values,
      selected: tab,
      label: (t) => c.tr('committee.tabs.${t.name}'),
      onTab: actions.tab,
      body: view == null
          ? const SizedBox()
          : switch (tab) {
              CommitteeTab.overview => CommitteeOverview(
                view: view,
                onTab: actions.tab,
              ),
              CommitteeTab.meetings => SpecialMeetingList(
                workspace: workspace,
                section: WorkspaceSection.meetings,
                records: view.upcoming,
                replies: meetingReplies,
                copy: 'committee.meetings',
              ),
              CommitteeTab.actions => SpecialStageList(
                workspace: workspace,
                section: WorkspaceSection.actions,
                records: view.actions,
                stages: actionStages,
                copy: 'committee.actions',
              ),
              CommitteeTab.minutes => CommitteeMinutes(
                view: view,
                actions: actions,
              ),
              CommitteeTab.decisions => SpecialPoll(
                workspace: workspace,
                poll: view.decision,
                voters: 6,
                section: WorkspaceSection.decisions,
                intro: 'committee.decisions_intro',
              ),
            },
    );
  }
}

/// First letters of the name's first and last words ("Harvest Planning
/// Committee" → "HC"), as the prototype's logo shows.
String? _logo(String name) {
  final words = name.split(' ').where((w) => w.isNotEmpty).toList();
  if (words.length < 2) return null;
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
