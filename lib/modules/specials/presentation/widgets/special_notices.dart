import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/special_actions.dart';
import 'special_compose.dart';

/// Notices tab: post to everyone, then each notice with how many read it.
class SpecialNotices extends ConsumerWidget {
  const SpecialNotices({
    super.key,
    required this.workspaceId,
    required this.notices,
    required this.members,
  });
  final String workspaceId;

  /// Notices, newest first.
  final List<WorkspaceRecord> notices;
  final int members;
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final actions = ref.read(specialActionsProvider(workspaceId));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        Text(
          c.tr('specials.notices_intro'),
          style: TextStyle(fontSize: 13.5, color: c.muted),
        ),
        const SizedBox(height: 12),
        SpecialCompose(
          hint: c.tr('specials.notice_hint'),
          action: c.tr('specials.post'),
          footnote: c.tr('specials.goes_to', namedArgs: {'n': '$members'}),
          onSend: (text) async {
            final done = c.tr('specials.notice_posted');
            final failed = c.tr('workspaces.try_again');
            final ok = await actions.postNotice(text);
            if (c.mounted) designToast(c, ok ? done : failed);
            return ok;
          },
        ),
        const SizedBox(height: 12),
        for (final (i, n) in notices.indexed)
          Padding(
            key: ValueKey(n.id),
            padding: const EdgeInsets.only(bottom: 10),
            child: DesignEntrance(
              order: i,
              child: KitCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 10,
                      children: [
                        const KitTile(
                          TmsIcons.announcement,
                          color: DesignColor.amber,
                          size: 34,
                        ),
                        Text(
                          n.date == null
                              ? ''
                              : DateFormat.MMMEd(
                                  c.locale.toString(),
                                ).add_jm().format(n.date!),
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      n.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(
                          child: KitBar(
                            value: members == 0
                                ? 0
                                : (int.tryParse(n.fields['read'] ?? '') ?? 0) /
                                      members,
                            color: const Color(0xff2bb3a3),
                          ),
                        ),
                        Text(
                          c.tr(
                            'specials.read_by',
                            namedArgs: {
                              'n':
                                  '${(int.tryParse(n.fields['read'] ?? '') ?? 0)}',
                              'total': '$members',
                            },
                          ),
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
