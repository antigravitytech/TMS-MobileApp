import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../application/church_controller.dart';

/// Head counts per group for a service, stepped in fives.
Future<void> showAttendanceSheet(
  BuildContext context,
  WorkspaceRecord service,
  ChurchController actions,
) => designSheet<void>(
  context,
  title: '',
  builder: (sheet) {
    final counts = {for (final g in attendanceGroups) g: service.field(g)};
    return StatefulBuilder(
      builder: (sheet, set) {
        final total = counts.values.fold(0, (a, b) => a + b);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sheet.tr('church.record_attendance'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        service.title,
                        style: TextStyle(fontSize: 12, color: sheet.muted),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: DesignMotion.fast,
                  child: Text(
                    '$total',
                    key: ValueKey(total),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final (i, g) in attendanceGroups.indexed) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: sheet.foreground.withValues(alpha: .08),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: Text(
                        sheet.tr('church.groups.$g'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (final (sign, delta, label) in [
                      ('−', -5, 'church.less'),
                    ])
                      _Step(
                        sign,
                        sheet.tr(label),
                        () => set(
                          () =>
                              counts[g] = (counts[g]! + delta).clamp(0, 99999),
                        ),
                      ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${counts[g]}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _Step(
                      '+',
                      sheet.tr('church.more'),
                      () => set(() => counts[g] = counts[g]! + 5),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            DesignButton(
              sheet.tr('church.save_people', namedArgs: {'n': '$total'}),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(sheet);
                final navigator = Navigator.of(sheet);
                final done = sheet.tr(
                  'church.attendance_saved',
                  namedArgs: {'n': '$total', 'service': service.title},
                );
                final failed = sheet.tr('workspaces.try_again');
                final ok = await actions.saveAttendance(service, counts);
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ok ? done : failed),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  },
);

class _Step extends StatelessWidget {
  const _Step(this.sign, this.label, this.onTap);
  final String sign, label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExcludeSemantics(
          child: Text(
            sign,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ),
  );
}
