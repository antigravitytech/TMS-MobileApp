import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit_controls.dart';
import '../../../shared/kit/kit.dart';
import '../../../shared/kit/kit_visuals.dart';
import '../../workspace/presentation/widgets/workspace_record_form.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../application/clients_controller.dart';
import 'widgets/client_widgets.dart';

/// Clients and Proposals, switched with a segment as in the prototype.
class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({
    super.key,
    required this.workspace,
    this.proposals = false,
  });
  final LocalWorkspace workspace;
  final bool proposals;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final args = (workspace.id, proposals);
    final state = ref.watch(clientsControllerProvider(args));
    final actions = ref.read(clientsControllerProvider(args).notifier);
    final section = state.proposals
        ? WorkspaceSection.proposals
        : WorkspaceSection.clients;
    final records = ref.watch(clientRecordsProvider((workspace.id, section)));
    final stages = state.proposals ? proposalStages : clientStages;
    final visible = records
        .where((r) => state.filter == 'all' || r.stage == state.filter)
        .toList();

    void failed(bool ok) {
      if (!ok && c.mounted) designToast(c, c.tr('workspaces.try_again'));
    }

    Future<void> edit([WorkspaceRecord? record]) async {
      final draft = await editWorkspaceRecord(
        c,
        workspace,
        section,
        record: record,
      );
      if (draft == null) return;
      failed(await actions.save(draft.record, draft.others));
    }

    Future<void> stage(WorkspaceRecord r, String s) async {
      final ok = await actions.setStage(r, s);
      failed(ok);
      if (ok && c.mounted && r.section == WorkspaceSection.proposals) {
        designToast(
          c,
          c.tr(
            s == 'sent' ? 'individual.sent_toast' : 'individual.accepted_toast',
            namedArgs: {'name': r.title},
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: const WorkspaceNavigation(
        kind: WorkspaceKind.individual,
        active: TmsRoute.more,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitHeader(
              title: c.tr(
                state.proposals
                    ? 'workspaces.sections.proposals.title'
                    : 'workspaces.sections.clients.title',
              ),
              subtitle: c.tr(
                state.proposals
                    ? 'individual.proposals_sub'
                    : 'individual.clients_sub',
              ),
              back: c.tr('common.back'),
              action: KitIconButton(
                primary: true,
                icon: TmsIcons.add,
                tooltip: section.addLabel(c),
                onPressed: edit,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: KitSegment<bool>(
                values: const [false, true],
                selected: state.proposals,
                label: (p) => c.tr(
                  p
                      ? 'workspaces.sections.proposals.title'
                      : 'workspaces.sections.clients.title',
                ),
                onChanged: actions.tab,
              ),
            ),
            const SizedBox(height: 12),
            KitTabs(
              children: [
                for (final f in ['all', ...stages])
                  KitChip(
                    label: f == 'all'
                        ? c.tr('common.all')
                        : c.tr('individual.stages.$f'),
                    count: f == 'all'
                        ? records.length
                        : records.where((r) => r.stage == f).length,
                    selected: state.filter == f,
                    onTap: () => actions.filter(f),
                  ),
              ],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: DesignMotion.fast,
                child: ListView(
                  key: ValueKey(state.proposals),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                  children: [
                    if (visible.isEmpty)
                      KitCard(
                        child: Text(
                          c.tr('workspaces.sections.${section.name}.empty'),
                          style: TextStyle(color: c.muted),
                        ),
                      )
                    else if (!state.proposals)
                      KitList(
                        children: [
                          for (final client in visible)
                            ClientRow(
                              key: ValueKey(client.id),
                              client: client,
                              onTap: () => showClientSheet(
                                c,
                                client: client,
                                onStage: (s) => stage(client, s),
                              ),
                            ),
                        ],
                      )
                    else
                      for (final (i, p) in visible.indexed)
                        Padding(
                          key: ValueKey(p.id),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DesignEntrance(
                            order: i,
                            child: ProposalCard(
                              proposal: p,
                              onOpen: () => edit(p),
                              onStage: (s) => stage(p, s),
                            ),
                          ),
                        ),
                    if (!state.proposals) ...[
                      const SizedBox(height: 14),
                      const ClientSeesCard(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
