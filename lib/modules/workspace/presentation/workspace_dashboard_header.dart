import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../domain/workspace_kind.dart';
import '../domain/local_workspace.dart';
import 'workspace_ui.dart';

class WorkspaceOverviewRail extends StatelessWidget {
  const WorkspaceOverviewRail({
    super.key,
    required this.workspace,
    this.section,
    this.select,
  });
  final LocalWorkspace workspace;
  final WorkspaceSection? section;
  final ValueChanged<WorkspaceSection>? select;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      spacing: 8,
      children: [
        DesignPill(
          context.tr('dashboard.overview'),
          selected: section == null,
          onTap: () => TmsRoute.home.open(context),
        ),
        for (final s in workspace.kind.sections)
          DesignPill(
            s.label(context),
            selected: section == s,
            onTap: () {
              if (select != null) {
                select!(s);
              } else {
                s.open(context);
              }
            },
          ),
      ],
    ),
  );
}

class WorkspaceCountdown extends StatelessWidget {
  const WorkspaceCountdown({super.key, required this.workspace});
  final LocalWorkspace workspace;
  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final upcoming =
        workspace.records
            .where(
              (r) =>
                  r.date != null &&
                  !DateUtils.dateOnly(r.date!).isBefore(today),
            )
            .toList()
          ..sort((a, b) => a.date!.compareTo(b.date!));
    final event = upcoming.firstOrNull;
    final date = workspace.eventDate ?? event?.date;
    final days = date == null
        ? null
        : DateTime.utc(
            date.year,
            date.month,
            date.day,
          ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    final title = workspace.occasion.isNotEmpty
        ? workspace.occasion
        : event?.title ?? workspaceName(context, workspace);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff262a60), Color(0xff1b1e45), Color(0xff353b80)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 12,
              children: [
                if (days != null && days >= 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NumberFormat.decimalPattern(
                          context.locale.toString(),
                        ).format(days),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2.8,
                        ),
                      ),
                      Text(
                        context.tr('dashboard.days_to_go'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 5,
                    children: [
                      Text(
                        workspace.kind.label(context),
                        style: const TextStyle(
                          color: DesignColor.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        title,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 19,
                        ),
                      ),
                      if (date != null)
                        Text(
                          DateFormat.yMMMEd(
                            context.locale.toString(),
                          ).format(date),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              workspace.kind.description(context),
              style: const TextStyle(color: Color(0xffc9cbe0), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkspaceShortcuts extends StatelessWidget {
  const WorkspaceShortcuts({super.key, required this.workspace});
  final LocalWorkspace workspace;
  @override
  Widget build(BuildContext context) {
    final family = workspace.kind == WorkspaceKind.family;
    final items = family
        ? [
            (
              'dashboard.add_task',
              TmsIcons.add,
              () => TmsRoute.familyTask.open(context),
            ),
            (
              'more.tools.school',
              TmsIcons.school,
              () => WorkspaceSection.school.open(context),
            ),
            (
              'more.tools.family_plans',
              TmsIcons.calendar,
              () => WorkspaceSection.plans.open(context),
            ),
            (
              'more.tools.shopping',
              TmsIcons.shoppingCart,
              () => WorkspaceSection.shopping.open(context),
            ),
          ]
        : [
            (
              'more.tools.gigs',
              TmsIcons.work,
              () => WorkspaceSection.gigs.open(context),
            ),
            (
              'more.tools.time',
              TmsIcons.timer,
              () => WorkspaceSection.time.open(context),
            ),
            (
              'more.tools.invoices',
              TmsIcons.receipt,
              () => WorkspaceSection.invoices.open(context),
            ),
            ('common.chat', TmsIcons.chat, () => TmsRoute.chat.open(context)),
          ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        for (final (i, item) in items.indexed)
          Expanded(
            child: InkWell(
              onTap: item.$3,
              child: Column(
                spacing: 6,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: [
                        DesignColor.purple,
                        DesignColor.blue,
                        DesignColor.teal,
                        DesignColor.amber,
                      ][i].withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      item.$2,
                      color: [
                        DesignColor.purple,
                        DesignColor.blue,
                        DesignColor.teal,
                        DesignColor.amber,
                      ][i],
                    ),
                  ),
                  Text(
                    context.tr(item.$1),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
