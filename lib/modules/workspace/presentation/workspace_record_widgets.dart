import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/media_service.dart';

import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/design_tokens.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import '../domain/workspace_fields.dart';
import 'workspace_document.dart';
import 'workspace_activity.dart';
import 'workspace_event_invitation.dart';
import 'workspace_invoice.dart';
import 'workspace_ui.dart';
import '../../../shared/design/tms_icons.dart';

part 'workspace_record_summaries.dart';
part 'workspace_payment_summary.dart';

enum WorkspaceRecordAction {
  edit,
  remove,
  pay,
  complete,
  returnForChanges,
  flag,
  allowVisitor,
  waitVisitor,
  startProgramme,
  redeem,
}

class WorkspaceRecordDetails extends StatelessWidget {
  const WorkspaceRecordDetails({
    super.key,
    required this.record,
    required this.onAction,
    required this.onTodo,
    required this.workspaceId,
  });

  final WorkspaceRecord record;
  final String workspaceId;
  final ValueChanged<WorkspaceRecordAction> onAction;
  final ValueChanged<String> onTodo;

  @override
  Widget build(BuildContext context) {
    final section = record.section;
    final view = section.view;
    final completion = switch (record.status) {
      WorkspaceStatus.done => 'workspaces.reopen',
      WorkspaceStatus.submitted => 'common.approve',
      _ when section == WorkspaceSection.shopping => 'workspaces.mark_bought',
      _ when section == WorkspaceSection.prayers => 'workspaces.mark_answered',
      _ when record.requiresReview => 'workspaces.submit_review',
      _ => 'workspaces.mark_done',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 9,
      children: [
        if (workspaceRecordSubtitle(context, record) case final subtitle?)
          DesignLabel(subtitle),
        if (record.notes.isNotEmpty) Text(record.notes),
        if (record.fields['workPhoto'] case final String path
            when section == WorkspaceSection.school)
          FutureBuilder(
            future: MediaService.readHomeworkImage(path),
            builder: (context, snapshot) => snapshot.data == null
                ? const SizedBox.shrink()
                : Image.memory(
                    snapshot.data!,
                    height: 170,
                    fit: BoxFit.contain,
                    semanticLabel: context.tr('family.photo'),
                  ),
          ),
        if (section == WorkspaceSection.guests ||
            section == WorkspaceSection.vendors)
          DesignButton(
            context.tr(
              section == WorkspaceSection.guests
                  ? 'workspaces.guest_page'
                  : 'workspaces.vendor_brief',
            ),
            icon: TmsIcons.visibility,
            secondary: true,
            onPressed: () => designSheet<void>(
              context,
              title: record.title,
              builder: (_) => WorkspaceEventInvitation(
                workspaceId: workspaceId,
                recordId: record.id,
              ),
            ),
          ),
        if (section == WorkspaceSection.invoices) ...[
          for (final line in record.invoiceLines)
            DesignTile(
              title: line.description,
              subtitle: invoiceLineTotal(context, line),
            ),
          DesignLabel(
            context.tr(
              'workspaces.invoice_total',
              namedArgs: {'amount': workspaceAmount(context, record.amount)},
            ),
          ),
        ],
        if (section == WorkspaceSection.invoices ||
            section == WorkspaceSection.proposals)
          DesignButton(
            context.tr('workspaces.doc.preview'),
            icon: TmsIcons.visibility,
            secondary: true,
            onPressed: () => designSheet<void>(
              context,
              title: context.tr('workspaces.doc.preview'),
              builder: (_) => WorkspaceDocumentPreview(record: record),
            ),
          ),
        for (final f in section.detailFields)
          if ((record.fields[f.name] ?? '').isNotEmpty)
            DesignTile(
              title: context.tr('workspaces.fields.${f.name}'),
              subtitle: record.fields[f.name],
            ),
        if (record.todos.isNotEmpty) ...[
          DesignTitle(context.tr('workspaces.todos')),
          for (final e in record.todos.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.key),
              value: e.value,
              onChanged: (_) => onTodo(e.key),
            ),
        ],
        if (section == WorkspaceSection.visitors)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DesignButton(
                context.tr('workspaces.allow_visitor'),
                icon: TmsIcons.check,
                onPressed: record.status == WorkspaceStatus.confirmed
                    ? null
                    : () => onAction(WorkspaceRecordAction.allowVisitor),
              ),
              DesignButton(
                context.tr('workspaces.wait_visitor'),
                secondary: true,
                onPressed: record.status == WorkspaceStatus.declined
                    ? null
                    : () => onAction(WorkspaceRecordAction.waitVisitor),
              ),
            ],
          ),
        if (section == WorkspaceSection.rewards)
          DesignButton(
            context.tr('workspaces.redeem'),
            icon: TmsIcons.trophy,
            onPressed: () => onAction(WorkspaceRecordAction.redeem),
          ),
        if (section == WorkspaceSection.programme)
          DesignButton(
            context.tr(
              record.status == WorkspaceStatus.inProgress
                  ? 'workspaces.mark_done'
                  : 'workspaces.start_item',
            ),
            onPressed: () => onAction(
              record.status == WorkspaceStatus.inProgress
                  ? WorkspaceRecordAction.complete
                  : WorkspaceRecordAction.startProgramme,
            ),
          ),
        if (section == WorkspaceSection.errands &&
            record.fields.containsKey('issued')) ...[
          DesignLabel(
            context.tr(
              'workspaces.errand_money',
              namedArgs: {
                for (final k in ['issued', 'spent'])
                  k: workspaceAmount(
                    context,
                    parseWorkspaceAmount(record.fields[k] ?? '0') ?? 0,
                  ),
                'change': workspaceAmount(
                  context,
                  (parseWorkspaceAmount(record.fields['issued']!) ?? 0) -
                      (parseWorkspaceAmount(record.fields['spent'] ?? '0') ??
                          0),
                ),
              },
            ),
          ),
          DesignButton(
            context.tr('workspaces.change_received'),
            onPressed: record.flagged
                ? null
                : () => onAction(WorkspaceRecordAction.flag),
          ),
        ],
        if (section == WorkspaceSection.guests &&
            record.status == WorkspaceStatus.confirmed)
          DesignButton(
            context.tr(
              record.flagged
                  ? 'workspaces.undo_check_in'
                  : 'workspaces.check_in_guest',
            ),
            onPressed: () => onAction(WorkspaceRecordAction.flag),
          ),
        if (section == WorkspaceSection.passes)
          DesignButton(
            context.tr('workspaces.copy_reference'),
            secondary: true,
            icon: TmsIcons.copy,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: record.fields['accessCode'] ?? record.id),
              );
              if (context.mounted) {
                designToast(context, context.tr('workspaces.reference_copied'));
              }
            },
          ),
        if (record.entries.isNotEmpty ||
            const {
              WorkspaceSection.units,
              WorkspaceSection.giving,
              WorkspaceSection.firstTimers,
            }.contains(section))
          WorkspaceActivity(workspaceId: workspaceId, record: record),
        if (view == WorkspaceView.money &&
            section != WorkspaceSection.giving &&
            record.outstanding > 0)
          DesignButton(
            context.tr('workspaces.record_payment'),
            onPressed: () => onAction(WorkspaceRecordAction.pay),
          ),
        if ((view == WorkspaceView.review || view == WorkspaceView.checklist) &&
            !(section == WorkspaceSection.errands && record.flagged))
          DesignButton(
            context.tr(completion),
            onPressed: () => onAction(WorkspaceRecordAction.complete),
          ),
        if (record.status == WorkspaceStatus.submitted)
          DesignButton(
            context.tr('workspaces.return_for_changes'),
            secondary: true,
            onPressed: () => onAction(WorkspaceRecordAction.returnForChanges),
          ),
        if (section == WorkspaceSection.prayers ||
            section == WorkspaceSection.passes ||
            view == WorkspaceView.notice)
          DesignButton(
            context.tr(switch (section) {
              WorkspaceSection.passes =>
                record.flagged
                    ? 'workspaces.undo_check_in'
                    : 'workspaces.check_in_pass',
              WorkspaceSection.prayers =>
                record.flagged ? 'workspaces.prayed' : 'workspaces.mark_prayed',
              _ =>
                record.flagged
                    ? 'workspaces.mark_unread'
                    : 'workspaces.mark_read',
            }),
            secondary: true,
            onPressed: () => onAction(WorkspaceRecordAction.flag),
          ),
        DesignButton(
          context.tr('workspaces.edit_record'),
          secondary: true,
          icon: TmsIcons.edit,
          onPressed: () => onAction(WorkspaceRecordAction.edit),
        ),
        TextButton(
          onPressed: () => onAction(WorkspaceRecordAction.remove),
          child: Text(context.tr('workspaces.remove')),
        ),
      ],
    );
  }
}
