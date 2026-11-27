part of '../approvals_screen.dart';

extension _ReviewActions on _ApprovalsScreenState {
  Future<void> _decide(TaskItem task, bool approve) async {
    if (outgoing) return;
    var note = '';
    if (!approve) {
      _update(() {
        dx = 0;
        dragging = false;
      });
      var reason = -1;
      var typed = '';
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
          namedArgs: {'name': task.assignee?.firstName ?? ''},
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
                onChanged: (value) => update(() => typed = value),
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
                // The server needs a note; a reason chip counts as one.
                onPressed: reason < 0 && typed.trim().isEmpty
                    ? null
                    : () => Navigator.pop(sheet, true),
              ),
            ],
          ),
        ),
      );
      if (!mounted || confirm != true) return;
      note = [
        if (reason >= 0) context.tr(reasons[reason]),
        if (typed.trim().isNotEmpty) typed.trim(),
      ].join('. ');
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
    final controller = ref.read(approvalsProvider.notifier);
    try {
      await (approve
          ? controller.approve(task)
          : controller.returnTask(task, note));
    } catch (error) {
      if (!mounted) return;
      // The card comes back so the decision can be tried again.
      _update(() {
        outgoing = false;
        dx = 0;
      });
      designToast(context, taskErrorMessage(context, error));
      return;
    }
    if (!mounted) return;
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
