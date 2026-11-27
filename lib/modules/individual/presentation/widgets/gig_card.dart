import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/gigs_controller.dart';

/// A running gig: status, client, slip note, two progress bars, milestones.
class GigCard extends StatelessWidget {
  const GigCard({super.key, required this.gig, required this.onMilestone});
  final WorkspaceRecord gig;
  final ValueChanged<String> onMilestone;
  @override
  Widget build(BuildContext c) {
    final day = DateFormat.MMMd(c.locale.toString());
    String date(String key) {
      final d = DateTime.tryParse(gig.fields[key] ?? '');
      return d == null ? '' : day.format(d);
    }

    final risk = gig.atRisk;
    final note = risk && (gig.fields['next'] ?? '').isNotEmpty
        ? c.tr(
            'individual.next_promise',
            namedArgs: {
              'step': gig.fields['next']!,
              'promised': date('promised'),
              'forecast': date('forecast'),
            },
          )
        : '';
    final label = TextStyle(fontSize: 12, color: c.muted);
    return KitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [
              KitStatus(
                c.tr(risk ? 'individual.at_risk' : 'individual.on_track'),
                risk ? KitColor.submitted : KitColor.done,
              ),
              if (gig.person.isNotEmpty)
                Flexible(
                  flex: 3,
                  child: Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: c.raised,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            gig.person,
                            overflow: TextOverflow.ellipsis,
                            style: label.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  c.tr('individual.mode.${gig.fields['mode'] ?? 'simple'}'),
                  textAlign: TextAlign.end,
                  style: label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            gig.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note,
              style: const TextStyle(fontSize: 12, color: KitColor.submitted),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            spacing: 14,
            children: [
              for (final (key, value, color) in [
                ('individual.accepted', gig.acceptedDelivery, DesignColor.teal),
                ('individual.tasks_done', gig.tasksDone, c.lavender),
              ])
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Text(c.tr(key), style: label),
                      KitBar(value: value, color: color),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (i, name) in gig.milestones.indexed) ...[
            if (i > 0)
              Divider(height: 1, color: c.foreground.withValues(alpha: .08)),
            _Milestone(
              name: name,
              state: gig.milestoneState(i),
              when: switch (gig.milestoneState(i)) {
                MilestoneState.done => c.tr('individual.done'),
                MilestoneState.late =>
                  '${date('promised')} → ${date('forecast')}',
                MilestoneState.upcoming =>
                  gig.milestoneDate(i) == null
                      ? ''
                      : day.format(gig.milestoneDate(i)!),
              },
              onTap: () => onMilestone(name),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.mile` row with its state dot (`.mdot`).
class _Milestone extends StatelessWidget {
  const _Milestone({
    required this.name,
    required this.state,
    required this.when,
    required this.onTap,
  });
  final String name, when;
  final MilestoneState state;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final fill = switch (state) {
      MilestoneState.done => KitColor.done,
      MilestoneState.late => KitColor.submitted,
      MilestoneState.upcoming => Colors.transparent,
    };
    return Semantics(
      button: true,
      toggled: state == MilestoneState.done,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            spacing: 12,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: kitSpring,
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(
                    width: 2.5,
                    color: state == MilestoneState.upcoming
                        ? c.foreground.withValues(alpha: .25)
                        : fill,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(when, style: TextStyle(fontSize: 12, color: c.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
