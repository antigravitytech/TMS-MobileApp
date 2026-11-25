import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../application/child_workspace_actions.dart';
import '../application/local_workspaces.dart';
import '../domain/workspace_kind.dart';
import 'workspace_ui.dart';

class KidHomeScreen extends ConsumerStatefulWidget {
  const KidHomeScreen({super.key});
  @override
  ConsumerState<KidHomeScreen> createState() => _KidHomeState();
}

class _KidHomeState extends ConsumerState<KidHomeScreen> {
  String? selected;
  final busy = <String>{};
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
              onPressed: () => WorkspaceSection.household.open(context),
            ),
          DesignButton(
            context.tr('family.parent'),
            onPressed: () => TmsRoute.home.reset(context),
          ),
        ],
      );
    }
    final points = space.availablePoints(kid.title);
    final chores = space
        .items(WorkspaceSection.chores)
        .where((r) => r.person == kid.title);
    final homework = space
        .items(WorkspaceSection.school)
        .where((r) => r.person == kid.title);
    final rewards = space.items(WorkspaceSection.rewards).toList()
      ..sort((a, b) => a.points.compareTo(b.points));
    final next = rewards.where((r) => r.points > points).firstOrNull;
    final arrived = DateUtils.isSameDay(
      DateTime.tryParse(kid.fields['schoolArrival'] ?? ''),
      DateTime.now(),
    );
    final actions = ref.read(childActionsProvider);
    return DesignPage(
      title: context.tr('family.hi', namedArgs: {'name': kid.title}),
      subtitle: DateFormat.MMMMEEEEd(
        context.locale.toString(),
      ).format(DateTime.now()),
      leading: DesignAvatar(
        kid.title.characters.first.toUpperCase(),
        color: DesignColor.amber,
        size: 44,
      ),
      actions: [
        TextButton(
          onPressed: () => TmsRoute.home.reset(context),
          child: Text(context.tr('family.parent')),
        ),
      ],
      navigation: const WorkspaceNavigation(
        kind: WorkspaceKind.family,
        active: TmsRoute.home,
      ),
      children: [
        if (kids.length > 1)
          DesignChoices(
            items: [for (final k in kids) k.title],
            selected: kids.indexOf(kid),
            onChanged: (i) => setState(() => selected = kids[i].id),
          ),
        DesignCard(
          color: const Color(0xff292746),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                context.tr('family.star').toUpperCase(),
                style: const TextStyle(
                  color: DesignColor.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AnimatedSwitcher(
                duration: DesignMotion.duration(context, DesignMotion.object),
                child: Text(
                  context.tr('family.pts', namedArgs: {'n': '$points'}),
                  key: ValueKey(points),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              if (next != null) ...[
                Text(
                  context.tr('family.next', namedArgs: {'name': next.title}),
                  style: const TextStyle(color: Colors.white),
                ),
                LinearProgressIndicator(
                  value: (points / next.points).clamp(0, 1),
                  color: DesignColor.amber,
                ),
              ],
            ],
          ),
        ),
        DesignCard(
          color: arrived ? context.panel : DesignColor.teal,
          onTap: arrived
              ? null
              : () => run(kid.id, () => actions.arrive(space.id, kid.id)),
          child: Row(
            spacing: 14,
            children: [
              Icon(
                TmsIcons.location,
                color: arrived ? context.foreground : DesignColor.ink,
              ),
              Expanded(
                child: Text(
                  context.tr(arrived ? 'family.arrived' : 'family.arrival'),
                  style: TextStyle(
                    color: arrived ? context.foreground : DesignColor.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        DesignTitle(context.tr('family.my_chores')),
        for (final chore in chores)
          DesignCard(
            onTap: () => run(chore.id, () => actions.chore(space.id, chore)),
            child: Row(
              spacing: 14,
              children: [
                AnimatedSwitcher(
                  duration: DesignMotion.duration(context, DesignMotion.page),
                  child: Icon(
                    chore.status == WorkspaceStatus.done
                        ? TmsIcons.checkCircleFilled
                        : TmsIcons.circle,
                    key: ValueKey(chore.status),
                    size: 36,
                    color: DesignColor.green,
                  ),
                ),
                Expanded(child: Text(chore.title)),
                DesignPill(
                  context.tr('family.pts', namedArgs: {'n': '${chore.points}'}),
                ),
              ],
            ),
          ),
        DesignTitle(
          context.tr('family.homework'),
          action: context.tr('family.all_school'),
          onTap: () => WorkspaceSection.school.open(context),
        ),
        for (final work in homework)
          DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Text(
                  work.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (work.status == WorkspaceStatus.submitted)
                  DesignLabel(context.tr('family.waiting'))
                else if (work.status == WorkspaceStatus.done)
                  DesignLabel(
                    WorkspaceSection.school.statusLabel(context, work.status),
                  )
                else
                  DesignButton(
                    context.tr(
                      work.fields['photo'] == 'false'
                          ? 'family.finish'
                          : 'family.photo',
                    ),
                    icon: TmsIcons.camera,
                    onPressed: busy.contains(work.id)
                        ? null
                        : () => run(
                            work.id,
                            () => actions.homework(space.id, work),
                          ),
                  ),
              ],
            ),
          ),
        DesignTitle(
          context.tr('workspaces.sections.rewards.title'),
          action: context.tr('family.see_all'),
          onTap: () => WorkspaceSection.rewards.open(context),
        ),
        for (final r in rewards)
          DesignTile(
            title: r.title,
            subtitle: context.tr(
              points >= r.points ? 'family.ask' : 'family.to_go',
              namedArgs: {'n': '${r.points - points}'},
            ),
            icon: TmsIcons.trophy,
            onTap: () => WorkspaceSection.rewards.open(context, recordId: r.id),
          ),
      ],
    );
  }
}
