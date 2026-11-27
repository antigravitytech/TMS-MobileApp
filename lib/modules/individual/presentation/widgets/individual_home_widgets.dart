import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/individual_home.dart';

/// `.qadd`: a task line with an Add button and the tokens it recognised.
class IndividualQuickAdd extends StatefulWidget {
  const IndividualQuickAdd({
    super.key,
    required this.line,
    required this.onChanged,
    required this.onAdd,
  });
  final String line;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;
  @override
  State<IndividualQuickAdd> createState() => _IndividualQuickAddState();
}

class _IndividualQuickAddState extends State<IndividualQuickAdd> {
  late final _text = TextEditingController(text: widget.line);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(IndividualQuickAdd old) {
    super.didUpdateWidget(old);
    if (widget.line != _text.text) _text.text = widget.line;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final draft = parseTask(widget.line);
    final tokens = [
      if (draft.due != null)
        c.tr('individual.token_due', namedArgs: {'day': _dayLabel(c, draft)}),
      if (draft.priority != null)
        c.tr(
          'individual.token_priority',
          namedArgs: {'level': c.tr('individual.priority.${draft.priority}')},
        ),
      if (draft.project != null)
        c.tr('individual.token_project', namedArgs: {'name': draft.project!}),
      if (draft.person != null)
        c.tr('individual.token_person', namedArgs: {'name': draft.person!}),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _focus.hasFocus ? DesignColor.purple : c.outline,
            ),
            boxShadow: _focus.hasFocus
                ? const [BoxShadow(color: Color(0x2e9184d9), spreadRadius: 4)]
                : null,
          ),
          child: Row(
            spacing: 8,
            children: [
              Icon(TmsIcons.add, size: 20, color: c.muted),
              Expanded(
                child: TextField(
                  controller: _text,
                  focusNode: _focus,
                  onChanged: widget.onChanged,
                  onSubmitted: (_) => widget.onAdd(),
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: c.tr('individual.quick_hint'),
                    hintStyle: TextStyle(color: c.muted),
                  ),
                ),
              ),
              KitMiniButton(
                c.tr('individual.add'),
                primary: true,
                onPressed: widget.onAdd,
              ),
            ],
          ),
        ),
        if (tokens.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in tokens)
                  KitPop(
                    key: ValueKey(t),
                    child: Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0x2e9184d9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.lavender,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _dayLabel(BuildContext c, TaskDraft d) => switch (d.due) {
    0 => c.tr('common.today'),
    8 => c.tr('individual.tomorrow'),
    final day? => DateFormat.E(
      c.locale.toString(),
    ).format(DateTime(2024, 1, day)),
    null => '',
  };
}

/// `.kpi` card: tile, big number and a caption.
class IndividualKpi extends StatelessWidget {
  const IndividualKpi({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.onTap,
    this.suffix,
  });
  final IconData icon;
  final Color? color;
  final String value, label;
  final String? suffix;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => GestureDetector(
    onTap: onTap,
    child: KitCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            KitTile(icon, color: color),
            Text.rich(
              TextSpan(
                text: value,
                children: [
                  if (suffix != null)
                    TextSpan(
                      text: suffix,
                      style: TextStyle(fontSize: 16, color: c.muted),
                    ),
                ],
              ),
              style: const TextStyle(
                fontSize: 26,
                height: 1,
                letterSpacing: -.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: c.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// `.li` row with a month/day block, title, meta and a status pill.
class IndividualTaskRow extends StatelessWidget {
  const IndividualTaskRow({super.key, required this.task, required this.onTap});
  final WorkspaceRecord task;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final locale = c.locale.toString();
    final date = task.date;
    final f = task.fields;
    final meta = [
      (f['project'] ?? '').isEmpty
          ? c.tr('individual.standalone')
          : f['project']!,
      if ((f['key'] ?? '').isNotEmpty) f['key']!,
      if ((f['priority'] ?? '').isNotEmpty)
        c.tr('individual.priority.${f['priority']}'),
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          spacing: 12,
          children: [
            SizedBox(
              width: 46,
              child: Column(
                children: [
                  Text(
                    date == null
                        ? ''
                        : DateFormat.MMM(locale).format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                      color: c.lavender,
                    ),
                  ),
                  Text(
                    date == null ? '' : '${date.day}',
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(meta, style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
            ),
            KitStatus(c.tr('individual.not_started'), c.muted),
          ],
        ),
      ),
    );
  }
}
