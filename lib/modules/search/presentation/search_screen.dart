import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/workspace_preview.dart';

part 'widgets/search_results.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _input = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    _input.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() => _query = value);
  }

  @override
  Widget build(BuildContext context) {
    final term = _query.trim().toLowerCase();
    final preview = ref.watch(workspacePreviewProvider);
    final actions = <_SearchItem>[
      _SearchItem(
        'common.new_task',
        'search.new_task_subtitle',
        TmsIcons.add,
        DesignColor.purple,
        TmsRoute.newTask,
      ),
      _SearchItem(
        'search.log_todays_report',
        'search.report_subtitle',
        TmsIcons.edit,
        DesignColor.teal,
        TmsRoute.reports,
      ),
      _SearchItem(
        'common.clock_in',
        'search.clock_in_subtitle',
        TmsIcons.login,
        DesignColor.blue,
        TmsRoute.attendance,
      ),
      _SearchItem(
        'quick_create.invite_guest',
        'search.guest_subtitle',
        TmsIcons.badge,
        DesignColor.amber,
        TmsRoute.visitors,
      ),
      _SearchItem(
        'common.new_note',
        'search.note_subtitle',
        TmsIcons.note,
        DesignColor.rose,
        TmsRoute.journal,
      ),
    ];
    final projects = <_SearchItem>[
      _SearchItem(
        'Customer Portal Revamp',
        'search.portal_subtitle',
        TmsIcons.work,
        DesignColor.rose,
        TmsRoute.projects,
        rawTitle: true,
      ),
      _SearchItem(
        'Mobile App Launch',
        'search.mobile_subtitle',
        TmsIcons.work,
        DesignColor.amber,
        TmsRoute.projects,
        rawTitle: true,
      ),
    ];
    final people = <_SearchItem>[
      _SearchItem(
        'Tunde Bakare',
        'search.tunde_subtitle',
        TmsIcons.person,
        DesignColor.teal,
        TmsRoute.conversation,
        rawTitle: true,
      ),
      _SearchItem(
        'Ibrahim Musa',
        'search.ibrahim_subtitle',
        TmsIcons.person,
        DesignColor.purple,
        TmsRoute.conversation,
        rawTitle: true,
      ),
    ];
    final tasks = preview.tasks
        .where((task) => task.id == 'TK-190' || task.id == 'TK-142')
        .map(
          (task) => _SearchItem(
            task.title,
            task.id == 'TK-190'
                ? 'search.hiring_subtitle'
                : 'search.webhook_subtitle',
            TmsIcons.checkSquare,
            task.id == 'TK-190' ? DesignColor.blue : DesignColor.amber,
            TmsRoute.task,
            rawTitle: true,
            task: task,
          ),
        )
        .toList();
    bool matches(_SearchItem item) =>
        term.isEmpty ||
        '${item.title(context)} ${item.subtitle(context)}'
            .toLowerCase()
            .contains(term);
    final actionHits = term.isEmpty ? actions : actions.where(matches).toList();
    final taskHits = term.isEmpty
        ? <_SearchItem>[]
        : tasks.where(matches).toList();
    final projectHits = term.isEmpty
        ? projects
        : projects.where(matches).toList();
    final peopleHits = term.isEmpty
        ? <_SearchItem>[]
        : people.where(matches).toList();
    final none =
        term.isNotEmpty &&
        actionHits.isEmpty &&
        taskHits.isEmpty &&
        projectHits.isEmpty &&
        peopleHits.isEmpty;

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: context.panel,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: DesignColor.purple),
                            boxShadow: [
                              BoxShadow(
                                color: DesignColor.purple.withValues(
                                  alpha: .18,
                                ),
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 15),
                              Icon(
                                TmsIcons.search,
                                size: 18,
                                color: context.muted,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _input,
                                  autofocus: true,
                                  onChanged: (value) =>
                                      setState(() => _query = value),
                                  style: TextStyle(
                                    color: context.foreground,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: context.tr('search.input_hint'),
                                    hintStyle: TextStyle(color: context.muted),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => context.router.maybePop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: Text(
                          context.tr('search.cancel'),
                          style: TextStyle(
                            color: context.lavender,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                    children: [
                      if (term.isEmpty) ...[
                        _Label(context.tr('common.recent')),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final recent in ['webhook', 'Tunde', 'TK-190'])
                              ActionChip(
                                avatar: Icon(
                                  TmsIcons.clock,
                                  size: 14,
                                  color: context.muted,
                                ),
                                label: Text(recent),
                                onPressed: () => _setQuery(recent),
                                backgroundColor: context.background,
                                side: BorderSide(color: context.outline),
                                labelStyle: TextStyle(
                                  color: context.muted,
                                  fontSize: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (actionHits.isNotEmpty)
                        _Group(
                          term.isEmpty
                              ? context.tr('search.quick_actions')
                              : context.tr('search.quick_actions'),
                          actionHits,
                          preview,
                        ),
                      if (taskHits.isNotEmpty)
                        _Group(context.tr('common.tasks'), taskHits, preview),
                      if (projectHits.isNotEmpty)
                        _Group(
                          term.isEmpty
                              ? context.tr('search.jump_to')
                              : context.tr('common.projects'),
                          projectHits,
                          preview,
                        ),
                      if (peopleHits.isNotEmpty)
                        _Group(
                          context.tr('search.people'),
                          peopleHits,
                          preview,
                        ),
                      if (none)
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Column(
                            children: [
                              Text(
                                context.tr(
                                  'search.no_results_for_query',
                                  namedArgs: {'query': _query},
                                ),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.tr(
                                  'search.try_a_persons_name_a_task_id',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.muted),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
