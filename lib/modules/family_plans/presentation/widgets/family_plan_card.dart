import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../family/presentation/widgets/household_sheets.dart';

class FamilyPlanCard extends StatelessWidget {
  const FamilyPlanCard({super.key, required this.plan, required this.onToggle});
  final WorkspaceRecord plan;
  final ValueChanged<String> onToggle;
  @override
  Widget build(BuildContext c) {
    final done = plan.todos.values.where((v) => v).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xff203750), Color(0xff242445), Color(0xff44478d)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  c.tr('family_plans.your_plan').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                c.tr(
                  'family_plans.done_count',
                  namedArgs: {'done': '$done', 'total': '${plan.todos.length}'},
                ),
                style: TextStyle(color: c.lavender, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            plan.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: 0,
              end: plan.todos.isEmpty ? 0 : done / plan.todos.length,
            ),
            duration: DesignMotion.fast,
            builder: (c, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 7,
              color: const Color(0xff2eb4a5),
              backgroundColor: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          for (final (i, entry) in plan.todos.entries.indexed)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: .07),
                  ),
                ),
              ),
              child: InkWell(
                onTap: () => onToggle(entry.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: DesignMotion.fast,
                        width: 29,
                        height: 29,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: entry.value
                              ? DesignColor.teal
                              : Colors.transparent,
                          border: Border.all(
                            color: entry.value
                                ? DesignColor.teal
                                : Colors.white38,
                            width: 1.5,
                          ),
                        ),
                        child: entry.value
                            ? const Icon(
                                TmsIcons.check,
                                size: 17,
                                color: DesignColor.ink,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plan.fields['owner$i'] ?? 'Ibrahim',
                              style: TextStyle(color: c.lavender, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      DesignAvatar(
                        _initials(plan.fields['owner$i'] ?? 'Ibrahim'),
                        size: 28,
                        color: householdColor(
                          plan.fields['owner$i'] ?? 'Ibrahim',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initials(String name) => switch (name) {
    'Ada' => 'AI',
    'Bisi' => 'BO',
    'Funmi' => 'FI',
    'Ibrahim' => 'IM',
    'Kwame' => 'KM',
    'Sule' => 'SG',
    _ => 'TI',
  };
}
