import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../application/child_workspace_actions.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit_burst.dart';
import '../../../shared/kit/kit.dart';
import 'widgets/kid_home_cards.dart';
import 'widgets/kid_home_widgets.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';

class KidHomeScreen extends ConsumerStatefulWidget {
  const KidHomeScreen({super.key});
  @override
  ConsumerState<KidHomeScreen> createState() => _KidHomeState();
}

class _KidHomeState extends ConsumerState<KidHomeScreen> {
  String? selected;
  final busy = <String>{};
  Timer? _burstTimer;
  int _burstKey = 0;
  int? _gained;

  @override
  void dispose() {
    _burstTimer?.cancel();
    super.dispose();
  }

  Future<void> run(String id, Future<void> Function() action) async {
    if (!busy.add(id)) return;
    setState(() {});
    try {
      await saveWorkspaceChange(context, action);
    } finally {
      if (mounted) setState(() => busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final space = ref.watch(localWorkspacesProvider).asData?.value.active;
    final kids =
        space
            ?.items(WorkspaceSection.household)
            .where((r) => r.fields['householdRole'] == 'child')
            .toList() ??
        [];
    final kid =
        kids.where((p) => p.id == selected).firstOrNull ?? kids.firstOrNull;
    if (space == null || kid == null) {
      return DesignPage(
        title: context.tr('more.tools.kid_view'),
        children: [
          DesignLabel(context.tr('family.need_child')),
          if (space?.kind == WorkspaceKind.family)
            DesignButton(
              context.tr('more.tools.household'),
              onPressed: () => TmsRoute.household.open(context),
            ),
          DesignButton(
            context.tr('family.parent'),
            onPressed: () => TmsRoute.home.reset(context),
          ),
        ],
      );
    }
    final name = kid.title.split(' ').first;
    final points = space.availablePoints(name);
    final chores = space
        .items(WorkspaceSection.chores)
        .where((r) => r.person == name && r.fields['ledger'] != 'true')
        .toList();
    final homework = space
        .items(WorkspaceSection.school)
        .where((r) => r.person == name)
        .toList();
    final rewards = space.items(WorkspaceSection.rewards).toList()
      ..sort((a, b) => a.points.compareTo(b.points));
    final next = rewards.where((r) => r.points > points).firstOrNull;
    final arrival = DateTime.tryParse(kid.fields['schoolArrival'] ?? '');
    final sentAt =
        arrival != null && DateUtils.isSameDay(arrival, DateTime.now())
        ? arrival
        : null;
    final actions = ref.read(childActionsProvider);
    final (initials, color) = kitPerson(kid.title);
    final left = chores.where((r) => r.status != WorkspaceStatus.done).length;
    Widget heading(
      String title, {
      String? trailing,
      VoidCallback? onTap,
    }) => Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          if (trailing != null)
            onTap == null
                ? Text(
                    trailing,
                    style: TextStyle(fontSize: 12, color: context.muted),
                  )
                : TextButton(
                    onPressed: onTap,
                    child: Text(
                      trailing,
                      style: TextStyle(fontSize: 13.5, color: context.lavender),
                    ),
                  ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: context.background,
      bottomNavigationBar: const WorkspaceNavigation(
        kind: WorkspaceKind.family,
        active: TmsRoute.home,
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    spacing: 10,
                    children: [
                      Tooltip(
                        message: kids.length > 1
                            ? context.tr('family.switch_child')
                            : name,
                        child: GestureDetector(
                          onTap: kids.length < 2
                              ? null
                              : () => setState(
                                  () => selected =
                                      kids[(kids.indexOf(kid) + 1) %
                                              kids.length]
                                          .id,
                                ),
                          child: AnimatedSwitcher(
                            duration: DesignMotion.fast,
                            child: DesignAvatar(
                              initials,
                              key: ValueKey(initials),
                              size: 44,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat.MMMMEEEEd(
                                context.locale.toString(),
                              ).format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 12,
                                color: context.muted,
                              ),
                            ),
                            Text(
                              context.tr(
                                'family.hi',
                                namedArgs: {'name': name},
                              ),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      KitMiniButton(
                        context.tr('family.parent'),
                        onPressed: () => TmsRoute.home.reset(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    children: [
                      DesignEntrance(
                        child: KidHero(points: points, next: next),
                      ),
                      const SizedBox(height: 14),
                      DesignEntrance(
                        order: 1,
                        child: KidArriveButton(
                          sentAt: sentAt,
                          onTap: () => run(
                            kid.id,
                            () => actions.arrive(space.id, kid.id),
                          ),
                        ),
                      ),
                      heading(
                        context.tr('family.my_chores'),
                        trailing: context.tr(
                          'family.left',
                          namedArgs: {'n': '$left'},
                        ),
                      ),
                      for (final (i, chore) in chores.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DesignEntrance(
                            order: i + 2,
                            child: KidChoreCard(
                              chore: chore,
                              onTap: () => _chore(space.id, chore),
                            ),
                          ),
                        ),
                      heading(
                        context.tr('family.homework'),
                        trailing: context.tr('family.all_school'),
                        onTap: () => WorkspaceSection.school.open(context),
                      ),
                      for (final work in homework)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: KidHomeworkCard(
                            work: work,
                            busy: busy.contains(work.id),
                            onDone: () => run(
                              work.id,
                              () => actions.homework(space.id, work),
                            ),
                          ),
                        ),
                      heading(
                        context.tr('workspaces.sections.rewards.title'),
                        trailing: context.tr('family.see_all'),
                        onTap: () => WorkspaceSection.rewards.open(context),
                      ),
                      for (final r in rewards)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: KidRewardRow(reward: r, points: points),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_gained != null)
            Positioned.fill(
              child: KitBurst(
                key: ValueKey(_burstKey),
                label: context.tr(
                  'chores.gained',
                  namedArgs: {'points': '$_gained'},
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _chore(String spaceId, WorkspaceRecord chore) async {
    final earning = chore.status != WorkspaceStatus.done && chore.points > 0;
    await run(
      chore.id,
      () => ref.read(childActionsProvider).chore(spaceId, chore),
    );
    if (!mounted || !earning) return;
    setState(() {
      _gained = chore.points;
      _burstKey++;
    });
    _burstTimer?.cancel();
    _burstTimer = Timer(
      const Duration(milliseconds: 1600),
      () => mounted ? setState(() => _gained = null) : null,
    );
  }
}
