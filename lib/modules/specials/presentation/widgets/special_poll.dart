import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/special_actions.dart';
import 'special_compose.dart';
import 'special_records.dart';

/// Poll tab: the latest poll with live results, and a way to start one.
class SpecialPoll extends ConsumerWidget {
  const SpecialPoll({
    super.key,
    required this.workspace,
    required this.poll,
    required this.voters,
    this.section = WorkspaceSection.poll,
    this.intro = 'specials.poll_intro',
  });
  final String intro;
  final LocalWorkspace workspace;

  /// Where new polls are saved (Committee keeps them as decisions).
  final WorkspaceSection section;
  final WorkspaceRecord? poll;

  /// How many people can vote, for "N of M voted".
  final int voters;
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final actions = ref.read(specialActionsProvider(workspace.id));
    final poll = this.poll;
    final votes = poll?.votes ?? const <int>[];
    final total = votes.fold(0, (a, b) => a + b);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        specialIntro(c, intro),
        if (poll == null)
          const SpecialEmpty('poll')
        else
          DesignEntrance(
            child: KitCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: DesignColor.purple.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          c
                              .tr(
                                poll.fields['byMe'] == 'true'
                                    ? 'specials.poll_by_you'
                                    : poll.person.isEmpty
                                    ? 'specials.poll_chip'
                                    : 'specials.poll_by',
                                namedArgs: {'name': poll.person},
                              )
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .5,
                            color: c.lavender,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        c.tr(
                          'specials.voted',
                          namedArgs: {'n': '$total', 'of': '$voters'},
                        ),
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    poll.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final (i, option) in poll.options.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _VoteOption(
                        label: option,
                        share: total == 0 ? 0 : votes[i] / total,
                        mine: poll.vote == i,
                        onTap: () async {
                          final done = c.tr(
                            'specials.your_vote',
                            namedArgs: {'option': option},
                          );
                          if (await actions.vote(poll, i) && c.mounted) {
                            designToast(c, done);
                          }
                        },
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    c.tr(
                      poll.vote == null
                          ? 'specials.vote_hint'
                          : 'specials.vote_in',
                    ),
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        DesignButton(
          c.tr('specials.new_poll'),
          secondary: true,
          onPressed: () => addSpecialRecord(c, ref, workspace, section),
        ),
      ],
    );
  }
}

/// `.vopt`: an option whose share fills in behind it.
class _VoteOption extends StatelessWidget {
  const _VoteOption({
    required this.label,
    required this.share,
    required this.mine,
    required this.onTap,
  });
  final String label;
  final double share;
  final bool mine;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: DesignMotion.fast,
      height: 50,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.panel,
        border: Border.all(color: mine ? DesignColor.purple : c.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: share),
            duration: const Duration(milliseconds: 800),
            curve: DesignMotion.curve,
            builder: (_, v, _) => FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              heightFactor: 1,
              child: ColoredBox(
                color: DesignColor.purple.withValues(alpha: .18),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      mine ? '$label  ✓' : label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${(share * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
