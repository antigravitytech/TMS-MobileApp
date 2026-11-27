import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../../workspace/presentation/widgets/workspace_ui.dart';

/// Homework card: subject line, title, then Done + photo or its status.
class KidHomeworkCard extends StatelessWidget {
  const KidHomeworkCard({
    super.key,
    required this.work,
    required this.busy,
    required this.onDone,
  });
  final WorkspaceRecord work;
  final bool busy;
  final VoidCallback onDone;
  @override
  Widget build(BuildContext context) => KitCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 12,
          children: [
            const KitTile(TmsIcons.book, color: KitColor.progress),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (work.notes.isNotEmpty)
                    Text(
                      work.notes,
                      style: TextStyle(fontSize: 12, color: context.muted),
                    ),
                  Text(
                    work.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (work.status == WorkspaceStatus.submitted)
          KitPop(
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                KitStatus(context.tr('family.waiting'), KitColor.submitted),
                if (work.points > 0)
                  Text(
                    context.tr(
                      'family.waiting_points',
                      namedArgs: {'n': '${work.points}'},
                    ),
                    style: TextStyle(fontSize: 12, color: context.muted),
                  ),
              ],
            ),
          )
        else if (work.status == WorkspaceStatus.done)
          Align(
            alignment: Alignment.centerLeft,
            child: KitStatus(
              WorkspaceSection.school.statusLabel(context, work.status),
              KitColor.done,
            ),
          )
        else
          DesignButton(
            context.tr(
              work.fields['photo'] == 'false'
                  ? 'family.finish'
                  : 'family.photo',
            ),
            icon: TmsIcons.camera,
            onPressed: busy ? null : onDone,
          ),
      ],
    ),
  );
}

/// `.reward` line: ticked when affordable, otherwise the points still needed.
class KidRewardRow extends StatelessWidget {
  const KidRewardRow({super.key, required this.reward, required this.points});
  final WorkspaceRecord reward;
  final int points;
  @override
  Widget build(BuildContext context) {
    final r = reward;
    final can = r.points > 0 && points >= r.points;
    return KitCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: can ? DesignColor.amber.withValues(alpha: .55) : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${can ? '✓ ' : ''}${r.title}',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            context.tr(
              can ? 'family.ask' : 'family.to_go',
              namedArgs: {'n': '${r.points - points}'},
            ),
            style: TextStyle(fontSize: 12, color: context.muted),
          ),
        ],
      ),
    );
  }
}
