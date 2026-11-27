import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/quick_create.dart';
import '../../../shared/design/tms_icons.dart';
import '../../tasks/presentation/widgets/task_card.dart';
import '../../tasks/presentation/widgets/task_labels.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../workspace/presentation/workspace_home.dart';

part 'widgets/home_overview.dart';
part 'widgets/home_cards.dart';
part 'widgets/home_report.dart';
part 'widgets/home_team.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspacePreviewProvider);
    final workspace = ref.watch(localWorkspacesProvider).asData?.value.active;
    if (workspace != null) {
      return WorkspaceHome(
        key: ValueKey(workspace.id),
        workspace: workspace,
        companyName: state.workspace,
      );
    }
    final due = state.tasks
        .where(
          (task) =>
              task.group == 'Mine' &&
              task.due == 'Today' &&
              task.status != 'Completed',
        )
        .toList();
    final reviews = state.reviewQueue.toList();
    final upcoming = state.tasks
        .where((task) => task.id == 'TK-192' && task.status != 'Completed')
        .firstOrNull;
    return Scaffold(
      backgroundColor: context.background,
      bottomNavigationBar: DesignTabs(
        active: TmsRoute.home,
        items: [
          for (final (route, label, icon, badge) in DesignTabs.companyTabs)
            (
              route,
              label,
              icon,
              route == TmsRoute.approvals ? reviews.length : badge,
            ),
        ],
      ),
      floatingActionButton: const QuickCreate(),
      floatingActionButtonLocation: const _HomeFabLocation(),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeHeader(state: state),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    children: [
                      DesignEntrance(
                        child: _HomeOverview(
                          state: state,
                          due: due.length,
                          reviews: reviews.length,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _Heading(
                        context.tr('home.daily_report'),
                        trailing: _StatusBadge(
                          context.tr(
                            state.reportSent
                                ? 'home.sent_today'
                                : 'home.due_by_5_00_pm',
                          ),
                          state.reportSent
                              ? DesignColor.green
                              : DesignColor.amber,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DailyReport(sent: state.reportSent),
                      const SizedBox(height: 26),
                      _Heading(
                        context.tr('home.due_heading'),
                        count: due.length,
                        trailing: _HomeLink(
                          context.tr('home.view_all'),
                          TmsRoute.tasks,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final (i, task) in due.indexed) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _DueTask(
                          task: task,
                          open: () => _openTask(context, state, task),
                        ),
                      ],
                      const SizedBox(height: 26),
                      _Heading(
                        context.tr('home.awaiting_heading'),
                        count: reviews.length,
                        trailing: _HomeLink(
                          context.tr('home.open_queue'),
                          TmsRoute.approvals,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSize(
                        duration: DesignMotion.duration(
                          context,
                          const Duration(milliseconds: 400),
                        ),
                        curve: DesignMotion.curve,
                        alignment: Alignment.topCenter,
                        child: Column(
                          spacing: 10,
                          children: [
                            if (reviews.isEmpty)
                              DesignCard(
                                child: Column(
                                  children: [
                                    Text(
                                      context.tr('home.review_clear'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    _HomeCaption(
                                      context.tr(
                                        'home.review_clear_description',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            for (final task in reviews)
                              _ReviewCard(
                                key: ValueKey(task.id),
                                task: task,
                                onApprove: () {
                                  state.review(task, approve: true);
                                  designToast(
                                    context,
                                    context.tr(
                                      'approvals.approved_notice',
                                      namedArgs: {'task': task.title},
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      _Heading(
                        context.tr('home.team_today'),
                        trailing: _HomeLink(
                          context.tr('home.summaries'),
                          TmsRoute.reports,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _TeamSummary(),
                      if (upcoming != null) ...[
                        const SizedBox(height: 26),
                        _Heading(
                          context.tr('home.coming_up'),
                          trailing: _HomeCaption(context.tr('home.next_week')),
                        ),
                        const SizedBox(height: 12),
                        _ComingUp(
                          task: upcoming,
                          open: () => _openTask(context, state, upcoming),
                        ),
                      ],
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

  void _openTask(
    BuildContext context,
    WorkspacePreview state,
    PreviewTask task,
  ) {
    state.selectTask(task);
    TmsRoute.task.open(context);
  }
}

class _HomeFabLocation extends FloatingActionButtonLocation {
  const _HomeFabLocation();
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) => Offset(
    geometry.scaffoldSize.width -
        geometry.minInsets.right -
        geometry.floatingActionButtonSize.width -
        18 -
        math.max(0, (geometry.scaffoldSize.width - 560) / 2),
    geometry.contentBottom - geometry.floatingActionButtonSize.height - 16,
  );
}
