import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../workspace/application/workspace_preview.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/church_controller.dart';

export 'church_board.dart';
export 'church_first_timers.dart';

class ChurchPrayer extends ConsumerWidget {
  const ChurchPrayer({
    super.key,
    required this.view,
    required this.state,
    required this.actions,
  });
  final ChurchView view;
  final ChurchState state;
  final ChurchController actions;
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final me = ref.watch(workspacePreviewProvider).firstName;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        SpecialCompose(
          hint: c.tr('church.prayer_hint'),
          action: c.tr('church.send'),
          onSend: (text) async {
            final pastors = state.pastorsOnly;
            final ok = await actions.sharePrayer(text, me);
            if (c.mounted) {
              specialToast(
                c,
                ok,
                pastors ? 'church.sent_pastors' : 'church.shared',
              );
            }
            return ok;
          },
          options: [
            KitChip(
              compact: true,
              label: c.tr('church.pastors_only'),
              selected: state.pastorsOnly,
              onTap: actions.togglePastorsOnly,
            ),
            KitChip(
              compact: true,
              label: c.tr('church.hide_name'),
              selected: state.hideName,
              onTap: actions.toggleHideName,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          spacing: 8,
          children: [
            KitChip(
              label: c.tr('church.praying'),
              count: view.openPrayers,
              selected: true,
              onTap: () {},
            ),
            KitChip(
              label: c.tr('church.answered'),
              count: view.answeredPrayers,
              selected: false,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final (i, p) in view.prayers.indexed)
          Padding(
            key: ValueKey(p.id),
            padding: const EdgeInsets.only(bottom: 10),
            child: DesignEntrance(
              order: i,
              child: _PrayerCard(
                prayer: p,
                when: specialWhen(c, p.date, view.today),
                actions: actions,
              ),
            ),
          ),
      ],
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.prayer,
    required this.when,
    required this.actions,
  });
  final WorkspaceRecord prayer;
  final String when;
  final ChurchController actions;
  @override
  Widget build(BuildContext c) {
    final p = prayer;
    final anonymous = p.flag('anonymous') || p.person.isEmpty;
    final who = anonymous ? c.tr('church.someone') : p.person;
    final (initials, color) = anonymous
        ? ('SO', KitColor.avatar(8))
        : kitPerson(p.person);
    final done = p.status == WorkspaceStatus.done;
    final praying = p.flag('iPray');
    return Opacity(
      opacity: done ? .6 : 1,
      child: KitCard(
        color: done
            ? Color.alphaBlend(KitColor.done.withValues(alpha: .08), c.panel)
            : null,
        border: done ? KitColor.done.withValues(alpha: .3) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 10,
              children: [
                DesignAvatar(initials, size: 28, color: color),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        who,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        when,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
                if (p.flag('private'))
                  KitStatus(c.tr('church.private'), c.muted),
                if (done) KitStatus(c.tr('church.answered'), KitColor.done),
              ],
            ),
            const SizedBox(height: 10),
            Text(p.title, style: const TextStyle(fontSize: 13.5, height: 1.5)),
            const SizedBox(height: 12),
            Row(
              spacing: 8,
              children: [
                AnimatedScale(
                  scale: praying ? 1.06 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: kitSpring,
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () async {
                        final on = await actions.togglePraying(p);
                        if (!c.mounted) return;
                        if (on == null) {
                          specialToast(c, false, '');
                        } else if (on) {
                          specialToast(c, true, 'church.praying_for', {
                            'name': who,
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: praying
                            ? DesignColor.amber.withValues(alpha: .18)
                            : c.raised,
                        foregroundColor: praying
                            ? DesignColor.amber
                            : c.foreground,
                        side: BorderSide(
                          color: praying ? DesignColor.amber : c.outline,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: Text(
                        c.tr(
                          praying ? 'church.praying_on' : 'church.will_pray',
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    c.tr(
                      'church.praying_count',
                      namedArgs: {'n': '${p.field('praying')}'},
                    ),
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ),
                if (!done)
                  TextButton(
                    onPressed: () async {
                      final ok = await actions.markAnswered(p);
                      if (!c.mounted) return;
                      specialToast(c, ok, 'church.answered_toast');
                    },
                    child: Text(c.tr('church.mark_answered')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
