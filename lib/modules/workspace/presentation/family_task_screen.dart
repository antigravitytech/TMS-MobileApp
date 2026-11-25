import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/tms_icons.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import '../application/family_task_draft.dart';
import '../application/local_workspaces.dart';
import '../application/workspace_preview.dart';

part 'family_task_options.dart';

class FamilyTaskScreen extends ConsumerWidget {
  const FamilyTaskScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(localWorkspacesProvider).asData?.value.active;
    if (space == null || space.kind != WorkspaceKind.family) {
      return DesignPage(
        title: context.tr('family.task'),
        children: [
          DesignButton(
            context.tr('common.home'),
            onPressed: () => TmsRoute.home.reset(context),
          ),
        ],
      );
    }
    return _TaskForm(key: ValueKey(space.id), space: space);
  }
}

class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({super.key, required this.space});
  final LocalWorkspace space;
  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final title = TextEditingController();
  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(familyTaskDraftProvider(widget.space.id));
    final preview = ref.watch(workspacePreviewProvider);
    final people = {
      for (final r in widget.space.items(WorkspaceSection.household)) r.title,
      preview.firstName,
    }.where((name) => name.isNotEmpty).toList();
    final kind = draft.type.name;
    final names = draft.people.join(', ');
    if (draft.sent) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: DesignColor.teal,
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: const Icon(
                      TmsIcons.check,
                      size: 58,
                      color: DesignColor.ink,
                    ),
                  ),
                  Text(
                    draft.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  DesignLabel(
                    context.tr(
                      'family.done',
                      namedArgs: {
                        'type': context.tr('family.$kind'),
                        'names': names,
                        'when': DateFormat.MMMd(
                          context.locale.toString(),
                        ).format(draft.date),
                      },
                    ),
                  ),
                  DesignButton(
                    context.tr('family.back_home'),
                    onPressed: () => TmsRoute.home.reset(context),
                  ),
                  DesignButton(
                    context.tr('family.another'),
                    secondary: true,
                    onPressed: () {
                      title.clear();
                      draft.again();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return DesignPage(
      title: context.tr('family.task'),
      footer: DesignButton(
        draft.people.isEmpty
            ? context.tr('family.pick_person')
            : context.tr('family.${kind}_cta', namedArgs: {'names': names}),
        onPressed: draft.saving || draft.people.isEmpty
            ? null
            : () async {
                final result = await draft.submit(
                  context.tr('family.${kind}_0'),
                );
                if (context.mounted && result == FamilyTaskResult.failed) {
                  designToast(context, context.tr('workspaces.try_again'));
                }
              },
      ),
      children: [
        Row(
          spacing: 6,
          children: [
            for (final (i, type) in FamilyTaskType.values.indexed)
              Expanded(
                child: _TypeTile(
                  type: type,
                  selected: type == draft.type,
                  index: i,
                  onTap: () => draft.change(() => draft.type = type),
                ),
              ),
          ],
        ),
        DesignField(
          label: context.tr('family.${kind}_hint'),
          controller: title,
          onChanged: (v) => draft.title = v,
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < 4; i++)
              ActionChip(
                label: Text(context.tr('family.${kind}_$i')),
                onPressed: () {
                  title.text = context.tr('family.${kind}_$i');
                  draft.title = title.text;
                },
              ),
          ],
        ),
        DesignTitle(
          context.tr('family.who'),
          action: context.tr(
            draft.people.length == people.length
                ? 'family.clear'
                : 'family.everyone',
          ),
          onTap: () => draft.toggleEveryone(people),
        ),
        LayoutBuilder(
          builder: (context, bounds) => Wrap(
            spacing: 6,
            runSpacing: 10,
            children: [
              for (final (i, name) in people.indexed)
                SizedBox(
                  width: (bounds.maxWidth - 18) / 4,
                  child: InkWell(
                    onTap: () => draft.togglePerson(name),
                    child: Column(
                      spacing: 6,
                      children: [
                        AnimatedScale(
                          duration: DesignMotion.duration(
                            context,
                            DesignMotion.fast,
                          ),
                          scale: draft.people.contains(name) ? 1.06 : 1,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              DesignAvatar(
                                name
                                    .split(' ')
                                    .where((v) => v.isNotEmpty)
                                    .take(2)
                                    .map((v) => v.characters.first)
                                    .join(),
                                size: 48,
                                color: [
                                  DesignColor.teal,
                                  DesignColor.amber,
                                  DesignColor.rose,
                                  DesignColor.blue,
                                ][i % 4],
                              ),
                              if (draft.people.contains(name))
                                const Positioned(
                                  top: -2,
                                  right: -3,
                                  child: Icon(
                                    TmsIcons.checkCircleFilled,
                                    size: 20,
                                    color: DesignColor.purple,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        DesignTitle(context.tr('family.when')),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final w in FamilyWhen.values)
              DesignPill(
                context.tr('family.${w.name}'),
                selected: draft.when == w,
                onTap: () => draft.chooseWhen(w),
              ),
          ],
        ),
        if (draft.when == FamilyWhen.pick)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 6,
              children: [
                for (var i = 1; i <= 7; i++)
                  Builder(
                    builder: (context) {
                      final now = DateTime.now(),
                          date = DateTime(now.year, now.month, now.day + i);
                      return DesignPill(
                        DateFormat(
                          'EEE d',
                          context.locale.toString(),
                        ).format(date),
                        selected: DateUtils.isSameDay(draft.date, date),
                        onTap: () => draft.change(() => draft.date = date),
                      );
                    },
                  ),
              ],
            ),
          ),
        _FamilyOptions(draft: draft, space: widget.space),
      ],
    );
  }
}
