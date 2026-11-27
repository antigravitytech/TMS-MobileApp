import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../specials/presentation/special_home_shell.dart';
import '../../specials/presentation/widgets/special_widgets.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit.dart';
import '../application/club_controller.dart';
import 'widgets/club_tabs.dart';

/// Ikoyi Sunday League FC's home: five tabs on the shared Specials shell.
class ClubHomeScreen extends ConsumerWidget {
  const ClubHomeScreen({
    super.key,
    required this.workspace,
    this.initial = ClubTab.overview,
  });
  final LocalWorkspace workspace;
  final ClubTab initial;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final args = (workspace.id, initial);
    final tab = ref.watch(clubControllerProvider(args));
    final actions = ref.read(clubControllerProvider(args).notifier);
    final view = ref.watch(clubViewProvider(workspace.id));
    return SpecialHomeShell<ClubTab>(
      workspace: workspace,
      logoColor: KitColor.avatar(6),
      logo: _logo(workspace.name),
      tabs: ClubTab.values,
      selected: tab,
      label: (t) => c.tr('club.tabs.${t.name}'),
      onTab: actions.tab,
      body: view == null
          ? const SizedBox()
          : switch (tab) {
              ClubTab.overview => ClubOverview(view: view, onTab: actions.tab),
              ClubTab.sessions => SpecialMeetingList(
                workspace: workspace,
                section: WorkspaceSection.sessions,
                records: view.upcoming,
                replies: sessionReplies,
                copy: 'club.sessions',
              ),
              ClubTab.fees => SpecialCollectionTab(
                workspace: workspace,
                section: WorkspaceSection.fees,
                records: view.fees,
                target: view.target,
                intro: 'club.fees_intro',
                record: 'club.record_fee',
                add: 'club.add_fee',
              ),
              ClubTab.attendance => ClubAttendance(
                workspace: workspace,
                view: view,
                actions: actions,
              ),
              ClubTab.notices => SpecialNotices(
                workspaceId: workspace.id,
                notices: view.notices,
                members: view.members,
              ),
            },
    );
  }
}

/// The first two letters of the club's name ("Ikoyi…" → "IK"), as the
/// prototype's logo shows.
String? _logo(String name) {
  final first = name.trim().split(' ').first;
  return first.length < 2 ? null : first.substring(0, 2).toUpperCase();
}
