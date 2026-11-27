import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

part 'widgets/review_card.dart';
part 'widgets/review_actions.dart';

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
  void _update(VoidCallback action) => setState(action);

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
                  const Color(0xfff59562),
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
              _ReviewChip(
                newest
                    ? context.tr('approvals.newest_first')
                    : context.tr('approvals.oldest_first'),
                selected: true,
                onTap: () => setState(() => newest = !newest),
              ),
              _ReviewChip(
                person == 0 ? context.tr(people.first) : people[person],
                selected: person > 0,
                onTap: () =>
                    setState(() => person = (person + 1) % people.length),
              ),
              _ReviewChip(
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
                  color: const Color(0xfff59562),
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
