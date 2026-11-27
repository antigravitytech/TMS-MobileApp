import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';
import '../../../workspace/application/workspace_preview.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/kit_controls.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/alumni_controller.dart';

class AlumniCommittees extends ConsumerWidget {
  const AlumniCommittees({
    super.key,
    required this.view,
    required this.actions,
  });
  final AlumniView view;
  final AlumniController actions;
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final me = ref.watch(workspacePreviewProvider).firstName;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        specialIntro(c, 'alumni.committees_intro'),
        if (view.committees.isEmpty) const SpecialEmpty('committees'),
        for (final (i, k) in view.committees.indexed)
          Padding(
            key: ValueKey(k.id),
            padding: const EdgeInsets.only(bottom: 10),
            child: DesignEntrance(
              order: i,
              child: KitCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 12,
                      children: [
                        SpecialInitialTile(
                          k.title.characters.first,
                          specialTints[i % specialTints.length],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                k.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                c.plural(
                                  k.person.isEmpty
                                      ? 'alumni.no_lead'
                                      : 'alumni.lead',
                                  k.members.length,
                                  namedArgs: {'name': k.person},
                                ),
                                style: TextStyle(fontSize: 12, color: c.muted),
                              ),
                            ],
                          ),
                        ),
                        SpecialFaces(k.members),
                      ],
                    ),
                    if (k.todos.isNotEmpty) const SizedBox(height: 10),
                    for (final MapEntry(key: todo, value: done)
                        in k.todos.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          spacing: 10,
                          children: [
                            KitTick(
                              size: 24,
                              on: done,
                              label: todo,
                              onTap: () => actions.toggleTodo(k, todo),
                            ),
                            Expanded(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: done ? .55 : 1,
                                child: Text(
                                  todo,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: KitColor.tick,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (k.person.isEmpty) ...[
                      const SizedBox(height: 8),
                      KitMiniButton(
                        c.tr('alumni.pick_lead'),
                        onPressed: () async {
                          final done = c.tr(
                            'alumni.you_lead',
                            namedArgs: {'name': k.title},
                          );
                          if (await actions.takeLead(k, me) && c.mounted) {
                            designToast(c, done);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AlumniDirectory extends ConsumerWidget {
  const AlumniDirectory({super.key, required this.view, required this.actions});
  final AlumniView view;
  final AlumniController actions;
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final tones = [KitColor.done, KitColor.submitted, KitColor.overdue];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        specialIntro(c, 'alumni.directory_intro'),
        Row(
          spacing: 8,
          children: [
            for (final (i, a) in alumniActivity.indexed)
              Expanded(
                child: KitCard(
                  radius: 20,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${view.classmates.where((p) => p.activity == i).length}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: tones[i],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.tr('alumni.activity.$a'),
                        style: TextStyle(fontSize: 11.5, color: c.muted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (view.classmates.isEmpty)
          const SpecialEmpty('directory')
        else
          KitList(
            children: [
              for (final p in view.classmates)
                Padding(
                  key: ValueKey(p.id),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    children: [
                      Row(
                        spacing: 12,
                        children: [
                          DesignAvatar(
                            kitPerson(p.title).$1,
                            size: 36,
                            color: kitPerson(p.title).$2,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (p.notes.isNotEmpty)
                                  Text(
                                    p.notes,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: c.muted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      KitSegment<int>(
                        values: const [0, 1, 2],
                        selected: p.activity,
                        label: (i) =>
                            c.tr('alumni.activity.${alumniActivity[i]}'),
                        onChanged: (i) => actions.setActivity(p, i),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        DesignButton(
          c.tr('alumni.add_classmate'),
          secondary: true,
          onPressed: () =>
              addSpecialRecord(c, ref, view.space, WorkspaceSection.directory),
        ),
      ],
    );
  }
}
