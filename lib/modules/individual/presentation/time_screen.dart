import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../bills/presentation/widgets/bills_widgets.dart' show naira;
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit.dart';
import '../../../shared/kit/kit_visuals.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../application/time_controller.dart';
import 'widgets/time_widgets.dart';

class TimeScreen extends ConsumerWidget {
  const TimeScreen({super.key, required this.workspace});
  final LocalWorkspace workspace;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final id = workspace.id;
    final sum = ref.watch(timeSummaryProvider(id));
    final actions = ref.read(timeActionsProvider(id));
    final day = DateFormat.E(c.locale.toString());
    String when(DateTime? d) {
      if (d == null) return '';
      final now = DateTime.now();
      final days = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(d.year, d.month, d.day)).inDays;
      return switch (days) {
        0 => c.tr('common.today'),
        1 => c.tr('individual.yesterday'),
        _ => day.format(d),
      };
    }

    Widget heading(String title, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          ?trailing,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: const WorkspaceNavigation(
        kind: WorkspaceKind.individual,
        active: TmsRoute.workspacePlan,
        section: WorkspaceSection.time,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitHeader(
              large: true,
              title: c.tr('workspaces.sections.time.title'),
              subtitle: workspaceName(c, workspace),
            ),
            if (sum != null)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                  children: [
                    DesignEntrance(
                      child: TimeTimerCard(
                        workspaceId: id,
                        clients: sum.clients,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DesignEntrance(
                      order: 1,
                      child: Row(
                        spacing: 8,
                        children: [
                          for (final (value, label, color) in [
                            (
                              timeHours(c, sum.minutes),
                              c.tr('individual.this_week'),
                              null,
                            ),
                            (
                              timeHours(c, sum.billableMinutes),
                              c.tr('individual.billable'),
                              null,
                            ),
                            (
                              naira(c, sum.billableValue),
                              c.tr(
                                'individual.at_rate',
                                namedArgs: {'rate': naira(c, sum.rate)},
                              ),
                              KitColor.done,
                            ),
                          ])
                            Expanded(
                              child: KitCard(
                                radius: 20,
                                padding: const EdgeInsets.all(14),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 52,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 6,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                            fontSize: 22,
                                            height: 1,
                                            fontWeight: FontWeight.w800,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: c.muted,
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
                    heading(c.tr('individual.by_client')),
                    KitCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          for (final (name, minutes) in sum.byClient)
                            TimeClientBar(
                              name: name,
                              minutes: minutes,
                              max: sum.byClient.fold(
                                60,
                                (m, e) => e.$2 > m ? e.$2 : m,
                              ),
                            ),
                        ],
                      ),
                    ),
                    heading(
                      c.tr('individual.logged_heading'),
                      trailing: GestureDetector(
                        onTap: () => WorkspaceSection.invoices.open(c),
                        child: Text(
                          c.tr('individual.bill_it'),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: c.lavender,
                          ),
                        ),
                      ),
                    ),
                    if (sum.entries.isEmpty)
                      KitCard(
                        child: Text(
                          c.tr('workspaces.sections.time.empty'),
                          style: TextStyle(color: c.muted),
                        ),
                      )
                    else
                      KitList(
                        children: [
                          for (final e in sum.entries)
                            _Entry(
                              key: ValueKey(e.id),
                              entry: e,
                              meta: [
                                e.person.isEmpty ? adminClient : e.person,
                                when(e.date),
                              ].where((s) => s.isNotEmpty).join(' · '),
                              onFlip: () async {
                                final ok = await actions.toggleBillable(e);
                                if (!ok && c.mounted) {
                                  designToast(c, c.tr('workspaces.try_again'));
                                }
                              },
                            ),
                        ],
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

/// `.entry`: what was done, for whom, billable toggle and hours.
class _Entry extends StatelessWidget {
  const _Entry({
    super.key,
    required this.entry,
    required this.meta,
    required this.onFlip,
  });
  final WorkspaceRecord entry;
  final String meta;
  final VoidCallback onFlip;
  @override
  Widget build(BuildContext c) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 62),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(meta, style: TextStyle(fontSize: 12, color: c.muted)),
              ],
            ),
          ),
          Semantics(
            button: true,
            toggled: entry.flagged,
            child: GestureDetector(
              onTap: onFlip,
              child: KitPop(
                key: ValueKey(entry.flagged),
                child: KitStatus(
                  c.tr(
                    entry.flagged
                        ? 'individual.billable'
                        : 'individual.not_billable',
                  ),
                  entry.flagged ? KitColor.done : c.muted,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              timeHours(c, entry.duration),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}
