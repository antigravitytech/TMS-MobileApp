import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../alumni/application/alumni_controller.dart';
import '../../alumni/presentation/widgets/alumni_money.dart';
import '../../authentication/domain/account.dart';
import '../../church/application/church_controller.dart';
import '../../church/presentation/widgets/church_overview.dart';
import '../../club/application/club_controller.dart';
import '../../club/presentation/widgets/club_tabs.dart';
import '../../committee/application/committee_controller.dart';
import '../../committee/presentation/widgets/committee_tabs.dart';
import '../../estate/application/estate_controller.dart';
import '../../estate/presentation/widgets/estate_tabs.dart';
import '../../event/application/event_controller.dart';
import '../../event/presentation/widgets/event_overview.dart';
import '../../family/presentation/widgets/family_home_metric.dart';
import '../../individual/presentation/widgets/individual_home_parts.dart';
import '../../individual/presentation/widgets/individual_home_widgets.dart';
import '../../notifications/presentation/widgets/live_notification_bell.dart';
import '../../specials/presentation/special_home_shell.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../data/live_home_repository.dart';

part 'widgets/live_personal_overview.dart';

class LiveSpaceDashboard extends StatefulWidget {
  const LiveSpaceDashboard({
    super.key,
    required this.account,
    required this.data,
    required this.refresh,
    required this.workspace,
  });

  final Account account;
  final LocalWorkspace workspace;
  final LiveHomeData data;
  final Future<void> Function() refresh;

  @override
  State<LiveSpaceDashboard> createState() => _LiveSpaceDashboardState();
}

class _LiveSpaceDashboardState extends State<LiveSpaceDashboard> {
  WorkspaceSection? _selected;

  void _select(WorkspaceSection? section) =>
      setState(() => _selected = section);

  @override
  Widget build(BuildContext context) {
    final workspace = widget.workspace;
    final sections = {
      ...workspace.kind.sections,
      ...workspace.records.map((record) => record.section),
    };

    return SpecialHomeShell<WorkspaceSection?>(
      workspace: workspace,
      logoColor: workspace.kind == WorkspaceKind.family
          ? DesignColor.teal
          : DesignColor.purple,
      openAccount: () => TmsRoute.account.open(context),
      notificationBell: LiveNotificationBell(workspaceId: workspace.id),
      tabs: [null, ...sections],
      selected: _selected,
      label: (section) => section == null
          ? context.tr('home.live_overview')
          : context.tr('workspaces.sections.${section.name}.title'),
      onTab: _select,
      body: Column(
        children: [
          if (widget.data.failed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: DesignLabel(context.tr('home.live_partial')),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.refresh,
              child: _selected == null
                  ? _overview(workspace)
                  : _LiveRecords(workspace.items(_selected!).toList()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overview(LocalWorkspace workspace) {
    final now = DateTime.now();
    void selectTab(Enum tab) {
      final name = switch (tab.name) {
        'prayer' => 'prayers',
        final name => name,
      };
      final section = workspace.kind.sections
          .where((section) => section.name == name)
          .firstOrNull;
      if (section != null) _select(section);
    }

    return switch (workspace.kind) {
      WorkspaceKind.church => ChurchOverview(
        view: ChurchView(workspace, now),
        onTab: selectTab,
      ),
      WorkspaceKind.alumni => AlumniOverview(
        view: AlumniView(workspace, now),
        onTab: selectTab,
      ),
      WorkspaceKind.estate => EstateOverview(
        view: EstateView(workspace, now),
        onTab: selectTab,
      ),
      WorkspaceKind.event => EventOverview(
        view: EventView(workspace, now),
        onTab: selectTab,
        readOnly: true,
      ),
      WorkspaceKind.committee => CommitteeOverview(
        view: CommitteeView(workspace, now),
        onTab: selectTab,
      ),
      WorkspaceKind.club => ClubOverview(
        view: ClubView(workspace, now),
        onTab: selectTab,
      ),
      _ => _LivePersonalOverview(
        workspace: workspace,
        account: widget.account,
        data: widget.data,
        onSelect: _select,
      ),
    };
  }
}

class _LiveRecords extends StatelessWidget {
  const _LiveRecords(this.records);

  final List<WorkspaceRecord> records;

  @override
  Widget build(BuildContext context) => ListView.separated(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(20),
    itemCount: records.isEmpty ? 1 : records.length,
    separatorBuilder: (_, _) => const SizedBox(height: 10),
    itemBuilder: (context, index) => records.isEmpty
        ? DesignLabel(context.tr('home.live_empty'))
        : _LiveRecordCard(records[index]),
  );
}

class _LiveRecordCard extends StatelessWidget {
  const _LiveRecordCard(this.record);

  final WorkspaceRecord record;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(record.title, style: Theme.of(context).textTheme.titleMedium),
          if (record.person.isNotEmpty) DesignLabel(record.person),
          if (record.date case final date?)
            DesignLabel(DateFormat.yMMMd(locale).format(date)),
          if (record.notes.isNotEmpty) DesignLabel(record.notes),
          if (record.amount > 0)
            Text(
              NumberFormat.simpleCurrency(
                locale: locale,
                name: 'NGN',
              ).format(record.amount / 100),
            ),
          for (final option in record.options) DesignLabel(option),
        ],
      ),
    );
  }
}
