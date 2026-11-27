import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../workspace/application/workspace_preview.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/church_controller.dart';
import 'church_compose.dart';

class ChurchFirstTimers extends ConsumerWidget {
  const ChurchFirstTimers({
    super.key,
    required this.view,
    required this.actions,
  });
  final ChurchView view;
  final ChurchController actions;
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final me = ref.watch(workspacePreviewProvider).firstName;
    final list = view.firstTimers;
    final members = list.where((f) => f.stage == 4).length;
    Color tone(int s) => [
      c.muted,
      KitColor.progress,
      KitColor.submitted,
      const Color(0xffee9a6a),
      KitColor.done,
    ][s.clamp(0, 4)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        Text(
          c.tr(
            'church.first_line',
            namedArgs: {
              'n': '${list.length}',
              'pct': list.isEmpty
                  ? '0'
                  : '${(members * 100 / list.length).round()}',
            },
          ),
          style: TextStyle(fontSize: 13.5, color: c.muted),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 6,
            children: [
              for (final (i, s) in firstTimerStages.indexed)
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.raised,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: '${c.tr('church.stages.$s')} ',
                      style: TextStyle(color: c.muted),
                      children: [
                        TextSpan(
                          text: '${list.where((f) => f.stage == i).length}',
                          style: TextStyle(color: c.foreground),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const SpecialEmpty('firstTimers')
        else
          KitList(
            children: [
              for (final f in list)
                Padding(
                  key: ValueKey(f.id),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    spacing: 12,
                    children: [
                      DesignAvatar(
                        kitPerson(f.title).$1,
                        size: 36,
                        color: kitPerson(f.title).$2,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              c.tr(
                                'church.first_came',
                                namedArgs: {
                                  'when': specialWhen(c, f.date, view.today),
                                  'who': (f.fields['followsUp'] ?? '').isEmpty
                                      ? c.tr('church.nobody')
                                      : f.fields['followsUp']!,
                                },
                              ),
                              style: TextStyle(fontSize: 12, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 6,
                        children: [
                          KitStatus(
                            c.tr(
                              'church.stages.${firstTimerStages[f.stage.clamp(0, 4)]}',
                            ),
                            tone(f.stage),
                          ),
                          if (f.stage < 4)
                            GestureDetector(
                              onTap: () async {
                                final stage = c.tr(
                                  'church.stages.${firstTimerStages[f.stage + 1]}',
                                );
                                final ok = await actions.advance(f, me);
                                if (!c.mounted) return;
                                specialToast(c, ok, 'church.moved', {
                                  'name': f.title,
                                  'stage': stage,
                                });
                              },
                              child: Text(
                                '${c.tr('church.next.${firstTimerStages[f.stage]}')} →',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.lavender,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        DesignButton(
          c.tr('church.add_first_timer'),
          secondary: true,
          onPressed: () => showFirstTimerSheet(c, actions),
        ),
      ],
    );
  }
}
