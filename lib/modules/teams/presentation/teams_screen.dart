import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../../shared/kit/kit.dart';
import '../../chat/application/chat_session.dart';
import '../../chat/data/chat_directory.dart';
import '../../chat/data/chat_repository.dart';
import '../../tasks/presentation/tasks_screen.dart' show taskErrorMessage;
import '../application/teams_controller.dart';
import '../domain/team.dart';

part 'widgets/team_card.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});
  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  /// The open card; the first one starts open, as in the design.
  String? expanded;

  /// Teams whose members were loaded, kept while the screen is open.
  final opened = <TeamItem>{};

  /// Opens a direct message with [member].
  Future<void> openMember(TeamMember member) async {
    try {
      final inbox = await ref.read(chatDirectoryProvider.future);
      final contact = ChatContact(
        kitPerson(member.name).$1,
        'a1',
        member.name,
        '',
        false,
        id: member.userId,
      );
      var row = await ref.read(chatRepositoryProvider).start(inbox, [
        contact,
      ], group: false);
      // Prototype people reopen their sample thread.
      if (row.id.isEmpty) {
        row =
            inbox.recent.where((r) => r.name == member.name).firstOrNull ?? row;
      }
      if (!mounted) return;
      ref.read(chatSessionProvider(inbox.workspace).notifier).open(row);
      TmsRoute.conversation.open(context);
    } catch (error) {
      if (mounted) designToast(context, taskErrorMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teamsProvider);
    final directory = async.value;
    for (final team in opened) {
      ref.watch(teamMembersProvider(team));
    }
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: Row(
                    spacing: 10,
                    children: [
                      DesignIcon(
                        icon: TmsIcons.chevronBack,
                        label: context.tr('common.back'),
                        onPressed: () async {
                          if (!await context.router.maybePop() &&
                              context.mounted) {
                            TmsRoute.more.reset(context);
                          }
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('teams.teams'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -.4,
                              ),
                            ),
                            if (directory != null)
                              _TeamCaption(
                                context.tr(
                                  'teams.workspace_count',
                                  namedArgs: {
                                    'count': NumberFormat.decimalPattern(
                                      context.locale.toString(),
                                    ).format(directory.teams.length),
                                    'workspace': directory.workspace,
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (async) {
                    AsyncValue(value: final d?) => ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      children: [
                        if (d.teams.isEmpty)
                          DesignEmpty(
                            context.tr('common.nothing_here'),
                            context.tr('teams.empty'),
                          ),
                        for (final (i, team) in d.teams.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TeamCard(
                              team: team,
                              expanded: expanded == null
                                  ? i == 0
                                  : expanded == team.id,
                              onOpen: () => opened.add(team),
                              toggle: () => setState(() {
                                final open = expanded == null
                                    ? i == 0
                                    : expanded == team.id;
                                expanded = open ? '' : team.id;
                              }),
                              open: openMember,
                            ),
                          ),
                      ],
                    ),
                    AsyncValue(:final error?) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 12,
                        children: [
                          DesignLabel(taskErrorMessage(context, error)),
                          DesignButton(
                            context.tr('workspaces.try_again'),
                            secondary: true,
                            onPressed: () => ref.invalidate(teamsProvider),
                          ),
                        ],
                      ),
                    ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
