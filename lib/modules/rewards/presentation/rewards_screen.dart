import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit_controls.dart';
import '../../../shared/kit/kit.dart';
import '../../../shared/kit/kit_visuals.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../application/rewards_controller.dart';
import 'widgets/rewards_widgets.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key, required this.workspace});
  final LocalWorkspace workspace;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final id = workspace.id;
    final state = ref.watch(rewardsControllerProvider(id));
    final actions = ref.read(rewardsControllerProvider(id).notifier);
    final view = ref.watch(rewardsViewProvider(id));
    Future<void> give(WorkspaceRecord reward) async {
      final ok = await actions.give(reward);
      if (!c.mounted) return;
      designToast(
        c,
        ok
            ? c.tr(
                'rewards.given',
                namedArgs: {
                  'reward': reward.title,
                  'name': rewardsChild,
                  'cost': '${reward.points}',
                },
              )
            : c.tr('workspaces.try_again'),
      );
    }

    final board = state.tab == RewardsTab.board;
    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: const WorkspaceNavigation(
        kind: WorkspaceKind.family,
        active: TmsRoute.more,
        badges: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitHeader(
              title: c.tr('rewards.title'),
              subtitle: c.tr('rewards.subtitle'),
              back: c.tr('common.back'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: KitSegment<RewardsTab>(
                values: RewardsTab.values,
                selected: state.tab,
                label: (t) => c.tr('rewards.tabs.${t.name}'),
                onChanged: actions.tab,
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: DesignMotion.fast,
                child: ListView(
                  key: ValueKey(state.tab),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  children: board
                      ? _board(c, view, state, actions)
                      : _shop(c, view, give),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _board(
    BuildContext c,
    RewardsView view,
    RewardsState state,
    RewardsController actions,
  ) => [
    DesignEntrance(child: RewardsPodium(people: view.people)),
    const SizedBox(height: 12),
    Row(
      spacing: 8,
      children: [
        for (final (i, (value, key, color)) in [
          (view.stats.chores, 'chores_done', null),
          (view.stats.school, 'school_checked', null),
          (view.stats.overdue, 'overdue', KitColor.overdue),
          (view.stats.streak, 'streak', KitColor.submitted),
        ].indexed)
          Expanded(
            child: DesignEntrance(
              order: i + 1,
              child: KitCard(
                radius: 20,
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  height: 56,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$value',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      Text(
                        c.tr('rewards.kpi.$key'),
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 10),
      child: Text(
        c.tr('rewards.everyone').toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: c.muted,
        ),
      ),
    ),
    KitList(
      children: [
        for (final (i, p) in view.people.indexed)
          RewardsPersonRow(
            rank: i + 1,
            person: p,
            cheered: state.cheered.contains(p.name),
            onCheer: () {
              if (actions.cheer(p.name)) {
                designToast(
                  c,
                  c.tr('rewards.cheer_toast', namedArgs: {'name': p.name}),
                );
              }
            },
          ),
      ],
    ),
  ];

  List<Widget> _shop(
    BuildContext c,
    RewardsView view,
    Future<void> Function(WorkspaceRecord) give,
  ) {
    final (initials, color) = kitPerson(rewardsChild);
    return [
      DesignEntrance(
        child: KitCard(
          child: Row(
            spacing: 14,
            children: [
              DesignAvatar(initials, size: 52, color: color),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.tr(
                        'rewards.has_points',
                        namedArgs: {
                          'name': rewardsChild,
                          'points': '${view.childPoints}',
                        },
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      c.tr('rewards.trade'),
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      for (final (i, r) in view.rewards.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DesignEntrance(
            order: i + 1,
            child: RewardCard(
              reward: r,
              points: view.childPoints,
              onGive: () => give(r),
            ),
          ),
        ),
      const SizedBox(height: 4),
      DesignButton(
        c.tr('rewards.add'),
        secondary: true,
        onPressed: () => designToast(c, c.tr('rewards.add_hint')),
      ),
    ];
  }
}
