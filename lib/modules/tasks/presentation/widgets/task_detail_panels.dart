part of '../task_detail_screen.dart';

class _CommentsPanel extends StatelessWidget {
  const _CommentsPanel({
    required this.task,
    required this.state,
    required this.controller,
  });
  final PreviewTask task;
  final WorkspacePreview state;
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: DesignColor.blue,
            child: Text(
              'IM',
              style: TextStyle(fontSize: 10, color: DesignColor.ink),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DesignCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('tasks.ibrahim_2d'),
                    style: TextStyle(fontSize: 11, color: context.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('tasks.sample_comment'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      for (final value in state.comments[task.id] ?? <String>[]) ...[
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: DesignCard(child: Text(value)),
        ),
      ],
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
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
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              state.addComment(task.id, text);
              controller.clear();
            },
            icon: const Icon(TmsIcons.send),
            tooltip: context.tr('tasks.send_comment'),
          ),
        ],
      ),
    ],
  );
}

class _FilesPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DesignSection(
    children: [
      DesignTile(
        title: context.tr('tasks.sample_file'),
        subtitle: context.tr('tasks.sample_file_meta'),
        icon: TmsIcons.file,
        onTap: () => TmsRoute.files.open(context),
      ),
      DesignTile(
        title: context.tr('tasks.attach_a_file'),
        icon: TmsIcons.add,
        onTap: () => TmsRoute.files.open(context),
      ),
    ],
  );
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel(this.task);
  final PreviewTask task;
  @override
  Widget build(BuildContext context) => DesignSection(
    children: [
      _DetailRow(
        context.tr('tasks.type'),
        taskProjectLabel(context, task.project),
      ),
      _DetailRow(context.tr('tasks.visibility'), context.tr('tasks.public')),
      _DetailRow(context.tr('tasks.watching'), 'CO · IM'),
      _DetailRow(context.tr('tasks.created'), context.tr('tasks.created_date')),
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
