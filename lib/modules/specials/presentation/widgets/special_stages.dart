import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/kit_controls.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/special_actions.dart';
import 'special_compose.dart';
import 'special_records.dart';

/// A record's stage index, from its `stage` field.
extension SpecialStage on WorkspaceRecord {
  int get stage => int.tryParse(fields['stage'] ?? '') ?? 0;
}

/// Items that move through stages (e.g. Reported → Being fixed → Fixed):
/// filter chips, a tick for the last stage, a pill that advances the stage
/// and an add box. Estate issues and Committee action items use it.
class SpecialStageList extends ConsumerStatefulWidget {
  const SpecialStageList({
    super.key,
    required this.workspace,
    required this.section,
    required this.records,
    required this.stages,
    required this.copy,
  });
  final LocalWorkspace workspace;
  final WorkspaceSection section;
  final List<WorkspaceRecord> records;

  /// Stage codes in order; the last one means done.
  final List<String> stages;

  /// Copy prefix holding `intro`, `hint`, `added_by` and `stages.<code>`.
  final String copy;
  @override
  ConsumerState<SpecialStageList> createState() => _SpecialStageListState();
}

class _SpecialStageListState extends ConsumerState<SpecialStageList> {
  int? filter;
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _report() async {
    final text = _draft.text.trim();
    if (text.isEmpty) return;
    final by = context.tr('${widget.copy}.added_by');
    final done = context.tr('specials.item_added', namedArgs: {'title': text});
    final ok = await ref
        .read(specialActionsProvider(widget.workspace.id))
        .addStaged(widget.section, text, by);
    if (!mounted) return;
    if (ok) _draft.clear();
    designToast(context, ok ? done : context.tr('workspaces.try_again'));
  }

  @override
  Widget build(BuildContext c) {
    final issues = widget.records;
    final last = widget.stages.length - 1;
    final actions = ref.read(specialActionsProvider(widget.workspace.id));
    final tones = [c.muted, KitColor.progress, KitColor.done];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        specialIntro(c, '${widget.copy}.intro'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            KitChip(
              label: c.tr('common.all'),
              count: issues.length,
              selected: filter == null,
              onTap: () => setState(() => filter = null),
            ),
            for (final (i, s) in widget.stages.indexed)
              KitChip(
                label: c.tr('${widget.copy}.stages.$s'),
                count: issues.where((x) => x.stage == i).length,
                selected: filter == i,
                onTap: () => setState(() => filter = i),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (issues.isEmpty) const SpecialEmpty('issues'),
        for (final (i, x)
            in issues.where((x) => filter == null || x.stage == filter).indexed)
          Padding(
            key: ValueKey(x.id),
            padding: const EdgeInsets.only(bottom: 10),
            child: DesignEntrance(
              order: i,
              child: Opacity(
                opacity: x.stage == last ? .6 : 1,
                child: KitCard(
                  child: Row(
                    spacing: 12,
                    children: [
                      KitTick(
                        on: x.stage == last,
                        label: c.tr('specials.mark_done'),
                        onTap: () async {
                          final done = c.tr(
                            'specials.done_toast',
                            namedArgs: {'title': x.title},
                          );
                          final fixing = x.stage != last;
                          final ok = await actions.setStage(
                            x,
                            fixing ? last : 0,
                            last: last,
                          );
                          if (ok && fixing && c.mounted) designToast(c, done);
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              x.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                decoration: x.stage == last
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: KitColor.tick,
                              ),
                            ),
                            if (x.notes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  x.notes,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => actions.setStage(
                          x,
                          (x.stage + 1) % widget.stages.length,
                          last: last,
                        ),
                        child: KitPop(
                          key: ValueKey(x.stage),
                          child: KitStatus(
                            c.tr(
                              '${widget.copy}.stages.${widget.stages[x.stage.clamp(0, last)]}',
                            ),
                            tones[x.stage
                                .clamp(0, last)
                                .clamp(0, tones.length - 1)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 2),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: KitInput(
                controller: _draft,
                hint: c.tr('${widget.copy}.hint'),
              ),
            ),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _report,
                style: FilledButton.styleFrom(
                  backgroundColor: DesignColor.purple,
                  foregroundColor: DesignColor.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(c.tr('specials.add')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
