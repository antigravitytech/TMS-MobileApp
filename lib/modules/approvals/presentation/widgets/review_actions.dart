part of '../approvals_screen.dart';

extension _ReviewActions on _ApprovalsScreenState {
  Future<void> _decide(PreviewTask task, bool approve) async {
    if (outgoing) return;
    if (!approve) {
      _update(() {
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < reasons.length; i++)
                    _ReviewChip(
                      context.tr(reasons[i]),
                      selected: reason == i,
                      onTap: () => update(() => reason = i),
                    ),
                ],
              ),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: context.tr('approvals.notes_hint'),
                  filled: true,
                  fillColor: context.panel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              DesignButton(
                context.tr('approvals.return_with_notes'),
                color: const Color(0xfff59562),
                onPressed: () => Navigator.pop(sheet, true),
              ),
            ],
          ),
        ),
      );
      if (!mounted || confirm != true) return;
    }
    _update(() {
      outgoing = true;
      dragging = false;
      dx = approve ? 465 : -465;
    });
    await Future<void>.delayed(
      DesignMotion.duration(context, DesignMotion.object),
    );
    if (!mounted) return;
    ref.read(workspacePreviewProvider).review(task, approve: approve);
    _update(() {
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
}
