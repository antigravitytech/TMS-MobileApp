part of '../task_detail_screen.dart';

class _TaskTabs extends StatelessWidget {
  const _TaskTabs(this.selected, this.onSelect);
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    final labels = [
      context.tr('tasks.activity'),
      context.tr('tasks.comments'),
      context.tr('common.files'),
      context.tr('tasks.details'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.panel,
        border: Border.all(color: context.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: DesignMotion.duration(context, DesignMotion.fast),
                  curve: DesignMotion.curve,
                  height: 39,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == i ? context.raised : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected == i
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected == i ? context.foreground : context.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loading, error and empty states shared by the task tabs.
Widget _tabState<T>(
  BuildContext context,
  WidgetRef ref,
  AsyncValue<List<T>> value,
  ProviderOrFamily provider,
  Widget Function(List<T>) data,
) => switch (value) {
  AsyncValue(value: final rows?) =>
    rows.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: DesignLabel(context.tr('common.nothing_here')),
            ),
          )
        : data(rows),
  AsyncValue(:final error?) => Column(
    spacing: 10,
    children: [
      DesignLabel(taskErrorMessage(context, error)),
      DesignButton(
        context.tr('workspaces.try_again'),
        secondary: true,
        onPressed: () => ref.invalidate(provider),
      ),
    ],
  ),
  _ => const Padding(
    padding: EdgeInsets.all(20),
    child: Center(child: CircularProgressIndicator()),
  ),
};

/// Activity kinds with their own wording; others read as an update.
const _activityKinds = {
  'created',
  'started',
  'submitted',
  'returned',
  'approved',
  'completed',
  'reopened',
  'due_date_changed',
  'reassigned',
  'commented',
  'attachment_added',
};

/// "17 Nov · 09:00".
String _when(BuildContext context, DateTime at) =>
    DateFormat('d MMM · HH:mm', context.locale.toString()).format(at);

class _ActivityPanel extends ConsumerWidget {
  const _ActivityPanel(this.task);
  final TaskItem task;
  @override
  Widget build(BuildContext context, WidgetRef ref) => _tabState(
    context,
    ref,
    ref.watch(taskActivityProvider(task)),
    taskActivityProvider(task),
    (rows) => Column(
      children: [
        for (final a in rows)
          _ActivityRow(
            a.actor?.name ?? '',
            context.tr(
              'tasks.activity_kinds.${_activityKinds.contains(a.kind) ? a.kind : 'updated'}',
              namedArgs: {'name': a.actor?.firstName ?? ''},
            ),
            _when(context, a.at),
          ),
      ],
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.name, this.title, this.time);
  final String name, title, time;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: kitPerson(name).$2,
          child: Text(
            kitPerson(name).$1,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: DesignColor.ink,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 3),
              Text(time, style: TextStyle(fontSize: 11, color: context.muted)),
            ],
          ),
        ),
      ],
    ),
  );
}
