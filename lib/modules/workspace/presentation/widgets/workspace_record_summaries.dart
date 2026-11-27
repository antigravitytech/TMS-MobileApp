part of 'workspace_record_widgets.dart';

class WorkspacePaymentForm extends StatefulWidget {
  const WorkspacePaymentForm({super.key, required this.outstanding});
  final int outstanding;

  @override
  State<WorkspacePaymentForm> createState() => _WorkspacePaymentFormState();
}

class _WorkspacePaymentFormState extends State<WorkspacePaymentForm> {
  String amount = '';
  bool attempted = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      DesignLabel(
        context.tr(
          'workspaces.balance_amount',
          namedArgs: {'amount': workspaceAmount(context, widget.outstanding)},
        ),
      ),
      DesignField(
        label: context.tr('workspaces.amount_ngn'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) => amount = value,
      ),
      if (attempted)
        Text(
          context.tr('workspaces.invalid_payment'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      DesignButton(
        context.tr('workspaces.record_payment'),
        onPressed: () {
          final parsed = parseWorkspaceAmount(amount);
          if (parsed != null && parsed > 0 && parsed <= widget.outstanding) {
            Navigator.pop(context, parsed);
          } else {
            setState(() => attempted = true);
          }
        },
      ),
    ],
  );
}

String? workspaceRecordSubtitle(BuildContext context, WorkspaceRecord record) {
  final section = record.section;
  final view = section.view;
  final localizations = MaterialLocalizations.of(context);
  final date = record.date;
  final parts = [
    if (record.person.isNotEmpty) record.person,
    if (section == WorkspaceSection.household &&
        record.fields.containsKey('householdRole'))
      context.tr('workspaces.roles.${record.fields['householdRole']}'),
    if (record.group.isNotEmpty && section != WorkspaceSection.school)
      section == WorkspaceSection.guests
          ? context.tr(
              'workspaces.table_name',
              namedArgs: {'table': record.group},
            )
          : record.group,
    if (section == WorkspaceSection.school && record.group.isNotEmpty)
      context.tr('workspaces.school_types.${record.group}'),
    if (date != null) localizations.formatMediumDate(date),
    if (date != null && view == WorkspaceView.schedule)
      TimeOfDay.fromDateTime(date).format(context),
    if (view == WorkspaceView.money &&
        record.outstanding > 0 &&
        date != null &&
        DateUtils.dateOnly(date).isBefore(DateUtils.dateOnly(DateTime.now())))
      context.tr('workspaces.overdue'),
    if (view == WorkspaceView.money)
      switch (record.outstanding) {
        0 => context.tr('workspaces.paid_in_full'),
        _ => context.tr(
          'workspaces.balance_amount',
          namedArgs: {'amount': workspaceAmount(context, record.outstanding)},
        ),
      },
    if (view == WorkspaceView.time || section == WorkspaceSection.programme)
      context.plural('workspaces.duration', record.duration, name: 'count'),
    if (view == WorkspaceView.time && record.flagged)
      context.tr('workspaces.billable'),
    if (view == WorkspaceView.review ||
        view == WorkspaceView.checklist ||
        section.tracksPeopleStatus)
      section.statusLabel(context, record.status),
    if (section == WorkspaceSection.guests)
      context.plural('workspaces.seat_count', record.duration, name: 'count'),
    if (view == WorkspaceView.notice)
      context.tr(record.flagged ? 'workspaces.read' : 'workspaces.unread'),
    if (section == WorkspaceSection.rewards)
      context.plural('workspaces.points', record.points, name: 'count'),
    if (section == WorkspaceSection.programme &&
        record.status != WorkspaceStatus.todo)
      section.statusLabel(context, record.status),
    if (section == WorkspaceSection.visitors)
      section.statusLabel(context, record.status),
    if ((section == WorkspaceSection.guests ||
            section == WorkspaceSection.passes) &&
        record.flagged)
      context.tr('workspaces.pass_checked_in'),
    if (section == WorkspaceSection.prayers && record.flagged)
      context.tr('workspaces.prayed'),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
