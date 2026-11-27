import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/application/local_workspaces.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../workspace/presentation/widgets/workspace_ui.dart';
import '../../../bills/presentation/widgets/bills_widgets.dart' show naira;

part 'family_home_errands.dart';

class FamilyRecordRow extends ConsumerWidget {
  const FamilyRecordRow({
    super.key,
    required this.record,
    required this.workspace,
  });
  final WorkspaceRecord record;
  final LocalWorkspace workspace;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = record.section == WorkspaceSection.bills;
    final school = record.id.endsWith('fractions');
    final color = bill
        ? DesignColor.red
        : school
        ? DesignColor.blue
        : DesignColor.amber;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.outline)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _tile(
            school
                ? TmsIcons.school
                : bill
                ? TmsIcons.receipt
                : TmsIcons.history,
            color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  record.notes,
                  style: TextStyle(fontSize: 11, color: context.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _action(
            context,
            context.tr(
              school
                  ? (record.status == WorkspaceStatus.done
                        ? 'family_reference.checked'
                        : 'family_reference.check')
                  : bill
                  ? 'family_home.pay'
                  : 'family_home.view',
            ),
            () => school
                ? saveWorkspaceChange(
                    context,
                    () => ref
                        .read(localWorkspacesProvider.notifier)
                        .updateRecord(
                          workspace.id,
                          record.id,
                          (r) => r.copyWith(status: WorkspaceStatus.done),
                        ),
                  )
                : record.section.open(context),
            green: school,
          ),
        ],
      ),
    );
  }
}

Widget _tile(IconData icon, Color color) => Container(
  width: 38,
  height: 38,
  decoration: BoxDecoration(
    color: color.withValues(alpha: .12),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: color.withValues(alpha: .25)),
  ),
  child: Icon(icon, size: 19, color: color),
);
Widget _action(
  BuildContext c,
  String label,
  VoidCallback onTap, {
  bool green = false,
}) => SizedBox(
  height: 36,
  child: OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      backgroundColor: green ? DesignColor.green : c.raised,
      foregroundColor: green ? DesignColor.ink : c.foreground,
      side: BorderSide(color: green ? DesignColor.green : c.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  ),
);

class FamilyShoppingRow extends StatelessWidget {
  const FamilyShoppingRow({super.key, required this.workspace});
  final LocalWorkspace workspace;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        _tile(TmsIcons.shoppingCart, DesignColor.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.tr('family_reference.shopping'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                workspace
                    .items(WorkspaceSection.shopping)
                    .where((r) => r.status != WorkspaceStatus.done)
                    .map((r) => r.title)
                    .join(', '),
                style: TextStyle(color: c.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        _action(
          c,
          c.tr('family_reference.open'),
          () => WorkspaceSection.shopping.open(c),
        ),
      ],
    ),
  );
}

class FamilyRewardPanel extends StatelessWidget {
  const FamilyRewardPanel({super.key, required this.workspace});
  final LocalWorkspace workspace;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xff77501b), Color(0xffbd861f), Color(0xffebca7c)],
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const DesignAvatar('TI', size: 46, color: DesignColor.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.tr('family_home.star_house'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    c.tr(
                      'family_home.person_points',
                      namedArgs: {
                        'name': 'Tobi',
                        'points': '${workspace.availablePoints('Tobi')}',
                      },
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(TmsIcons.star, color: Colors.white, size: 29),
          ],
        ),
        for (final r in workspace.items(WorkspaceSection.rewards))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: () => WorkspaceSection.rewards.open(c),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: r.points <= workspace.availablePoints('Tobi')
                      ? Colors.white.withValues(alpha: .19)
                      : const Color(0x30402000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${r.points <= 140 ? '✓ ' : ''}${r.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${r.points} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
