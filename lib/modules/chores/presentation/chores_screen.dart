import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit.dart';
import '../../../shared/kit/kit_visuals.dart';
import '../../../shared/kit/kit_burst.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../application/chores_controller.dart';
import 'widgets/chore_add_sheet.dart';

class ChoresScreen extends ConsumerStatefulWidget {
  const ChoresScreen({super.key, required this.workspace});
  final LocalWorkspace workspace;
  @override
  ConsumerState<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends ConsumerState<ChoresScreen> {
  Timer? _burstTimer;
  int _burstKey = 0;
  int? _gained;

  String get _id => widget.workspace.id;

  @override
  void dispose() {
    _burstTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggle(WorkspaceRecord chore) async {
    final done = await ref
        .read(choresControllerProvider(_id).notifier)
        .toggle(chore);
    if (!mounted) return;
    if (done == null) {
      return designToast(context, context.tr('workspaces.try_again'));
    }
    if (done && chore.points > 0) {
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
    if (!done) return;
    designToast(
      context,
      chore.points > 0
          ? context.tr(
              'chores.earned',
              namedArgs: {'name': chore.person, 'points': '${chore.points}'},
            )
          : context.tr('chores.done_toast', namedArgs: {'name': chore.title}),
    );
  }

  @override
  Widget build(BuildContext c) {
    final state = ref.watch(choresControllerProvider(_id));
    final chores = ref.watch(choreItemsProvider(_id));
    final tobi = ref.watch(familyPointsProvider((_id, 'Tobi')));
    final visible = chores.where(state.filter.matches).toList();
    final done = chores.where(ChoreFilter.done.matches).length;
    final total = chores.length;
    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: const WorkspaceNavigation(
        kind: WorkspaceKind.family,
        active: TmsRoute.workspacePlan,
        section: WorkspaceSection.chores,
        badges: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitHeader(
                  large: true,
                  title: c.tr('chores.title'),
                  subtitle: widget.workspace.name,
                  action: KitIconButton(
                    primary: true,
                    icon: TmsIcons.add,
                    tooltip: c.tr('chores.add'),
                    onPressed: () => showChoreAdd(c, _id),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    c.tr('chores.intro'),
                    style: TextStyle(fontSize: 13.5, color: c.muted),
                  ),
                ),
                const SizedBox(height: 14),
                KitTabs(
                  children: [
                    for (final f in ChoreFilter.values)
                      KitChip(
                        label: c.tr('chores.filters.${f.name}'),
                        count: chores.where(f.matches).length,
                        selected: state.filter == f,
                        onTap: () => ref
                            .read(choresControllerProvider(_id).notifier)
                            .filter(f),
                      ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                    children: [
                      DesignEntrance(
                        child: KitCard(
                          child: Row(
                            spacing: 14,
                            children: [
                              KitRing(
                                size: 64,
                                value: total == 0 ? 0 : done / total,
                                label: '$done/$total',
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      total > 0 && done == total
                                          ? c.tr('chores.all_done')
                                          : c.plural(
                                              'chores.left',
                                              total - done,
                                            ),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text.rich(
                                      TextSpan(
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.muted,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: c.tr(
                                              'chores.points_line',
                                              namedArgs: {'name': 'Tobi'},
                                            ),
                                          ),
                                          TextSpan(
                                            text: c.tr(
                                              'chores.points_value',
                                              namedArgs: {'points': '$tobi'},
                                            ),
                                            style: TextStyle(
                                              color: c.lavender,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          TextSpan(
                                            text: c.tr('chores.points_tail'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              KitMiniButton(
                                c.tr('chores.rewards'),
                                onPressed: () =>
                                    WorkspaceSection.rewards.open(c),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (visible.isEmpty)
                        KitPop(
                          child: KitCard(
                            padding: const EdgeInsets.all(26),
                            child: Column(
                              children: [
                                Text(
                                  c.tr('chores.empty_title'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  c.tr('chores.empty_body'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      for (final (i, chore) in visible.indexed)
                        Padding(
                          key: ValueKey(chore.id),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DesignEntrance(
                            order: i,
                            child: _ChoreRow(
                              chore: chore,
                              onToggle: () => _toggle(chore),
                            ),
                          ),
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
                label: c.tr('chores.gained', namedArgs: {'points': '$_gained'}),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoreRow extends StatelessWidget {
  const _ChoreRow({required this.chore, required this.onToggle});
  final WorkspaceRecord chore;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext c) {
    final done = chore.status == WorkspaceStatus.done;
    final (initials, color) = kitPerson(chore.person);
    final dueKey = chore.fields['dueKey'];
    final due = dueKey != null
        ? c.tr('chores.dues.$dueKey')
        : chore.fields['due'] ?? '';
    return KitCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      color: done
          ? Color.alphaBlend(KitColor.done.withValues(alpha: .08), c.panel)
          : null,
      border: done ? KitColor.done.withValues(alpha: .3) : null,
      child: Row(
        spacing: 12,
        children: [
          KitTick(
            on: done,
            label: c.tr(done ? 'chores.mark_not_done' : 'chores.mark_done'),
            onTap: onToggle,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: done ? .55 : 1,
                  child: Text(
                    chore.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: KitColor.tick,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  spacing: 6,
                  children: [
                    DesignAvatar(initials, size: 28, color: color),
                    Flexible(
                      child: Text(
                        [
                          chore.person,
                          due,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 6,
            children: [
              if (chore.points > 0) KitPoints(chore.points),
              if (chore.status == WorkspaceStatus.inProgress)
                KitStatus(c.tr('chores.in_progress'), KitColor.progress),
            ],
          ),
        ],
      ),
    );
  }
}
