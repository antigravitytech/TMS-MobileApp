import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});
  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  static const people = [
    'approvals.everyone',
    'Sarah Johnson',
    'Amaka Eze',
    'Tunde Bakare',
  ];
  static const projects = [
    'common.all_projects',
    'Customer Portal Revamp',
    'Mobile App Launch',
  ];
  bool newest = false, dragging = false, outgoing = false;
  int person = 0, project = 0;
  double dx = 0;

  Future<void> _decide(PreviewTask task, bool approve) async {
    if (outgoing) return;
    if (!approve) {
      setState(() {
        dx = 0;
        dragging = false;
      });
      var reason = -1;
      const reasons = [
        'approvals.missing_files',
        'approvals.doesnt_match_the_brief',
        'approvals.needs_tests',
        'approvals.fix_formatting',
      ];
      final confirm = await designSheet<bool>(
        context,
        title: context.tr(
          'approvals.return_to',
          namedArgs: {'name': task.person.split(' ').first},
        ),
        builder: (sheet) => StatefulBuilder(
          builder: (context, update) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              DesignLabel(
                context.tr('approvals.say_what_needs_to_change_it_starts'),
              ),
              DesignChoices(
                items: reasons.map(context.tr).toList(),
                selected: reason,
                onChanged: (i) => update(() => reason = i),
                scroll: false,
              ),
              DesignField(label: context.tr('common.notes'), lines: 3),
              DesignButton(
                context.tr('approvals.return_with_notes'),
                color: DesignColor.rose,
                onPressed: () => Navigator.pop(sheet, true),
              ),
            ],
          ),
        ),
      );
      if (!mounted || confirm != true) return;
    }
    setState(() {
      outgoing = true;
      dragging = false;
      dx = approve ? 465 : -465;
    });
    await Future<void>.delayed(
      DesignMotion.duration(context, DesignMotion.object),
    );
    if (!mounted) return;
    ref.read(workspacePreviewProvider).review(task, approve: approve);
    setState(() {
      outgoing = false;
      dx = 0;
    });
    designToast(
      context,
      context.tr(
        approve ? 'approvals.approved_notice' : 'approvals.returned_notice',
        namedArgs: {'task': task.title},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspacePreviewProvider);
    var queue = state.reviewQueue
        .where(
          (t) =>
              (person == 0 || t.person == people[person]) &&
              (project == 0 || t.project == projects[project]),
        )
        .toList();
    if (newest) queue = queue.reversed.toList();
    final task = queue.firstOrNull;
    return DesignPage(
      title: context.tr('approvals.review'),
      tab: TmsRoute.approvals,
      actions: [
        DesignIcon(
          icon: TmsIcons.filter,
          label: context.tr('common.sort_and_filter'),
          onPressed: () {
            designSheet<void>(
              context,
              title: context.tr('common.sort_and_filter'),
              builder: (_) => StatefulBuilder(
                builder: (context, update) => Column(
                  spacing: 9,
                  children: [
                    DesignChoices(
                      items: [context.tr(people.first), ...people.skip(1)],
                      selected: person,
                      onChanged: (i) {
                        setState(() => person = i);
                        update(() {});
                      },
                      scroll: false,
                    ),
                    DesignChoices(
                      items: [context.tr(projects.first), ...projects.skip(1)],
                      selected: project,
                      onChanged: (i) {
                        setState(() => project = i);
                        update(() {});
                      },
                      scroll: false,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
      children: [
        DesignCard(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              for (final (label, value, color) in [
                (
                  context.tr('approvals.waiting'),
                  '${state.reviewQueue.length}',
                  context.foreground,
                ),
                (
                  context.tr('approvals.avg_review'),
                  context.tr('approvals.5_3h'),
                  context.foreground,
                ),
                (
                  context.tr('approvals.approved'),
                  '${2 + state.approved.length}',
                  DesignColor.green,
                ),
                (
                  context.tr('common.returned'),
                  '${5 + state.returned.length}',
                  DesignColor.rose,
                ),
              ])
                Expanded(
                  child: Column(
                    spacing: 5,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 22,
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: context.muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              DesignPill(
                newest
                    ? context.tr('approvals.newest_first')
                    : context.tr('approvals.oldest_first'),
                selected: true,
                onTap: () => setState(() => newest = !newest),
              ),
              DesignPill(
                person == 0 ? context.tr(people.first) : people[person],
                selected: person > 0,
                onTap: () =>
                    setState(() => person = (person + 1) % people.length),
              ),
              DesignPill(
                project == 0 ? context.tr(projects.first) : projects[project],
                selected: project > 0,
                onTap: () =>
                    setState(() => project = (project + 1) % projects.length),
              ),
            ],
          ),
        ),
        if (task == null) ...[
          DesignEmpty(
            state.reviewQueue.isEmpty
                ? context.tr('approvals.all_caught_up')
                : context.tr('common.nothing_here'),
            state.reviewQueue.isEmpty
                ? context.tr(
                    'approvals.queue_empty_summary',
                    namedArgs: {
                      'approved': state.approved.length.toString(),
                      'returned': state.returned.length.toString(),
                    },
                  )
                : context.tr('approvals.no_reviews_match_this_filter'),
          ),
          DesignButton(
            context.tr('approvals.back_to_home'),
            onPressed: () => TmsRoute.home.open(context),
          ),
        ] else ...[
          Center(
            child: DesignLabel(
              context.tr('approvals.swipe_right_to_approve_left_to_return'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LayoutBuilder(
              builder: (context, bounds) => Stack(
                clipBehavior: Clip.none,
                children: [
                  if (queue.length > 1)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: -8,
                      height: 60,
                      child: DesignCard(
                        color: context.raised,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: outgoing
                        ? null
                        : (_) => setState(() => dragging = true),
                    onHorizontalDragUpdate: outgoing
                        ? null
                        : (d) => setState(() => dx += d.delta.dx),
                    onHorizontalDragCancel: () {
                      if (!outgoing) {
                        setState(() {
                          dragging = false;
                          dx = 0;
                        });
                      }
                    },
                    onHorizontalDragEnd: outgoing
                        ? null
                        : (_) {
                            if (dx > 102) {
                              _decide(task, true);
                            } else if (dx < -102) {
                              _decide(task, false);
                            } else {
                              setState(() {
                                dragging = false;
                                dx = 0;
                              });
                            }
                          },
                    child: AnimatedSlide(
                      offset: Offset(dx / math.max(bounds.maxWidth, 1), 0),
                      duration: dragging
                          ? Duration.zero
                          : DesignMotion.duration(context, DesignMotion.object),
                      curve: DesignMotion.curve,
                      child: AnimatedRotation(
                        turns: (dx / 2700).clamp(-.095, .095),
                        duration: dragging
                            ? Duration.zero
                            : DesignMotion.duration(
                                context,
                                DesignMotion.object,
                              ),
                        curve: DesignMotion.curve,
                        child: DesignEntrance(
                          key: ValueKey(task.id),
                          child: _ReviewCard(
                            task: task,
                            dx: dx,
                            onOpen: () {
                              state.selectTask(task);
                              TmsRoute.task.open(context);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: DesignButton(
                  context.tr('common.return'),
                  icon: TmsIcons.undo,
                  color: DesignColor.rose,
                  onPressed: outgoing ? null : () => _decide(task, false),
                ),
              ),
              Expanded(
                child: DesignButton(
                  context.tr('common.approve'),
                  icon: TmsIcons.check,
                  color: DesignColor.green,
                  onPressed: outgoing ? null : () => _decide(task, true),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.task,
    required this.dx,
    required this.onOpen,
  });
  final PreviewTask task;
  final double dx;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      DesignCard(
        padding: const EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              spacing: 10,
              children: [
                DesignAvatar(
                  task.person.split(' ').map((name) => name[0]).take(2).join(),
                  color: DesignColor.teal,
                  size: 46,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DesignTitle(task.person),
                      DesignLabel('${task.project} · ${task.id}'),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.18,
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                DesignPill(
                  context.tr('common.submitted'),
                  color: DesignColor.amber,
                ),
                DesignPill(context.tr('approvals.round_1')),
                DesignPill(
                  context.tr('approvals.just_now'),
                  icon: TmsIcons.clock,
                ),
              ],
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.raised,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('“${task.note}”'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  DesignPill(
                    context.tr('approvals.2_files'),
                    icon: TmsIcons.attachment,
                  ),
                  TextButton(
                    onPressed: onOpen,
                    child: Text(context.tr('approvals.open_task_link')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (dx.abs() > 10)
        Positioned(
          top: 20,
          left: dx > 0 ? 18 : null,
          right: dx < 0 ? 18 : null,
          child: IgnorePointer(
            child: Opacity(
              opacity: (dx.abs() / 95).clamp(0, 1),
              child: Transform.rotate(
                angle: dx > 0 ? -.18 : .18,
                child: DesignPill(
                  dx > 0
                      ? context.tr('approvals.approve_swipe')
                      : context.tr('approvals.return_swipe'),
                  color: dx > 0 ? DesignColor.green : DesignColor.rose,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
