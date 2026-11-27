import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_widgets.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/dated_row.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/special_actions.dart';
import 'special_compose.dart';
import 'special_records.dart';

extension SpecialTags on WorkspaceRecord {
  /// Agenda points or notes shown as tags, one per line of `fields['tags']`.
  List<String> get tags => [
    for (final a in (fields['tags'] ?? '').split('\n'))
      if (a.trim().isNotEmpty) a.trim(),
  ];
}

/// Upcoming meetings or sessions: date cards with tags, reply buttons and an
/// add button. Committee meetings and Club sessions both use it.
class SpecialMeetingList extends ConsumerWidget {
  const SpecialMeetingList({
    super.key,
    required this.workspace,
    required this.section,
    required this.records,
    required this.replies,
    required this.copy,
  });
  final LocalWorkspace workspace;
  final WorkspaceSection section;

  /// Upcoming records, soonest first.
  final List<WorkspaceRecord> records;

  /// Reply codes, shown from `<copy>.replies.<code>`.
  final List<String> replies;

  /// Copy prefix holding `intro`, `add` and `replies.<code>`.
  final String copy;
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final locale = c.locale.toString();
    final actions = ref.read(specialActionsProvider(workspace.id));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        specialIntro(c, '$copy.intro'),
        if (records.isEmpty) SpecialEmpty(section.name),
        for (final (i, m) in records.indexed)
          Padding(
            key: ValueKey(m.id),
            padding: const EdgeInsets.only(bottom: 10),
            child: DesignEntrance(
              order: i,
              child: KitCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DatedRow(
                      date: m.date!,
                      title: m.title,
                      meta: [
                        DateFormat.MMMEd(locale).format(m.date!),
                        DateFormat.Hm(locale).format(m.date!),
                        m.group,
                        m.person,
                      ].where((s) => s.isNotEmpty).join(' · '),
                    ),
                    if (m.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [for (final a in m.tags) KitTag(a)],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      spacing: 8,
                      children: [
                        for (final reply in replies)
                          Expanded(
                            child: KitMiniButton(
                              c.tr('$copy.replies.$reply'),
                              primary: m.fields['myReply'] == reply,
                              onPressed: () async {
                                final msg = c.tr(
                                  'specials.reply_toast',
                                  namedArgs: {
                                    'reply': c.tr('$copy.replies.$reply'),
                                    'meeting': m.title,
                                  },
                                );
                                final ok = await actions.reply(m, reply);
                                if (c.mounted) {
                                  designToast(
                                    c,
                                    ok ? msg : c.tr('workspaces.try_again'),
                                  );
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 2),
        DesignButton(
          c.tr('$copy.add'),
          secondary: true,
          onPressed: () => addSpecialRecord(c, ref, workspace, section),
        ),
      ],
    );
  }
}
