part of '../home_screen.dart';

class _LiveBusinessHome extends ConsumerStatefulWidget {
  const _LiveBusinessHome({
    super.key,
    required this.account,
    required this.data,
    required this.refresh,
  });

  final Account account;
  final LiveHomeData data;
  final Future<void> Function() refresh;

  @override
  ConsumerState<_LiveBusinessHome> createState() => _LiveBusinessHomeState();
}

class _LiveBusinessHomeState extends ConsumerState<_LiveBusinessHome> {
  String? _dismissedBirthday;
  final _top = GlobalKey();

  /// Opens a dashboard task with the data already loaded; no request.
  void _openTask(DashboardJson task) {
    if (task['id'] is! String) return;
    try {
      ref.read(openedTaskProvider.notifier).open(taskItemFromJson(task));
    } on TypeError {
      return;
    }
    TmsRoute.task.open(context);
  }

  Future<void> _action(Future<bool> operation, String confirmation) async {
    try {
      final completed = await operation;
      if (mounted && completed) designToast(context, context.tr(confirmation));
    } catch (error) {
      if (mounted) designToast(context, _dashboardError(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final busy = ref.watch(liveHomeActionsProvider(data.workspace));
    final actions = ref.read(liveHomeActionsProvider(data.workspace).notifier);
    final summary = data.object('summary');
    final mine = dashboardObject(summary['my_tasks']);
    final review = dashboardObject(summary['review']);
    final birthday = dashboardRows(data.object('birthdays')['today'])
        .where((entry) => entry['i_wished'] != true)
        .map(_birthdayPerson)
        .nonNulls
        .where((person) => person.id != widget.account.id)
        .firstOrNull;
    final birthdayId = birthday?.id;
    final report = data
        .rows('routines')
        .where((entry) => dashboardObject(entry['routine'])['kind'] == 'report')
        .firstOrNull;
    final due = data.rows('due');
    final reviews = data.rows('review');
    final upcoming = data
        .rows('upcoming')
        .where((row) => dashboardDate(row['due_date']) != null);
    final team = data.rows('team');
    final submitted = team.where((entry) => entry['submitted'] == true).length;
    return Scaffold(
      backgroundColor: context.background,
      bottomNavigationBar: _LiveHomeNavigation(data: data, home: _top),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeHeader(
                  state: null,
                  account: widget.account,
                  workspace: data.name,
                  workspaceId: data.workspace.id,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: widget.refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DesignEntrance(
                            key: _top,
                            child: _HomeOverview(
                              firstName: widget.account.firstName,
                              due: dashboardCount(mine['due_today']),
                              overdue: dashboardCount(mine['overdue']),
                              reviews: dashboardCount(review['waiting']),
                              preview: false,
                              birthday:
                                  birthdayId == null ||
                                      birthdayId == _dismissedBirthday
                                  ? null
                                  : _BirthdayBanner(
                                      name: birthday!.name.split(' ').first,
                                      onClose: () => setState(
                                        () => _dismissedBirthday = birthdayId,
                                      ),
                                      onWish: busy
                                          ? null
                                          : () => _action(
                                              actions.wish(birthday),
                                              'home.live_wish_sent',
                                            ),
                                    ),
                            ),
                          ),
                          if (data.failed.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            DesignLabel(context.tr('home.live_partial')),
                          ],
                          if (report != null) ...[
                            const SizedBox(height: 26),
                            _Heading(context.tr('home.daily_report')),
                            const SizedBox(height: 12),
                            _LiveDailyReport(
                              report: report,
                              actions: actions,
                              busy: busy,
                            ),
                          ],
                          if (!data.failed.contains('due')) ...[
                            const SizedBox(height: 26),
                            _Heading(
                              context.tr('home.due_heading'),
                              count: dashboardCount(mine['due_today']),
                              trailing: _HomeLink(
                                context.tr('home.view_all'),
                                TmsRoute.tasks,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (due.isEmpty)
                              DesignLabel(context.tr('home.live_empty')),
                            for (final (index, task) in due.indexed) ...[
                              if (index > 0) const SizedBox(height: 10),
                              _DueTask(
                                task: _dashboardTask(context, task),
                                open: () => _openTask(task),
                              ),
                            ],
                          ],
                          if (!data.failed.contains('review')) ...[
                            const SizedBox(height: 26),
                            _Heading(
                              context.tr('home.awaiting_heading'),
                              count: dashboardCount(review['waiting']),
                              trailing: _HomeLink(
                                context.tr('home.open_queue'),
                                TmsRoute.approvals,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (reviews.isEmpty)
                              DesignLabel(context.tr('home.review_clear')),
                            for (final (index, task) in reviews.indexed) ...[
                              if (index > 0) const SizedBox(height: 10),
                              _ReviewCard(
                                task: _dashboardTask(
                                  context,
                                  task,
                                  reviewer: true,
                                ),
                                preview: false,
                                onReturn: busy || task['id'] is! String
                                    ? null
                                    : () async {
                                        final note = await _returnNote(context);
                                        if (note != null && context.mounted) {
                                          await _action(
                                            actions.returnTask(
                                              taskItemFromJson(task),
                                              note,
                                            ),
                                            'home.live_returned',
                                          );
                                        }
                                      },
                                onApprove: busy || task['id'] is! String
                                    ? null
                                    : () => _action(
                                        actions.approve(taskItemFromJson(task)),
                                        'home.live_approved',
                                      ),
                              ),
                            ],
                          ],
                          if (team.isNotEmpty) ...[
                            const SizedBox(height: 26),
                            _Heading(context.tr('home.team_today')),
                            const SizedBox(height: 12),
                            DesignCard(
                              child: Text(
                                context.tr(
                                  'home.live_team_submitted',
                                  namedArgs: {
                                    'submitted': NumberFormat.decimalPattern(
                                      context.locale.toString(),
                                    ).format(submitted),
                                    'total': NumberFormat.decimalPattern(
                                      context.locale.toString(),
                                    ).format(team.length),
                                  },
                                ),
                              ),
                            ),
                          ],
                          if (upcoming.isNotEmpty) ...[
                            const SizedBox(height: 26),
                            _Heading(
                              context.tr('home.coming_up'),
                              trailing: _HomeCaption(
                                context.tr('home.next_week'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (final (index, task) in upcoming.indexed) ...[
                              if (index > 0) const SizedBox(height: 10),
                              _ComingUp(
                                task: _dashboardTask(context, task),
                                dueDate: dashboardDate(task['due_date']),
                                open: () => _openTask(task),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
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

/// A birthday feed entry, or null when it isn't a valid person.
BirthdayPerson? _birthdayPerson(DashboardJson entry) {
  try {
    return BirthdayPerson.fromJson(entry);
  } on TypeError {
    return null;
  }
}
