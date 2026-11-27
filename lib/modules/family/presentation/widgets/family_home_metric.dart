import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../workspace/presentation/widgets/workspace_ui.dart';
import '../../../bills/application/bills_controller.dart';
import '../../../bills/presentation/widgets/bills_widgets.dart' show naira;

class FamilyHomeMetric extends StatelessWidget {
  const FamilyHomeMetric({
    super.key,
    required this.index,
    required this.workspace,
  });
  final int index;
  final LocalWorkspace workspace;
  @override
  Widget build(BuildContext context) {
    final color = [
      DesignColor.amber,
      DesignColor.blue,
      DesignColor.red,
      context.lavender,
    ][index];
    final sections = [
      WorkspaceSection.chores,
      WorkspaceSection.school,
      WorkspaceSection.bills,
      WorkspaceSection.plans,
    ];
    return DesignCard(
      onTap: () => sections[index].open(context),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: .25)),
            ),
            child: Icon(
              [
                TmsIcons.shoppingBag,
                TmsIcons.school,
                TmsIcons.receipt,
                TmsIcons.calendar,
              ][index],
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_value()}',
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            index == 2
                ? context.tr(
                    'family_reference.bill',
                    namedArgs: {'amount': naira(context, _dueThisWeek.$2)},
                  )
                : context.tr(
                    [
                      'family_reference.chores',
                      'family_reference.school',
                      '',
                      'workspaces.sections.plans.title',
                    ][index],
                  ),
            style: TextStyle(fontSize: 11, color: context.muted),
          ),
        ],
      ),
    );
  }

  /// Unpaid bills due in the next seven days and what they still owe.
  (int, int) get _dueThisWeek {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 7));
    final due = workspace.items(WorkspaceSection.bills).where((b) {
      final on = b.dueOn;
      return !b.settled &&
          b.amount > 0 &&
          on != null &&
          !on.isBefore(start) &&
          on.isBefore(end);
    });
    return (due.length, due.fold(0, (s, b) => s + b.outstanding));
  }

  int _value() => switch (index) {
    0 =>
      workspace
          .items(WorkspaceSection.chores)
          .where(
            (r) =>
                r.fields['ledger'] != 'true' &&
                r.status != WorkspaceStatus.done,
          )
          .length,
    1 =>
      workspace
          .items(WorkspaceSection.school)
          .where((r) => r.status == WorkspaceStatus.submitted)
          .length,
    2 => _dueThisWeek.$1,
    _ => workspace.items(WorkspaceSection.plans).length,
  };
}
