part of '../task_detail_screen.dart';

class _CommentsPanel extends ConsumerStatefulWidget {
  const _CommentsPanel({required this.task, required this.controller});
  final TaskItem task;
  final TextEditingController controller;
  @override
  ConsumerState<_CommentsPanel> createState() => _CommentsPanelState();
}

class _CommentsPanelState extends ConsumerState<_CommentsPanel> {
  bool sending = false;

  Future<void> send() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await ref.read(taskCommentsProvider(widget.task).notifier).add(text);
      widget.controller.clear();
    } catch (error) {
      if (mounted) designToast(context, taskErrorMessage(context, error));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = taskCommentsProvider(widget.task);
    return Column(
      children: [
        _tabState(
          context,
          ref,
          ref.watch(provider),
          provider,
          (rows) => Column(
            spacing: 10,
            children: [
              for (final c in rows)
                c.mine
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: DesignCard(child: Text(c.body)),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: kitPerson(c.author.name).$2,
                            child: Text(
                              kitPerson(c.author.name).$1,
                              style: const TextStyle(
                                fontSize: 10,
                                color: DesignColor.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DesignCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${c.author.firstName} · ${_when(context, c.at)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.body,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
            ],
          ),
        ),
        if (widget.task.permissions.canComment) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  onSubmitted: (_) => send(),
                  decoration: InputDecoration(
                    hintText: context.tr('tasks.comment_hint'),
                    filled: true,
                    fillColor: context.panel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: sending ? null : send,
                icon: const Icon(TmsIcons.send),
                tooltip: context.tr('tasks.send_comment'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FilesPanel extends ConsumerWidget {
  const _FilesPanel(this.task);
  final TaskItem task;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    spacing: 12,
    children: [
      _tabState(
        context,
        ref,
        ref.watch(taskFilesProvider(task)),
        taskFilesProvider(task),
        (rows) => DesignSection(
          children: [
            for (final f in rows)
              DesignTile(
                title: f.name,
                subtitle: '${(f.size / 1024).ceil()} KB',
                icon: TmsIcons.file,
              ),
          ],
        ),
      ),
      DesignSection(
        children: [
          DesignTile(
            title: context.tr('tasks.attach_a_file'),
            icon: TmsIcons.add,
            onTap: () => TmsRoute.files.open(context),
          ),
        ],
      ),
    ],
  );
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel(this.task);
  final TaskItem task;
  @override
  Widget build(BuildContext context) => DesignSection(
    children: [
      _DetailRow(context.tr('tasks.type'), taskTypeText(context, task.type)),
      if (task.project.isNotEmpty)
        _DetailRow(context.tr('common.project'), task.project),
      _DetailRow(
        context.tr('tasks.visibility'),
        context.tr(task.confidential ? 'tasks.confidential' : 'tasks.public'),
      ),
      if (task.createdAt case final created?)
        _DetailRow(context.tr('tasks.created'), _when(context, created)),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: context.muted, fontSize: 13),
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );
}
