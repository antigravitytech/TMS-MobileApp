import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import '../../../shared/kit/kit.dart';
import 'widgets/household_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../application/family_task_draft.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/application/workspace_preview.dart';
part 'widgets/family_task_options.dart';
part 'widgets/family_task_success.dart';

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
    // Children first, then staff, then the co-head; the head is "You".
    const order = ['child', 'cook', 'driver', 'cohead', 'security', 'head'];
    final members = widget.space.items(WorkspaceSection.household).toList()
      ..sort((a, b) {
        int rank(WorkspaceRecord r) {
          final i = order.indexOf(r.fields['householdRole'] ?? '');
          return i < 0 ? order.length - 1 : i;
        }

        return rank(a).compareTo(rank(b));
      });
    final full = <String, String>{
      for (final m in members)
        if (m.fields['householdRole'] == 'head')
          context.tr('family.you'): m.title
        else
          m.title.split(' ').first: m.title,
    };
    if (full.isEmpty && preview.firstName.isNotEmpty) {
      full[preview.firstName] = '${preview.firstName} ${preview.lastName}';
    }
    final people = full.keys.toList();
    final kind = draft.type.name;
    final names = draft.people.length < 2
        ? draft.people.join()
        : '${draft.people.take(draft.people.length - 1).join(', ')} ${context.tr('household.and')} ${draft.people.last}';
    if (draft.sent) {
      return _FamilyTaskSuccess(
        draft: draft,
        names: people.isNotEmpty && people.every(draft.people.contains)
            ? context.tr('family.everyone_lower')
            : names,
        onAgain: () {
          title.clear();
          draft.again();
        },
      );
    }
    return DesignPage(
      title: context.tr('family.task'),
      leading: DesignIcon(
        icon: TmsIcons.close,
        label: context.tr('common.back'),
        onPressed: () => context.router.maybePop(),
      ),
      footer: DesignButton(
        disabledColor: const Color(0xff514b76),
        draft.people.isEmpty
            ? context.tr('family.pick_person')
            : people.isNotEmpty && people.every(draft.people.contains)
            ? context.tr('family.give_everyone')
            : context.tr('family.${kind}_cta', namedArgs: {'names': names}),
        icon: [
          TmsIcons.shoppingBag,
          TmsIcons.file,
          TmsIcons.shoppingCart,
          TmsIcons.clock,
        ][draft.type.index],
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
        TextField(
          controller: title,
          onChanged: (v) => draft.title = v,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: context.tr('family.${kind}_hint'),
            filled: true,
            fillColor: context.panel,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.outline),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < 4; i++)
              ActionChip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                backgroundColor: context.raised,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: context.outline),
                ),
                label: Text(
                  context.tr('family.${kind}_$i'),
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  title.text = context.tr('family.${kind}_$i');
                  draft.title = title.text;
                },
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('family.who'),
                style: TextStyle(color: context.muted, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => draft.toggleEveryone(people),
              child: Text(
                context.tr(
                  draft.people.length == people.length
                      ? 'family.clear'
                      : 'family.everyone',
                ),
                style: TextStyle(color: context.lavender, fontSize: 13),
              ),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, bounds) => Wrap(
            spacing: 6,
            runSpacing: 10,
            children: [
              for (final name in people)
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
                                kitPerson(full[name]!).$1,
                                size: 48,
                                color: householdColor(full[name]!),
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
        DesignLabel(context.tr('family.when')),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final w in FamilyWhen.values)
              _FamilyChip(
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
