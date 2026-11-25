import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/quick_create.dart';
import '../../tasks/presentation/task_card.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final input = TextEditingController();
  String query = '';
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final terms = query.toLowerCase().trim();
    final tasks = ref
        .watch(workspacePreviewProvider)
        .tasks
        .where(
          (t) =>
              terms.isNotEmpty &&
              '${t.title} ${t.id} ${t.project} ${t.person}'
                  .toLowerCase()
                  .contains(terms),
        );
    final actions = QuickCreate.actions.where(
      (a) => context.tr(a.$1).toLowerCase().contains(terms),
    );
    final projects = [
      'Customer Portal Revamp',
      'Mobile App Launch',
    ].where((p) => p.toLowerCase().contains(terms));
    final people = [
      'Tunde Bakare',
      'Ibrahim Musa',
      'Amaka Eze',
    ].where((p) => terms.isNotEmpty && p.toLowerCase().contains(terms));
    return DesignPage(
      title: context.tr('common.search'),
      children: [
        DesignField(
          label: context.tr('common.search_tasks_people_or_actions'),
          autofocus: true,
          controller: input,
          onChanged: (value) => setState(() => query = value),
          suffix: IconButton(
            tooltip: context.tr('search.clear_search'),
            onPressed: () {
              input.clear();
              setState(() => query = '');
            },
            icon: const Icon(TmsIcons.close),
          ),
        ),
        if (terms.isEmpty) ...[
          DesignTitle(context.tr('common.recent')),
          Wrap(
            spacing: 8,
            children: [
              for (final term in ['webhook', 'Tunde', 'TK-190'])
                DesignPill(
                  term,
                  onTap: () {
                    input.text = term;
                    setState(() => query = term);
                  },
                ),
            ],
          ),
        ],
        if (tasks.isNotEmpty) ...[
          DesignTitle(context.tr('common.tasks')),
          for (final task in tasks) TaskCard(task, key: ValueKey(task.id)),
        ],
        if (actions.isNotEmpty) ...[
          DesignTitle(context.tr('search.quick_actions')),
          DesignSection(
            children: [
              for (final action in actions)
                DesignTile(
                  title: context.tr(action.$1),
                  icon: action.$2,
                  onTap: () => action.$4.open(context),
                ),
            ],
          ),
        ],
        if (projects.isNotEmpty) ...[
          DesignTitle(context.tr('common.projects')),
          DesignSection(
            children: [
              for (final project in projects)
                DesignTile(
                  title: project,
                  icon: TmsIcons.folder,
                  onTap: () => TmsRoute.projects.open(context),
                ),
            ],
          ),
        ],
        if (people.isNotEmpty) ...[
          DesignTitle(context.tr('search.people')),
          DesignSection(
            children: [
              for (final person in people)
                DesignTile(
                  title: person,
                  icon: TmsIcons.person,
                  onTap: () => TmsRoute.conversation.open(context),
                ),
            ],
          ),
        ],
        if (tasks.isEmpty &&
            actions.isEmpty &&
            projects.isEmpty &&
            people.isEmpty)
          DesignEmpty(
            context.tr(
              'search.no_results_for_query',
              namedArgs: {'query': query},
            ),
            context.tr('search.try_a_persons_name_a_task_id'),
            icon: TmsIcons.searchEmpty,
          ),
      ],
    );
  }
}
