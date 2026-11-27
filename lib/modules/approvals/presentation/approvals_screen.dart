import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../../shared/kit/kit.dart';
import '../../tasks/application/tasks_controller.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/tasks_screen.dart' show taskErrorMessage;
import '../../tasks/presentation/widgets/task_labels.dart';
import '../application/approvals_controller.dart';

part 'widgets/review_card.dart';
part 'widgets/review_actions.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});
  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  bool newest = false, dragging = false, outgoing = false;
  int person = 0, project = 0;
  double dx = 0;
  void _update(VoidCallback action) => setState(action);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(approvalsProvider);
    final review = async.value;
    if (review == null) {
      return DesignPage(
        title: context.tr('approvals.review'),
        tab: TmsRoute.approvals,
        children: [
          if (async.hasError) ...[
            DesignEmpty(
              context.tr('approvals.load_failed'),
              taskErrorMessage(context, async.error),
            ),
            DesignButton(
              context.tr('workspaces.try_again'),
              secondary: true,
              onPressed: () => ref.invalidate(approvalsProvider),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    }
    // Filter choices come from who and what is waiting.
    final people = [
      context.tr('approvals.everyone'),
      ...{for (final t in review.tasks) t.assignee?.name ?? ''},
    ];
    final projects = [
      context.tr('common.all_projects'),
      ...{for (final t in review.tasks) taskPlaceText(context, t)},
    ];
    person = person.clamp(0, people.length - 1);
    project = project.clamp(0, projects.length - 1);
    var queue = review.tasks
        .where(
          (t) =>
              (person == 0 || t.assignee?.name == people[person]) &&
              (project == 0 || taskPlaceText(context, t) == projects[project]),
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
                      items: people,
                      selected: person,
                      onChanged: (i) {
                        setState(() => person = i);
                        update(() {});
                      },
                      scroll: false,
                    ),
                    DesignChoices(
                      items: projects,
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
                  '${review.tasks.length}',
                  context.foreground,
                ),
                (
                  context.tr('approvals.avg_review'),
                  context.tr(
                    'approvals.hours',
                    namedArgs: {
                      'n':
                          NumberFormat.decimalPattern(
                            context.locale.toString(),
                          ).format(
                            double.parse(review.avgHours.toStringAsFixed(1)),
                          ),
                    },
                  ),
                  context.foreground,
                ),
                (
                  context.tr('approvals.approved'),
                  '${review.approved}',
                  DesignColor.green,
                ),
                (
                  context.tr('common.returned'),
                  '${review.returned}',
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
                people[person],
                selected: person > 0,
                onTap: () =>
                    setState(() => person = (person + 1) % people.length),
              ),
              _ReviewChip(
                projects[project],
                selected: project > 0,
                onTap: () =>
                    setState(() => project = (project + 1) % projects.length),
              ),
            ],
          ),
        ),
        if (task == null) ...[
          DesignEmpty(
            review.tasks.isEmpty
                ? context.tr('approvals.all_caught_up')
                : context.tr('common.nothing_here'),
            review.tasks.isEmpty
                ? context.tr(
                    'approvals.queue_empty_summary',
                    namedArgs: {
                      'approved': '${review.approved}',
                      'returned': '${review.returned}',
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
                              ref.read(openedTaskProvider.notifier).open(task);
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
