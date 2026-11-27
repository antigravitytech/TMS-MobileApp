import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../family/presentation/widgets/household_sheets.dart';
import '../../application/family_plan_controller.dart';

part 'family_plan_choices.dart';

Future<void> showFamilyPlanBuilder(
  BuildContext c,
  FamilyPlanController controller,
) => showModalBottomSheet<void>(
  context: c,
  isScrollControlled: true,
  backgroundColor: c.panel,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => _Builder(controller: controller),
);

class _Builder extends StatelessWidget {
  const _Builder({required this.controller});
  final FamilyPlanController controller;
  @override
  Widget build(BuildContext c) => ListenableBuilder(
    listenable: controller,
    builder: (c, _) {
      final d = controller;
      final key = familyPlanTemplates[d.template];
      return SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(c).height * .82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: c.muted.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.tr('family_plans.new'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            c.tr('family_plans.untick'),
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(c),
                      tooltip: c.tr('common.back'),
                      icon: const Icon(TmsIcons.close, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: c.outline),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              for (var i = 0; i < 3; i++)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => d.changeMode(i),
                                    child: AnimatedContainer(
                                      duration: DesignMotion.fast,
                                      height: 38,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: d.mode == i
                                            ? c.raised
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        c.tr('family_plans.mode$i'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: d.mode == i
                                              ? c.foreground
                                              : c.muted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          c.tr('family_plans.mode_detail${d.mode}'),
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                        const SizedBox(height: 20),
                        _label(c, 'family_plans.idea'),
                        const SizedBox(height: 5),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            spacing: 8,
                            children: [
                              for (var i = 0; i < 6; i++)
                                _Idea(
                                  c.tr(
                                    'family_plans.${familyPlanTemplates[i]}.title',
                                  ),
                                  selected: d.template == i,
                                  onTap: () => d.start(i),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _label(c, 'family_plans.members'),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            for (final name in familyPlanPeople)
                              GestureDetector(
                                onTap: () => d.toggleMember(name),
                                child: SizedBox(
                                  width: 42,
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: d.members.contains(name)
                                                ? DesignColor.purple
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Opacity(
                                          opacity: d.members.contains(name)
                                              ? 1
                                              : .4,
                                          child: DesignAvatar(
                                            _initials(name),
                                            color: householdColor(name),
                                            size: 34,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: d.members.contains(name)
                                              ? c.foreground
                                              : c.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _label(c, 'family_plans.steps')),
                            Text(
                              c.tr(
                                'family_plans.kept',
                                namedArgs: {
                                  'count': '${d.kept}',
                                  'total': '${d.total}',
                                },
                              ),
                              style: TextStyle(fontSize: 12, color: c.muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (var i = 0; i < d.total; i++)
                          InkWell(
                            onTap: () => d.toggleStep(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: c.outline.withValues(alpha: .5),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: DesignMotion.fast,
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: d.omitted.contains(i)
                                          ? Colors.transparent
                                          : DesignColor.purple,
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(
                                        color: d.omitted.contains(i)
                                            ? c.outline
                                            : DesignColor.purple,
                                      ),
                                    ),
                                    child: d.omitted.contains(i)
                                        ? null
                                        : const Icon(
                                            TmsIcons.check,
                                            size: 15,
                                            color: DesignColor.ink,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      c.tr('family_plans.$key.step$i'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: d.omitted.contains(i)
                                            ? c.muted
                                            : c.foreground,
                                        decoration: d.omitted.contains(i)
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(c),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          foregroundColor: c.foreground,
                          backgroundColor: c.raised,
                          side: BorderSide(color: c.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          c.tr('family_plans.cancel'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: DesignButton(
                        c.tr('family_plans.create'),
                        onPressed: d.busy || d.kept == 0
                            ? null
                            : () async {
                                final ok = await d.create(
                                  c.tr(
                                    key == 'blank'
                                        ? 'family_plans.our_plan'
                                        : 'family_plans.$key.title',
                                  ),
                                  [
                                    for (var i = 0; i < d.total; i++)
                                      c.tr('family_plans.$key.step$i'),
                                  ],
                                );
                                if (!c.mounted) return;
                                if (ok) {
                                  Navigator.pop(c);
                                } else {
                                  designToast(c, c.tr('workspaces.try_again'));
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
      );
    },
  );
  Widget _label(BuildContext c, String key) =>
      Text(c.tr(key), style: TextStyle(fontSize: 13, color: c.muted));
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
