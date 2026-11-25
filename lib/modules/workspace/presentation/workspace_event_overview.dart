part of 'workspace_home.dart';

class _EventOverview extends StatelessWidget {
  const _EventOverview({required this.workspace, required this.onEdit});
  final LocalWorkspace workspace;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final date = workspace.eventDate;
    final now = DateTime.now();
    final days = date == null
        ? null
        : DateTime.utc(
            date.year,
            date.month,
            date.day,
          ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    final guests = workspace.items(WorkspaceSection.guests);
    final confirmed = guests
        .where((guest) => guest.status == WorkspaceStatus.confirmed)
        .fold(0, (total, guest) => total + guest.duration);
    final awaiting = guests
        .where((guest) => guest.status == WorkspaceStatus.pending)
        .length;

    final vendorPayments = workspace
        .items(WorkspaceSection.vendors)
        .fold(0, (sum, vendor) => sum + vendor.paid);

    return DesignCard(
      color: Color.alphaBlend(
        workspace.kind.accent.withValues(alpha: .13),
        Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 9,
        children: [
          DesignTitle(switch (days) {
            null => context.tr('workspaces.no_event_date'),
            0 => context.tr('workspaces.event_today'),
            < 0 => context.tr('workspaces.event_passed'),
            _ => context.plural(
              'workspaces.days_to_event',
              days,
              name: 'count',
            ),
          }),
          if (date != null)
            DesignLabel(MaterialLocalizations.of(context).formatFullDate(date)),
          if (workspace.eventVenue.isNotEmpty)
            DesignLabel(workspace.eventVenue),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DesignPill(
                context.plural(
                  'workspaces.confirmed_seats',
                  confirmed,
                  name: 'count',
                ),
              ),
              DesignPill(
                context.plural(
                  'workspaces.awaiting_rsvp',
                  awaiting,
                  name: 'count',
                ),
              ),
            ],
          ),
          if (workspace.eventCapacity > 0)
            DesignLabel(
              context.plural(
                'workspaces.event_capacity',
                workspace.eventCapacity,
                name: 'count',
              ),
            ),
          if (workspace.eventBudget > 0)
            DesignLabel(
              context.tr(
                'workspaces.budget_used',
                namedArgs: {
                  'paid': workspaceAmount(context, vendorPayments),
                  'budget': workspaceAmount(context, workspace.eventBudget),
                },
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              DesignPill(
                context.tr('workspaces.event_details'),
                icon: TmsIcons.editCalendar,
                onTap: onEdit,
              ),
              DesignPill(
                context.tr('workspaces.guest_page'),
                icon: TmsIcons.visibility,
                onTap: () => designSheet<void>(
                  context,
                  title: context.tr('workspaces.guest_page'),
                  builder: (_) =>
                      WorkspaceEventInvitation(workspaceId: workspace.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventDetailsForm extends StatefulWidget {
  const _EventDetailsForm({required this.workspace});
  final LocalWorkspace workspace;

  @override
  State<_EventDetailsForm> createState() => _EventDetailsFormState();
}

class _EventDetailsFormState extends State<_EventDetailsForm> {
  late String name = widget.workspace.name;
  late DateTime? date = widget.workspace.eventDate;
  late String venue = widget.workspace.eventVenue;
  late String capacity = widget.workspace.eventCapacity == 0
      ? ''
      : widget.workspace.eventCapacity.toString();
  late String budget = widget.workspace.eventBudget == 0
      ? ''
      : (widget.workspace.eventBudget / 100).toStringAsFixed(2);
  bool invalid = false;

  void save() {
    final seats = capacity.trim().isEmpty ? 0 : int.tryParse(capacity.trim());
    final cost = budget.trim().isEmpty ? 0 : parseWorkspaceAmount(budget);
    if (seats == null || seats < 0 || seats > 100000 || cost == null) {
      setState(() => invalid = true);
      return;
    }
    final _EventDetails details = (
      name: name.trim(),
      date: date,
      venue: venue.trim(),
      capacity: seats,
      budget: cost,
    );
    Navigator.pop(context, details);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      DesignField(
        label: context.tr('workspaces.event_name'),
        initialValue: name,
        onChanged: (value) => name = value,
      ),
      DesignButton(
        date == null
            ? context.tr('workspaces.pick_date')
            : MaterialLocalizations.of(context).formatFullDate(date!),
        secondary: true,
        icon: TmsIcons.calendar,
        onPressed: () async {
          final selected = await pickWorkspaceDate(context, date);
          if (mounted && selected != null) setState(() => date = selected);
        },
      ),
      DesignField(
        label: context.tr('workspaces.venue'),
        initialValue: venue,
        onChanged: (value) => venue = value,
      ),
      DesignField(
        label: context.tr('workspaces.capacity'),
        initialValue: capacity,
        keyboardType: TextInputType.number,
        onChanged: (value) => capacity = value,
      ),
      DesignField(
        label: context.tr('workspaces.budget_ngn'),
        initialValue: budget,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) => budget = value,
      ),
      if (invalid) DesignLabel(context.tr('workspaces.invalid_event_details')),
      DesignButton(context.tr('workspaces.save'), onPressed: save),
    ],
  );
}
