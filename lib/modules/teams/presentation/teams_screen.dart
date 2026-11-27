import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../chat/application/chat_session.dart';
import '../../chat/data/chat_directory.dart';
import '../../workspace/application/workspace_preview.dart';

part 'widgets/team_card.dart';

typedef _Member = (String, String, String, Color, int, bool);

const _tunde = ('TB', 'Tunde Bakare', 'a2', Color(0xff86d6cb), 4, false);
const _amaka = ('AE', 'Amaka Eze', 'a4', Color(0xffeeabb0), 3, false);
const _david = ('DM', 'David Mensah', 'a6', Color(0xffbcd995), 2, false);
const _sarah = ('SJ', 'Sarah Johnson', 'a3', DesignColor.amber, 2, false);

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});
  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  int? expanded = 0;

  Future<void> openMember(_Member member) async {
    final directory = await ref
        .read(chatDirectoryProvider.future)
        .then<ChatDirectory?>((value) => value, onError: (Object _) => null);
    if (!mounted) return;
    if (directory == null) {
      TmsRoute.chat.open(context);
      return;
    }
    final peer =
        directory.recent.where((item) => item.name == member.$2).firstOrNull ??
        ChatRow(initials: member.$1, name: member.$2, color: member.$3);
    ref.read(chatSessionProvider(directory.workspace).notifier).open(peer);
    TmsRoute.conversation.open(context);
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspacePreviewProvider);
    final lead = '${workspace.firstName} ${workspace.lastName}';
    final teams = [
      (
        'Tech Team',
        lead,
        8,
        context.lavender,
        <_Member>[
          (
            '${workspace.firstName.characters.firstOrNull ?? ''}${workspace.lastName.characters.firstOrNull ?? ''}'
                .toUpperCase(),
            lead,
            'a1',
            const Color(0xffc4bdf6),
            2,
            true,
          ),
          _tunde,
          _amaka,
          _sarah,
          _david,
        ],
      ),
      (
        context.tr('teams.compliance'),
        'Ngozi Adeyemi',
        0,
        DesignColor.teal,
        <_Member>[
          ('NA', 'Ngozi Adeyemi', 'a7', const Color(0xffd8b4ec), 1, true),
          ('DM', 'David Mensah', 'a6', const Color(0xffbcd995), 0, false),
          ('SJ', 'Sarah Johnson', 'a3', DesignColor.amber, 1, false),
        ],
      ),
    ];
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
                            _TeamCaption(
                              context.tr(
                                'teams.workspace_count',
                                namedArgs: {
                                  'count': NumberFormat.decimalPattern(
                                    context.locale.toString(),
                                  ).format(teams.length),
                                  'workspace': workspace.workspace,
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    children: [
                      for (final (
                            index,
                            (name, manager, progress, color, members),
                          )
                          in teams.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TeamCard(
                            name: name,
                            manager: manager,
                            progress: progress,
                            color: color,
                            members: members,
                            expanded: expanded == index,
                            job: index == 0 ? workspace.jobTitle : null,
                            toggle: () => setState(
                              () => expanded = expanded == index ? null : index,
                            ),
                            open: openMember,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
