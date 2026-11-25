import '../domain/event_seating.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/design/design_widgets.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import '../domain/workspace_fields.dart';
import '../domain/workspace_setup.dart';
import 'workspace_document.dart';
import 'workspace_invoice.dart';
import 'workspace_ui.dart';
import '../../../shared/design/tms_icons.dart';

typedef WorkspaceRecordDraft = ({WorkspaceRecord record, Set<String> others});

Future<WorkspaceRecordDraft?> editWorkspaceRecord(
  BuildContext context,
  LocalWorkspace workspace,
  WorkspaceSection section, {
  WorkspaceRecord? record,
}) => designSheet<WorkspaceRecordDraft>(
  context,
  title: record == null
      ? section.addLabel(context)
      : context.tr('workspaces.edit_record'),
  builder: (_) =>
      _RecordForm(workspace: workspace, section: section, record: record),
);

class _RecordForm extends StatefulWidget {
  const _RecordForm({
    required this.workspace,
    required this.section,
    required this.record,
  });

  final LocalWorkspace workspace;

  final WorkspaceSection section;
  final WorkspaceRecord? record;

  @override
  State<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<_RecordForm> {
  late String title, group, notes, amount, duration, options;
  late final TextEditingController person;
  late List<InvoiceLine> invoiceLines;
  late WorkspaceStatus status;
  late Map<String, String> fields;
  late String points;
  late Map<String, bool> todos;
  bool get isReward => section == WorkspaceSection.rewards;
  bool get isProposal => section == WorkspaceSection.proposals;
  bool get isInvoice => section == WorkspaceSection.invoices;
  bool get isErrand => section == WorkspaceSection.errands;
  late bool requiresReview;
  DateTime? date;
  bool attempted = false;
  final assignees = <String>{};

  WorkspaceSection get section => widget.section;
  WorkspaceView get view => section.view;
  bool get isGuest => section == WorkspaceSection.guests;
  bool get isProgramme => section == WorkspaceSection.programme;
  bool get hasDuration => view == WorkspaceView.time || isGuest || isProgramme;
  bool get hasPerson => switch (view) {
    WorkspaceView.review ||
    WorkspaceView.time ||
    WorkspaceView.schedule ||
    WorkspaceView.board => !isReward,
    WorkspaceView.money => section == WorkspaceSection.invoices,
    WorkspaceView.checklist =>
      section.tracksProgress || section == WorkspaceSection.errands,
    _ => false,
  };
  bool get hasDate => switch (view) {
    WorkspaceView.people =>
      section == WorkspaceSection.visitors ||
          section == WorkspaceSection.firstTimers,

    WorkspaceView.notice ||
    WorkspaceView.poll ||
    WorkspaceView.board ||
    WorkspaceView.seating => false,
    _ => true,
  };

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    title = record?.title ?? '';
    fields = {...?record?.fields};
    points = (record?.points ?? 1).toString();
    todos = {...?record?.todos};
    person = TextEditingController(text: record?.person ?? '');
    group =
        record?.group ??
        (section == WorkspaceSection.school
            ? SchoolItemKind.homework.name
            : '');
    notes = record?.notes ?? '';
    amount = record == null || record.invoiceLines.isNotEmpty
        ? ''
        : (record.amount / 100).toStringAsFixed(2);
    if (isInvoice && record != null && record.invoiceLines.isEmpty) {
      amount = fields['baseAmount'] ?? amount;
    }
    invoiceLines = [...?record?.invoiceLines];
    duration =
        record?.duration.toString() ??
        (isGuest
            ? '1'
            : isProgramme
            ? '30'
            : '');
    options = record?.options.join('\n') ?? '';
    status =
        record?.status ??
        (view == WorkspaceView.people
            ? WorkspaceStatus.pending
            : WorkspaceStatus.todo);
    if (section.tracksPeopleStatus &&
        !section.peopleStatuses.contains(status)) {
      status = WorkspaceStatus.pending;
    }
    requiresReview =
        record?.requiresReview ?? (section == WorkspaceSection.school);
    date =
        record?.date ??
        (view == WorkspaceView.time && record == null
            ? DateUtils.dateOnly(DateTime.now())
            : null);
  }

  @override
  void dispose() {
    person.dispose();
    super.dispose();
  }

  int? get parsedAmount {
    final subtotal = invoiceLines.isEmpty
        ? parseWorkspaceAmount(amount)
        : invoiceLines.fold<int>(0, (total, line) => total + line.total);
    if (!isInvoice || subtotal == null) return subtotal;
    final discount = (fields['discount'] ?? '').isEmpty
        ? 0
        : parseWorkspaceAmount(fields['discount']!);
    final tax = (fields['tax'] ?? '').isEmpty
        ? 0
        : parseWorkspaceAmount(fields['tax']!);
    if (discount == null || discount > subtotal || tax == null || tax > 10000) {
      return null;
    }
    return subtotal - discount + ((subtotal - discount) * tax + 5000) ~/ 10000;
  }

  int? get parsedDuration => int.tryParse(duration.trim());
  List<String> get pollOptions => options
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  String? get error {
    if (title.trim().isEmpty) return 'workspaces.required_title';
    if ((view == WorkspaceView.review || isReward) &&
        ((int.tryParse(points) ?? 0) < 1 ||
            (int.tryParse(points) ?? 0) > 10000)) {
      return 'workspaces.invalid_points';
    }
    if (isProposal && amount.trim().isNotEmpty && parsedAmount == null) {
      return 'workspaces.invalid_total';
    }
    if (isErrand) {
      final issued = parseWorkspaceAmount(fields['issued'] ?? '0'),
          spent = parseWorkspaceAmount(fields['spent'] ?? '0');
      if (issued == null || spent == null || spent > issued) {
        return 'workspaces.invalid_errand';
      }
    }
    if (section.detailFields.any(
      (f) =>
          f.numeric &&
          (fields[f.name] ?? '').isNotEmpty &&
          (int.tryParse(fields[f.name]!) ?? -1) < 0,
    )) {
      return 'workspaces.invalid_count';
    }
    if (view == WorkspaceView.money &&
        ((parsedAmount ?? 0) <= 0 ||
            parsedAmount! > 999999999999 ||
            (section != WorkspaceSection.giving &&
                parsedAmount! < (widget.record?.paid ?? 0)))) {
      return 'workspaces.invalid_total';
    }
    if (view == WorkspaceView.schedule && date == null) {
      return 'workspaces.required_date';
    }
    if ((view == WorkspaceView.time || isProgramme) &&
        ((parsedDuration ?? 0) < 1 || parsedDuration! > 1440)) {
      return 'workspaces.invalid_minutes';
    }
    if (isGuest && ((parsedDuration ?? 0) < 1 || parsedDuration! > 100)) {
      return 'workspaces.invalid_party_size';
    }
    if (isGuest &&
        (status == WorkspaceStatus.confirmed ||
            status == WorkspaceStatus.maybe) &&
        !widget.workspace.canSeat(
          group.trim(),
          WorkspaceRecord(
            id: widget.record?.id ?? '',
            section: section,
            title: title,
            duration: parsedDuration!,
          ),
        )) {
      return 'workspaces.table_full';
    }
    if (view == WorkspaceView.poll &&
        (pollOptions.length < 2 ||
            pollOptions.length > 8 ||
            pollOptions.map((option) => option.toLowerCase()).toSet().length !=
                pollOptions.length)) {
      return 'workspaces.invalid_options';
    }
    return null;
  }

  void save() {
    if (error != null) {
      setState(() => attempted = true);
      return;
    }
    final previous = widget.record;
    if (isInvoice && invoiceLines.isEmpty) fields['baseAmount'] = amount;
    final assignee = person.text.trim().isEmpty
        ? assignees.firstOrNull ?? ''
        : person.text.trim();
    final record = WorkspaceRecord(
      id: previous?.id ?? '',
      section: section,
      title: title.trim(),
      person: assignee,
      group: group.trim(),
      notes: notes.trim(),
      date: date,
      amount: view == WorkspaceView.money || isProposal ? parsedAmount ?? 0 : 0,
      fields: {
        for (final e in fields.entries)
          if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
      },
      points: int.tryParse(points) ?? 1,
      todos: todos,
      paid: previous?.paid ?? 0,
      duration: hasDuration ? parsedDuration! : 0,
      status: status,
      requiresReview: requiresReview,
      flagged: isGuest && status != WorkspaceStatus.confirmed
          ? false
          : view == WorkspaceView.time
          ? billable
          : previous?.flagged ?? false,
      options: view == WorkspaceView.poll ? pollOptions : const [],
      vote: previous?.vote,
      invoiceLines: invoiceLines,
    );
    Navigator.pop(context, (record: record, others: assignees));
  }

  late bool billable = widget.record?.flagged ?? true;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final titleKey = switch (section) {
      WorkspaceSection.invoices => 'workspaces.invoice_number',
      WorkspaceSection.visitors ||
      WorkspaceSection.guests ||
      WorkspaceSection.clients ||
      WorkspaceSection.congregation ||
      WorkspaceSection.household ||
      WorkspaceSection.directory ||
      WorkspaceSection.firstTimers ||
      WorkspaceSection.attendance => 'workspaces.name',
      _ => 'common.title',
    };
    final directorySection = switch (widget.workspace.kind) {
      WorkspaceKind.family => WorkspaceSection.household,
      WorkspaceKind.individual => WorkspaceSection.clients,
      _ => null,
    };
    final contacts = directorySection == null
        ? const <String>{}
        : widget.workspace
              .items(directorySection)
              .map((item) => item.title)
              .toSet();
    final peopleStatus = section.tracksPeopleStatus;
    final statusOptions = peopleStatus
        ? section.peopleStatuses
        : const [
            WorkspaceStatus.todo,
            WorkspaceStatus.inProgress,
            WorkspaceStatus.done,
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 13,
      children: [
        DesignField(
          label: tr(titleKey),
          initialValue: title,
          onChanged: (value) => title = value,
        ),
        if (hasPerson)
          DesignField(
            label: tr(
              section == WorkspaceSection.invoices ||
                      isProposal ||
                      section == WorkspaceSection.gigs ||
                      view == WorkspaceView.time
                  ? 'workspaces.client'
                  : view == WorkspaceView.board ||
                        view == WorkspaceView.schedule
                  ? 'workspaces.lead'
                  : 'workspaces.assigned_to',
            ),
            controller: person,
          ),
        if (hasPerson && contacts.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final contact in contacts)
                DesignPill(
                  contact,
                  selected:
                      assignees.contains(contact) || person.text == contact,
                  onTap: () {
                    if (view == WorkspaceView.review && widget.record == null) {
                      setState(() {
                        if (!assignees.remove(contact)) assignees.add(contact);
                      });
                    } else {
                      setState(() => person.text = contact);
                    }
                  },
                ),
            ],
          ),
        if (view == WorkspaceView.review || isReward)
          DesignField(
            label: tr(
              isReward ? 'workspaces.reward_cost' : 'workspaces.points_value',
            ),
            initialValue: points,
            keyboardType: TextInputType.number,
            onChanged: (s) => points = s.trim(),
          ),
        if (section == WorkspaceSection.household)
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: fields['householdRole'],
            decoration: InputDecoration(
              labelText: tr('workspaces.setup.member_role'),
            ),
            items: [
              for (final r in HouseholdRole.values)
                DropdownMenuItem(
                  value: r.name,
                  child: Text(tr('workspaces.roles.${r.name}')),
                ),
            ],
            onChanged: (value) {
              if (value != null) fields['householdRole'] = value;
            },
          ),
        if (section == WorkspaceSection.school)
          DropdownButtonFormField<SchoolItemKind>(
            icon: const Icon(TmsIcons.chevronDown),
            initialValue:
                SchoolItemKind.values
                    .where((t) => t.name == group)
                    .firstOrNull ??
                SchoolItemKind.homework,
            decoration: InputDecoration(
              labelText: tr('workspaces.school_type'),
            ),
            items: [
              for (final type in SchoolItemKind.values)
                DropdownMenuItem(
                  value: type,
                  child: Text(tr('workspaces.school_types.${type.name}')),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => group = value.name);
            },
          ),
        if ((view == WorkspaceView.people &&
                section != WorkspaceSection.visitors) ||
            view == WorkspaceView.schedule)
          DesignField(
            label: tr(
              isGuest
                  ? 'workspaces.table'
                  : view == WorkspaceView.schedule
                  ? 'workspaces.location'
                  : 'workspaces.role_or_group',
            ),
            initialValue: group,
            onChanged: (value) => group = value,
          ),
        if (peopleStatus || section.tracksProgress)
          DropdownButtonFormField<WorkspaceStatus>(
            icon: const Icon(TmsIcons.chevronDown),
            initialValue: statusOptions.contains(status)
                ? status
                : statusOptions.first,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: tr('workspaces.record_status'),
            ),
            items: [
              for (final value in statusOptions)
                DropdownMenuItem(
                  value: value,
                  child: Text(section.statusLabel(context, value)),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => status = value);
            },
          ),
        if (section == WorkspaceSection.invoices)
          InvoiceLinesEditor(
            lines: invoiceLines,
            onChanged: (value) => setState(() => invoiceLines = value),
          ),
        if ((view == WorkspaceView.money || isProposal) && invoiceLines.isEmpty)
          DesignField(
            label: tr(
              isProposal
                  ? 'workspaces.fields.proposalValue'
                  : 'workspaces.amount_ngn',
            ),
            initialValue: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => amount = value,
          ),
        if (isInvoice || isProposal)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 10),
            initiallyExpanded: isProposal,
            title: Text(
              tr(
                isInvoice ? 'workspaces.doc.studio' : 'workspaces.doc.proposal',
              ),
            ),
            children: [
              DocumentDesignFields(
                invoice: isInvoice,
                values: fields,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
        if (isErrand && widget.record?.flagged != true)
          for (final k in [WorkspaceField.issued, WorkspaceField.spent])
            DesignField(
              label: tr('workspaces.fields.${k.name}'),
              initialValue: fields[k.name],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (s) {
                if (s.trim().isEmpty) {
                  fields.remove(k.name);
                } else {
                  fields[k.name] = s.trim();
                }
              },
            ),
        if (section.detailFields.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(tr('workspaces.more_details')),
            children: [
              for (final f in section.detailFields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DesignField(
                    label: tr('workspaces.fields.${f.name}'),
                    initialValue: fields[f.name],
                    lines: f == WorkspaceField.members ? 3 : 1,
                    keyboardType: f.numeric
                        ? TextInputType.number
                        : f == WorkspaceField.email
                        ? TextInputType.emailAddress
                        : f == WorkspaceField.phone
                        ? TextInputType.phone
                        : null,
                    onChanged: (s) => fields[f.name] = s.trim(),
                  ),
                ),
            ],
          ),
        if (view == WorkspaceView.board && !isReward)
          DesignField(
            label: tr('workspaces.todos_input'),
            initialValue: todos.keys.join('\n'),
            lines: 3,
            onChanged: (s) => todos = {
              for (final t
                  in s
                      .split('\n')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty))
                t: widget.record?.todos[t] ?? false,
            },
          ),
        if (isProgramme)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('workspaces.public_programme')),
            value: fields['visibility'] != 'team',
            onChanged: (v) =>
                setState(() => fields['visibility'] = v ? 'guests' : 'team'),
          ),
        if (hasDuration)
          DesignField(
            label: tr(
              isGuest
                  ? 'workspaces.party_size'
                  : isProgramme
                  ? 'workspaces.duration_minutes'
                  : 'workspaces.minutes_worked',
            ),
            initialValue: duration,
            keyboardType: TextInputType.number,
            onChanged: (value) => duration = value,
          ),
        if (hasDate)
          DesignButton(
            date == null
                ? tr('workspaces.pick_date')
                : MaterialLocalizations.of(context).formatMediumDate(date!),
            secondary: true,
            icon: TmsIcons.calendar,
            onPressed: () async {
              final selected = await pickWorkspaceDate(context, date);
              if (mounted && selected != null) {
                setState(
                  () => date = selected.copyWith(
                    hour: date?.hour ?? 9,
                    minute: date?.minute ?? 0,
                  ),
                );
              }
            },
          ),
        if (view == WorkspaceView.schedule && date != null)
          DesignButton(
            TimeOfDay.fromDateTime(date!).format(context),
            icon: TmsIcons.clock,
            secondary: true,
            onPressed: () async {
              final time = await showTimePicker(
                switchToInputEntryModeIcon: const Icon(TmsIcons.keyboard),
                switchToTimerEntryModeIcon: const Icon(TmsIcons.clock),
                context: context,
                initialTime: TimeOfDay.fromDateTime(date!),
              );
              if (mounted && time != null) {
                setState(
                  () => date = date!.copyWith(
                    hour: time.hour,
                    minute: time.minute,
                  ),
                );
              }
            },
          ),
        if (view == WorkspaceView.review &&
            status != WorkspaceStatus.submitted &&
            status != WorkspaceStatus.returned &&
            status != WorkspaceStatus.done)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('workspaces.require_review')),
            value: requiresReview,
            onChanged: (value) => setState(() => requiresReview = value),
          ),
        if (view == WorkspaceView.time)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('workspaces.billable')),
            value: billable,
            onChanged: (value) => setState(() => billable = value),
          ),
        if (view == WorkspaceView.poll && widget.record?.vote == null)
          DesignField(
            label: tr('workspaces.options_per_line'),
            initialValue: options,
            lines: 4,
            onChanged: (value) => options = value,
          ),
        DesignField(
          label: tr(
            section == WorkspaceSection.minutes ||
                    section == WorkspaceSection.notices
                ? 'workspaces.message'
                : 'common.notes',
          ),
          initialValue: notes,
          lines: 3,
          onChanged: (value) => notes = value,
        ),
        if (attempted && error != null)
          Text(
            tr(error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        DesignButton(tr('workspaces.save'), onPressed: save),
      ],
    );
  }
}
