part of '../workspace_plan_screen.dart';

abstract class _WorkspacePlanActions extends ConsumerState<_WorkspaceSections> {
  late WorkspaceSection section = widget.initial;
  late WorkspaceStatus? filter = widget.initialFilter;

  @override
  void initState() {
    super.initState();
    final item = workspace
        .items(section)
        .where((r) => r.id == widget.itemId)
        .firstOrNull;
    if (item != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showRecord(item);
      });
    }
  }

  final search = TextEditingController();
  bool searching = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void selectSection(WorkspaceSection next) {
    if (section == next) return;
    setState(() {
      section = next;
      filter = null;
      searching = false;
      search.clear();
    });
  }

  Future<void> redeem(WorkspaceRecord reward) async {
    final people = {
      for (final item in workspace.records)
        if (item.section.view == WorkspaceView.review && item.person.isNotEmpty)
          item.person,
      for (final item in workspace.items(WorkspaceSection.household))
        item.title,
    };
    final person = await designSheet<String>(
      context,
      title: context.tr('workspaces.redeem'),
      builder: (context) => Column(
        children: [
          if (people.isEmpty) DesignLabel(context.tr('workspaces.earn_points')),
          for (final name in people)
            ListTile(
              title: Text(name),
              subtitle: Text(
                context.plural(
                  'workspaces.points',
                  workspace.availablePoints(name),
                  name: 'count',
                ),
              ),
              enabled: workspace.availablePoints(name) >= reward.points,
              onTap: () => Navigator.pop(context, name),
            ),
        ],
      ),
    );
    if (mounted && person != null) {
      await saveWorkspaceChange(
        context,
        () => directory.redeemReward(workspace.id, reward.id, person),
      );
    }
  }

  LocalWorkspace get workspace => widget.workspace;
  LocalWorkspaces get directory => ref.read(localWorkspacesProvider.notifier);

  Future<void> edit(WorkspaceSection section, [WorkspaceRecord? record]) async {
    final changed = await editWorkspaceRecord(
      context,
      workspace,
      section,
      record: record,
    );
    if (!mounted || changed == null) return;
    await saveWorkspaceChange(
      context,
      () => directory.saveRecord(
        workspace.id,
        changed.record,
        alsoAssignTo: changed.others,
      ),
    );
  }

  Future<void> update(
    WorkspaceRecord item,
    WorkspaceRecord Function(WorkspaceRecord) change,
  ) => saveWorkspaceChange(
    context,
    () => directory.updateRecord(workspace.id, item.id, change),
  );

  Future<void> recordPayment(WorkspaceRecord item) async {
    final amount = await designSheet<int>(
      context,
      title: context.tr('workspaces.record_payment'),
      builder: (_) => WorkspacePaymentForm(outstanding: item.outstanding),
    );
    if (!mounted || amount == null) return;
    await saveWorkspaceChange(
      context,
      () => directory.recordPayment(workspace.id, item.id, amount),
    );
  }

  Future<void> remove(WorkspaceRecord item) async {
    final confirmed = await designSheet<bool>(
      context,
      title: context.tr('workspaces.remove_record'),
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          DesignLabel(
            context.tr(
              'workspaces.remove_prompt',
              namedArgs: {'title': item.title},
            ),
          ),
          DesignButton(
            context.tr('workspaces.remove'),
            color: DesignColor.rose,
            onPressed: () => Navigator.pop(context, true),
          ),
          DesignButton(
            context.tr('workspaces.cancel'),
            secondary: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) {
      await saveWorkspaceChange(
        context,
        () => directory.removeRecord(workspace.id, item.id),
      );
    }
  }

  Future<void> showRecord(WorkspaceRecord item) async {
    final action = await designSheet<WorkspaceRecordAction>(
      context,
      title: item.title,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final current = ref
              .watch(localWorkspacesProvider)
              .asData
              ?.value
              .active
              ?.records
              .where((r) => r.id == item.id)
              .firstOrNull;
          if (current == null) return const SizedBox.shrink();
          return WorkspaceRecordDetails(
            workspaceId: workspace.id,
            record: current,
            onAction: (action) => Navigator.pop(context, action),
            onTodo: (name) => update(
              current,
              (r) => r.copyWith(
                todos: {...r.todos, name: !(r.todos[name] ?? false)},
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case WorkspaceRecordAction.edit:
        await edit(item.section, item);
      case WorkspaceRecordAction.remove:
        await remove(item);
      case WorkspaceRecordAction.pay:
        await recordPayment(item);
      case WorkspaceRecordAction.complete:
        await update(
          item,
          (current) => current.copyWith(
            status: switch (current.status) {
              WorkspaceStatus.done => WorkspaceStatus.todo,
              WorkspaceStatus.submitted => WorkspaceStatus.done,
              _ =>
                current.requiresReview
                    ? WorkspaceStatus.submitted
                    : WorkspaceStatus.done,
            },
          ),
        );
      case WorkspaceRecordAction.returnForChanges:
        await update(
          item,
          (current) => current.copyWith(status: WorkspaceStatus.returned),
        );
      case WorkspaceRecordAction.allowVisitor:
      case WorkspaceRecordAction.waitVisitor:
        await update(
          item,
          (r) => r.copyWith(
            status: action == WorkspaceRecordAction.allowVisitor
                ? WorkspaceStatus.confirmed
                : WorkspaceStatus.declined,
          ),
        );
      case WorkspaceRecordAction.startProgramme:
        await saveWorkspaceChange(
          context,
          () => directory.startProgrammeItem(workspace.id, item.id),
        );
      case WorkspaceRecordAction.redeem:
        await redeem(item);
      case WorkspaceRecordAction.flag:
        await update(
          item,
          (current) => current.copyWith(
            flagged: !current.flagged,
            status: current.section == WorkspaceSection.errands
                ? WorkspaceStatus.done
                : null,
          ),
        );
    }
  }
}
