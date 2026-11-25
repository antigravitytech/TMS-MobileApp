part of 'workspace_record_widgets.dart';

class WorkspaceTimeSummary extends StatelessWidget {
  const WorkspaceTimeSummary({
    super.key,
    required this.items,
    required this.hourlyRate,
    required this.editRate,
  });
  final int hourlyRate;
  final VoidCallback editRate;
  final List<WorkspaceRecord> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold(0, (sum, item) => sum + item.duration);
    final billable = items
        .where((item) => item.flagged)
        .fold(0, (sum, item) => sum + item.duration);
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          DesignTitle(
            context.plural('workspaces.time_logged', total, name: 'count'),
          ),
          DesignLabel(
            context.plural(
              'workspaces.billable_minutes',
              billable,
              name: 'count',
            ),
          ),
          DesignLabel(
            context.tr(
              'workspaces.week_value',
              namedArgs: {
                'rate': workspaceAmount(context, hourlyRate),
                'value': workspaceAmount(
                  context,
                  (billable * hourlyRate / 60).round(),
                ),
              },
            ),
          ),
          DesignPill(
            context.tr('workspaces.fields.hourlyRate'),
            icon: TmsIcons.edit,
            onTap: editRate,
          ),
          for (final client in items.map((r) => r.person).toSet())
            DesignTile(
              title: client.isEmpty
                  ? context.tr('workspaces.unassigned')
                  : client,
              subtitle: context.plural(
                'workspaces.duration',
                items
                    .where((r) => r.person == client)
                    .fold<int>(0, (t, r) => t + r.duration),
                name: 'count',
              ),
            ),
        ],
      ),
    );
  }
}

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

class WorkspacePollCard extends StatelessWidget {
  const WorkspacePollCard({
    super.key,
    required this.item,
    required this.showRecord,
    required this.onVote,
  });
  final WorkspaceRecord item;
  final VoidCallback showRecord;
  final ValueChanged<int> onVote;

  @override
  Widget build(BuildContext context) => DesignCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          children: [
            Expanded(child: DesignTitle(item.title)),
            DesignIcon(
              icon: TmsIcons.more,
              label: context.tr('workspaces.record_options'),
              onPressed: showRecord,
            ),
          ],
        ),
        if (item.notes.isNotEmpty) DesignLabel(item.notes),
        for (final (i, option) in item.options.indexed)
          if (item.vote == null)
            DesignButton(option, secondary: true, onPressed: () => onVote(i))
          else
            ListTile(
              title: Text(option),
              trailing: Text(
                context.plural(
                  'workspaces.votes',
                  item.vote == i ? 1 : 0,
                  name: 'count',
                ),
              ),
              leading: Icon(
                item.vote == i ? TmsIcons.checkCircle : TmsIcons.circle,
              ),
            ),
      ],
    ),
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
