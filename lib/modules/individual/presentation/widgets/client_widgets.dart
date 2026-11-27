import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../router/tms_routes.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/kit_controls.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../../workspace/presentation/widgets/workspace_ui.dart';
import '../../application/clients_controller.dart';

/// Status pill colour for a client or proposal stage.
Color stageColor(BuildContext c, String stage) => switch (stage) {
  'active' || 'accepted' => KitColor.done,
  'lead' => KitColor.submitted,
  'invited' || 'sent' => KitColor.progress,
  _ => c.muted,
};

(String, Color) clientFace(WorkspaceRecord client) {
  final avatar = int.tryParse(client.fields['avatar'] ?? '');
  final (initials, color) = kitPerson(client.title);
  return (initials, avatar == null ? color : KitColor.avatar(avatar));
}

/// `.cl` row: avatar, name, what they hired you for, stage.
class ClientRow extends StatelessWidget {
  const ClientRow({super.key, required this.client, required this.onTap});
  final WorkspaceRecord client;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final (initials, color) = clientFace(client);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 70),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            spacing: 12,
            children: [
              DesignAvatar(initials, size: 36, color: color),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (client.notes.isNotEmpty)
                      Text(
                        client.notes,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                  ],
                ),
              ),
              KitStatus(
                c.tr('individual.stages.${client.stage}'),
                stageColor(c, client.stage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "What a client sees" card.
class ClientSeesCard extends StatelessWidget {
  const ClientSeesCard({super.key});
  @override
  Widget build(BuildContext c) => KitCard(
    color: c.dark ? const Color(0xff2a2846) : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          c.tr('individual.client_sees'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final k in [
              'progress',
              'files',
              'invoices',
              'timeline',
              'comments',
            ])
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: c.raised,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  c.tr('individual.sees.$k'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          c.tr('individual.sees_note'),
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
      ],
    ),
  );
}

/// A proposal card with Open document and the next step.
class ProposalCard extends StatelessWidget {
  const ProposalCard({
    super.key,
    required this.proposal,
    required this.onOpen,
    required this.onStage,
  });
  final WorkspaceRecord proposal;
  final VoidCallback onOpen;
  final ValueChanged<String> onStage;
  @override
  Widget build(BuildContext c) {
    final stage = proposal.stage;
    final date = proposal.date;
    final day = date == null
        ? ''
        : DateFormat.MMMEd(c.locale.toString()).format(date);
    final meta = stage == 'accepted'
        ? c.tr('individual.accepted_on', namedArgs: {'date': day})
        : [
            if ((proposal.fields['meta'] ?? '').isNotEmpty)
              proposal.fields['meta']!,
            if (day.isNotEmpty)
              c.tr('individual.due_on', namedArgs: {'date': day}),
          ].join(' · ');
    return KitCard(
      child: Column(
        children: [
          Row(
            spacing: 10,
            children: [
              const KitTile(TmsIcons.file, size: 40),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                  ],
                ),
              ),
              KitStatus(c.tr('individual.stages.$stage'), stageColor(c, stage)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: KitMiniButton(
                  c.tr('individual.open_document'),
                  onPressed: onOpen,
                ),
              ),
              if (stage == 'todo')
                Expanded(
                  child: KitMiniButton(
                    c.tr('individual.send_client'),
                    primary: true,
                    onPressed: () => onStage('sent'),
                  ),
                ),
              if (stage == 'sent')
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextButton(
                      onPressed: () => onStage('accepted'),
                      style: TextButton.styleFrom(
                        backgroundColor: KitColor.done,
                        foregroundColor: const Color(0xff0f2418),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        textStyle: Theme.of(c).textTheme.labelLarge?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(c.tr('individual.mark_accepted')),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Client sheet: stage picker, then Invoices or Message.
Future<void> showClientSheet(
  BuildContext context, {
  required WorkspaceRecord client,
  required ValueChanged<String> onStage,
}) => designSheet<void>(
  context,
  title: '',
  builder: (sheet) {
    var stage = client.stage;
    final (initials, color) = clientFace(client);
    return StatefulBuilder(
      builder: (sheet, set) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 12,
            children: [
              DesignAvatar(initials, size: 52, color: color),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (client.notes.isNotEmpty)
                      Text(
                        client.notes,
                        style: TextStyle(fontSize: 13.5, color: sheet.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            sheet.tr('individual.stage'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: sheet.muted,
            ),
          ),
          const SizedBox(height: 8),
          KitSegment<String>(
            values: clientStages,
            selected: stage,
            label: (s) => sheet.tr('individual.stages.$s'),
            onChanged: (s) {
              set(() => stage = s);
              onStage(s);
            },
          ),
          const SizedBox(height: 16),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: DesignButton(
                  sheet.tr('workspaces.sections.invoices.title'),
                  secondary: true,
                  onPressed: () {
                    Navigator.pop(sheet);
                    WorkspaceSection.invoices.open(context);
                  },
                ),
              ),
              Expanded(
                child: DesignButton(
                  sheet.tr('individual.message'),
                  color: DesignColor.purple,
                  onPressed: () {
                    Navigator.pop(sheet);
                    TmsRoute.conversation.open(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  },
);
