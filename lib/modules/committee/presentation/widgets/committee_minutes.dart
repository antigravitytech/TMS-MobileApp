import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_widgets.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/dated_row.dart';
import '../../../../shared/kit/kit_controls.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/committee_controller.dart';

/// Minutes tab: the latest minutes, editable, with save and a way to turn
/// "X to do Y" lines into action items.
class CommitteeMinutes extends StatefulWidget {
  const CommitteeMinutes({
    super.key,
    required this.view,
    required this.actions,
  });
  final CommitteeView view;
  final CommitteeController actions;
  @override
  State<CommitteeMinutes> createState() => _CommitteeMinutesState();
}

class _CommitteeMinutesState extends State<CommitteeMinutes> {
  late final _text = TextEditingController(text: _minutes?.notes ?? '');
  var _edited = false;

  WorkspaceRecord? get _minutes => widget.view.minutes.firstOrNull;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save(WorkspaceRecord m) async {
    final c = context;
    final ok = await widget.actions.saveMinutes(m, _text.text);
    if (!c.mounted) return;
    if (ok) setState(() => _edited = false);
    designToast(
      c,
      c.tr(ok ? 'committee.minutes_saved' : 'workspaces.try_again'),
    );
  }

  Future<void> _toActions(WorkspaceRecord m) async {
    final c = context;
    final from = c.tr('committee.from_minutes');
    final n = await widget.actions.actionsFromMinutes(_text.text, from);
    if (!c.mounted) return;
    if (n == null) return designToast(c, c.tr('workspaces.try_again'));
    if (n > 0) widget.actions.tab(CommitteeTab.actions);
    designToast(
      c,
      n == 0 ? c.tr('committee.no_jobs') : c.plural('committee.jobs_found', n),
    );
  }

  @override
  Widget build(BuildContext c) {
    final m = _minutes;
    final saved = m != null && m.status == WorkspaceStatus.done && !_edited;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        specialIntro(c, 'committee.minutes_intro'),
        if (m == null)
          const SpecialEmpty('minutes')
        else
          DesignEntrance(
            child: KitCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DatedRow(
                    date: m.date ?? widget.view.today,
                    title: m.title,
                    meta: c.tr(
                      'committee.minutes_meta',
                      namedArgs: {
                        'n': m.fields['read'] ?? '0',
                        'total': '${widget.view.members}',
                        'name': m.person,
                      },
                    ),
                    trailing: KitStatus(
                      c.tr(saved ? 'committee.saved' : 'committee.draft'),
                      saved ? KitColor.done : KitColor.submitted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  KitInput(
                    controller: _text,
                    hint: c.tr('committee.minutes_hint'),
                    lines: 6,
                    onChanged: (_) {
                      if (!_edited) setState(() => _edited = true);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: KitMiniButton(
                          c.tr('committee.to_actions'),
                          onPressed: () => _toActions(m),
                        ),
                      ),
                      KitMiniButton(
                        c.tr('committee.save'),
                        primary: true,
                        onPressed: () => _save(m),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
