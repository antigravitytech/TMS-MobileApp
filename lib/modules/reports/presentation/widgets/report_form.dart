part of '../reports_screen.dart';

/// Today's report, laid out as in the design: what got done, what's next,
/// a project link (when offered) and "I'm blocked".
class _ReportForm extends ConsumerStatefulWidget {
  const _ReportForm({super.key, required this.report});
  final DailyReport report;
  @override
  ConsumerState<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends ConsumerState<_ReportForm> {
  late final answers = <String, String>{...widget.report.draft};
  int project = 0;
  bool blocked = false, sending = false;

  DailyReport get report => widget.report;
  ReportField? get _blockers =>
      report.fields.where((f) => f.role == ReportRole.blockers).firstOrNull;

  bool get _ready => report.fields.every(
    (f) =>
        !f.required ||
        (f.role == ReportRole.blockers && !blocked) ||
        (answers[f.id]?.trim().isNotEmpty ?? false),
  );

  Future<void> _send() async {
    setState(() => sending = true);
    final values = <String, Object>{
      for (final f in report.fields)
        if (answers[f.id]?.trim() case final v? when v.isNotEmpty)
          if (f.role != ReportRole.blockers || blocked)
            f.id: switch (f.type) {
              'number' => num.tryParse(v) ?? v,
              'rating' => int.tryParse(v) ?? v,
              _ => v,
            },
    };
    try {
      await ref.read(dailyReportProvider.notifier).send(values);
    } catch (error) {
      if (mounted) designToast(context, taskErrorMessage(context, error));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Widget _field(ReportField f, {String? hint}) => switch (f.type) {
    'choice' || 'rating' => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option
            in f.type == 'rating' ? const ['1', '2', '3', '4', '5'] : f.options)
          _ReportChip(
            option,
            selected: answers[f.id] == option,
            onTap: () => setState(() => answers[f.id] = option),
          ),
      ],
    ),
    _ => _ReportInput(
      initialValue: answers[f.id],
      hint: hint,
      lines: f.type == 'long' ? 3 : 1,
      onChanged: (v) => setState(() => answers[f.id] = v),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final blockers = _blockers;
    final reviewer = report.reviewer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DesignColor.teal.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: DesignColor.teal.withValues(alpha: .25),
                ),
              ),
              child: const Icon(
                TmsIcons.edit,
                color: DesignColor.teal,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (reviewer.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.tr(
                        'reports.for_name',
                        namedArgs: {'name': reviewer},
                      ),
                      style: TextStyle(color: context.muted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (report.dueTime.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: DesignColor.amber.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '•  ${context.tr('reports.due_at', namedArgs: {'time': report.dueTime})}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: DesignColor.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        for (final f in report.fields)
          if (f.role != ReportRole.blockers) ...[
            DesignLabel(f.label),
            _field(
              f,
              hint: f.role == ReportRole.plan
                  ? context.tr('reports.tomorrows_focus')
                  : null,
            ),
          ],
        if (report.projects.isNotEmpty) ...[
          DesignLabel(context.tr('reports.link_to_a_project')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, name) in [
                context.tr('common.standalone'),
                ...report.projects,
              ].indexed)
                _ReportChip(
                  name,
                  selected: project == i,
                  onTap: () => setState(() => project = i),
                ),
            ],
          ),
        ],
        if (blockers != null) ...[
          DesignCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DesignColor.red.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: DesignColor.red.withValues(alpha: .3),
                    ),
                  ),
                  child: const Icon(
                    TmsIcons.warning,
                    color: DesignColor.red,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('reports.im_blocked'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (reviewer.isNotEmpty)
                        Text(
                          context.tr(
                            'reports.flags_it_to',
                            namedArgs: {'name': reviewer.split(' ').first},
                          ),
                          style: TextStyle(color: context.muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => blocked = !blocked),
                  child: AnimatedContainer(
                    duration: DesignMotion.fast,
                    width: 52,
                    height: 32,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: blocked
                          ? DesignColor.purple
                          : context.foreground.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AnimatedAlign(
                      duration: DesignMotion.fast,
                      alignment: blocked
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: context.foreground,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (blocked) ...[DesignLabel(blockers.label), _field(blockers)],
        ],
        DesignButton(
          context.tr('reports.send_report'),
          onPressed: !_ready || sending || !report.canLog ? null : _send,
        ),
      ],
    );
  }
}
