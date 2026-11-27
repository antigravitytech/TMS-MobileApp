import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../bills/presentation/widgets/bills_widgets.dart' show naira;
import '../../workspace/application/workspace_preview.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit.dart';
import '../../../shared/kit/kit_visuals.dart';
import '../../workspace/presentation/widgets/workspace_quick_add.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../application/individual_home.dart';
import '../data/individual_reference.dart';
import 'widgets/individual_gig_watch.dart';
import 'widgets/individual_home_parts.dart';
import 'widgets/individual_home_widgets.dart';

class IndividualHomeScreen extends ConsumerWidget {
  const IndividualHomeScreen({super.key, required this.workspace});
  final LocalWorkspace workspace;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final id = workspace.id;
    final sum = ref.watch(individualSummaryProvider(id));
    final line = ref.watch(individualHomeProvider(id));
    final preview = ref.watch(workspacePreviewProvider);
    final name = workspaceName(c, workspace);
    final demo = workspace.records.any(
      (r) => r.id.startsWith(individualRefPrefix),
    );
    Future<void> add() async {
      final title = await ref.read(individualHomeProvider(id).notifier).add();
      if (title != null && c.mounted) {
        designToast(
          c,
          c.tr('individual.task_added', namedArgs: {'title': title}),
        );
      }
    }

    String compact(int kobo) => NumberFormat.compactCurrency(
      locale: c.locale.toString(),
      symbol: '₦',
      decimalDigits: kobo >= 100000000 ? 2 : 0,
    ).format(kobo / 100).toLowerCase();

    Widget heading(
      String title, {
      int? count,
      String? link,
      VoidCallback? go,
    }) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            IndividualCount(count),
          ],
          const Spacer(),
          if (link != null)
            GestureDetector(
              onTap: go,
              child: Text(
                link,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: c.lavender,
                ),
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: const WorkspaceQuickAdd(
        kind: WorkspaceKind.individual,
      ),
      bottomNavigationBar: const WorkspaceNavigation(
        kind: WorkspaceKind.individual,
        active: TmsRoute.home,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                spacing: 10,
                children: [
                  IndividualLogo(name),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.MMMMEEEEd(
                            c.locale.toString(),
                          ).format(DateTime.now()),
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  KitIconButton(
                    icon: TmsIcons.notifications,
                    tooltip: c.tr('common.notifications'),
                    onPressed: () => TmsRoute.notifications.open(c),
                  ),
                  GestureDetector(
                    onTap: () => TmsRoute.profile.open(c),
                    child: IndividualOnlineAvatar(
                      '${preview.firstName} ${preview.lastName}',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 110),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: DesignEntrance(
                      child: Text.rich(
                        TextSpan(
                          text: c.tr('individual.greeting'),
                          children: [
                            TextSpan(
                              text: preview.firstName,
                              style: TextStyle(color: c.lavender),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1.12,
                          letterSpacing: -.7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: DesignEntrance(
                      order: 1,
                      child: IndividualQuickAdd(
                        line: line,
                        onChanged: ref
                            .read(individualHomeProvider(id).notifier)
                            .edit,
                        onAdd: add,
                      ),
                    ),
                  ),
                  if (sum != null) ...[
                    heading(c.tr('individual.your_business')),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DesignEntrance(
                        order: 2,
                        child: IndividualKpiGrid(
                          children: [
                            IndividualKpi(
                              icon: TmsIcons.person,
                              color: DesignColor.blue,
                              value: '${sum.activeClients}',
                              suffix: '/${sum.clients}',
                              label: c.tr('individual.active_clients'),
                              onTap: () => WorkspaceSection.clients.open(c),
                            ),
                            IndividualKpi(
                              icon: TmsIcons.card,
                              color: DesignColor.green,
                              value: compact(sum.received),
                              label: c.plural(
                                'individual.billed_line',
                                sum.owing,
                                namedArgs: {'total': compact(sum.billed)},
                              ),
                              onTap: () => WorkspaceSection.invoices.open(c),
                            ),
                            IndividualKpi(
                              icon: TmsIcons.timer,
                              color: DesignColor.amber,
                              value: c.tr(
                                'individual.hours',
                                namedArgs: {
                                  'n': NumberFormat.decimalPattern(
                                    c.locale.toString(),
                                  ).format((sum.weekMinutes / 6).round() / 10),
                                },
                              ),
                              label: c.tr(
                                'individual.billable_week',
                                namedArgs: {
                                  'amount': naira(c, sum.billableValue),
                                },
                              ),
                              onTap: () => WorkspaceSection.time.open(c),
                            ),
                            IndividualKpi(
                              icon: TmsIcons.file,
                              color: null,
                              value: '${sum.openProposals}',
                              label: c.tr('individual.open_proposals'),
                              onTap: () => WorkspaceSection.proposals.open(c),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (sum.watch case final gig?) ...[
                      heading(
                        c.tr('individual.gig_to_watch'),
                        link: c.tr('individual.all_gigs'),
                        go: () => WorkspaceSection.gigs.open(c),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: IndividualGigWatch(
                          gig: gig,
                          onTap: () => WorkspaceSection.gigs.open(c),
                        ),
                      ),
                    ],
                    heading(
                      c.tr('individual.coming_up'),
                      count: sum.upcoming.length,
                      link: c.tr('individual.view_all'),
                      go: () => WorkspaceSection.tasks.open(c),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: sum.upcoming.isEmpty
                          ? KitCard(
                              child: Text(
                                c.tr('individual.nothing_due'),
                                style: TextStyle(color: c.muted),
                              ),
                            )
                          : KitList(
                              children: [
                                for (final t in sum.upcoming.take(5))
                                  IndividualTaskRow(
                                    key: ValueKey(t.id),
                                    task: t,
                                    onTap: () => WorkspaceSection.tasks.open(
                                      c,
                                      recordId: t.id,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                  if (demo) ...[
                    heading(
                      c.tr('individual.rhythm'),
                      link: c.tr('individual.performance'),
                      go: () => TmsRoute.performance.open(c),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: IndividualRhythm(),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: GestureDetector(
                      onTap: () => TmsRoute.teams.open(c),
                      child: KitCard(
                        color: c.dark ? const Color(0xff2a2846) : null,
                        child: Row(
                          spacing: 12,
                          children: [
                            const KitTile(TmsIcons.people),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.tr('individual.invite_title'),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    c.tr('individual.invite_body'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: c.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
