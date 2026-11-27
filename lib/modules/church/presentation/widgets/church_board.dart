import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/church_controller.dart';
import 'church_compose.dart';

class ChurchUnits extends StatelessWidget {
  const ChurchUnits({super.key, required this.view});
  final ChurchView view;
  @override
  Widget build(BuildContext c) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
    children: [
      if (view.units.isEmpty) const SpecialEmpty('units'),
      for (final (i, u) in view.units.indexed)
        Padding(
          key: ValueKey(u.id),
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
                      SpecialInitialTile(
                        u.title.characters.first,
                        specialTints[i % specialTints.length],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              u.fields['when'] ?? '',
                              style: TextStyle(fontSize: 12, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                      if ((u.fields['me'] ?? '').isNotEmpty)
                        KitStatus(
                          c.tr('church.me.${u.fields['me']}'),
                          KitColor.progress,
                        ),
                    ],
                  ),
                  if (u.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      u.notes,
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                  if ((u.fields['urgent'] ?? '').isNotEmpty)
                    ChurchUrgent(u.fields['urgent']!),
                  const SizedBox(height: 10),
                  Row(
                    spacing: 10,
                    children: [
                      SpecialFaces([
                        for (final m in (u.fields['members'] ?? '').split('\n'))
                          if (m.trim().isNotEmpty) m.trim(),
                      ]),
                      Expanded(
                        child: Text(
                          u.fields['next'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
