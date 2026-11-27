part of '../live_space_dashboard.dart';

class _LivePersonalOverview extends StatelessWidget {
  const _LivePersonalOverview({
    required this.workspace,
    required this.account,
    required this.data,
    required this.onSelect,
  });

  final LocalWorkspace workspace;
  final Account account;
  final LiveHomeData data;
  final ValueChanged<WorkspaceSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final family = workspace.kind == WorkspaceKind.family;
    final attention = workspace.records
        .where(
          (row) => family
              ? {
                      WorkspaceSection.school,
                      WorkspaceSection.chores,
                      WorkspaceSection.errands,
                    }.contains(row.section) &&
                    row.status != WorkspaceStatus.done
              : row.section == WorkspaceSection.tasks &&
                    row.status != WorkspaceStatus.done,
        )
        .take(5);
    final metricSections = [
      (WorkspaceSection.clients, TmsIcons.person, DesignColor.blue),
      (WorkspaceSection.invoices, TmsIcons.card, DesignColor.green),
      (WorkspaceSection.time, TmsIcons.timer, DesignColor.amber),
      (WorkspaceSection.proposals, TmsIcons.file, DesignColor.purple),
    ];
    String metricValue(WorkspaceSection section) {
      final rows = workspace.items(section);
      final locale = context.locale.toString();
      return switch (section) {
        WorkspaceSection.invoices => NumberFormat.simpleCurrency(
          locale: locale,
          name: 'NGN',
        ).format(rows.fold<int>(0, (sum, row) => sum + row.paid) / 100),
        WorkspaceSection.time => context.tr(
          'individual.hours',
          namedArgs: {
            'n': NumberFormat.decimalPattern(
              locale,
            ).format(rows.fold<int>(0, (sum, row) => sum + row.duration) / 60),
          },
        ),
        WorkspaceSection.proposals =>
          NumberFormat.decimalPattern(locale).format(
            rows.where((row) => row.status != WorkspaceStatus.done).length,
          ),
        _ => NumberFormat.decimalPattern(locale).format(rows.length),
      };
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          context.tr('home.greeting', namedArgs: {'name': account.firstName}),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        DesignTitle(
          context.tr(
            family ? 'workspaces.today_at_home' : 'individual.your_business',
          ),
        ),
        const SizedBox(height: 12),
        if (family)
          for (final row in [0, 1])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                spacing: 10,
                children: [
                  for (final column in [0, 1])
                    Expanded(
                      child: FamilyHomeMetric(
                        index: row * 2 + column,
                        workspace: workspace,
                        readOnly: true,
                      ),
                    ),
                ],
              ),
            )
        else
          IndividualKpiGrid(
            children: [
              for (final (section, icon, color) in metricSections)
                IndividualKpi(
                  icon: icon,
                  color: color,
                  value: metricValue(section),
                  label: context.tr(switch (section) {
                    WorkspaceSection.invoices => 'home.live_invoice_payments',
                    WorkspaceSection.time => 'home.live_hours_logged',
                    WorkspaceSection.proposals => 'individual.open_proposals',
                    _ => 'workspaces.sections.${section.name}.title',
                  }),
                  onTap: () => onSelect(section),
                ),
            ],
          ),
        const SizedBox(height: 22),
        DesignTitle(
          context.tr(family ? 'dashboard.needs_you' : 'individual.coming_up'),
        ),
        const SizedBox(height: 12),
        if (attention.isEmpty) DesignLabel(context.tr('home.live_empty')),
        for (final record in attention)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LiveRecordCard(record),
          ),
        if (family &&
            dashboardRows(data.object('family')['points']).isNotEmpty) ...[
          const SizedBox(height: 22),
          DesignTitle(context.tr('family_home.points_rewards')),
          const SizedBox(height: 12),
          DesignCard(
            child: Text(
              context.tr(
                'home.live_family_points',
                namedArgs: {
                  'count':
                      NumberFormat.decimalPattern(
                        context.locale.toString(),
                      ).format(
                        dashboardRows(
                          data.object('family')['points'],
                        ).fold<int>(
                          0,
                          (total, row) =>
                              total + dashboardInteger(row['points']),
                        ),
                      ),
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
