import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';

/// The gig most likely to slip, with its next promise and progress.
class IndividualGigWatch extends StatelessWidget {
  const IndividualGigWatch({super.key, required this.gig, required this.onTap});
  final WorkspaceRecord gig;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final f = gig.fields;
    final day = DateFormat.MMMd(c.locale.toString());
    String when(String key) {
      final d = DateTime.tryParse(f[key] ?? '');
      return d == null ? '' : day.format(d);
    }

    return GestureDetector(
      onTap: onTap,
      child: KitCard(
        border: DesignColor.amber.withValues(alpha: .45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                KitStatus(c.tr('individual.at_risk'), KitColor.submitted),
                if (gig.person.isNotEmpty) KitTag(gig.person),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              gig.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              c.plural(
                'individual.watch_line',
                int.tryParse(f['lateDays'] ?? '') ?? 0,
                namedArgs: {
                  'step': f['next'] ?? '',
                  'forecast': when('forecast'),
                  'promised': when('promised'),
                },
              ),
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
            const SizedBox(height: 12),
            KitBar(
              value: (int.tryParse(f['progress'] ?? '') ?? 0) / 100,
              color: KitColor.submitted,
            ),
          ],
        ),
      ),
    );
  }
}
