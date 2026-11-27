import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/network_failure_localization.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../authentication/domain/account.dart';
import '../../chat/application/chat_session.dart';
import '../../chat/data/chat_directory.dart';
import '../../chat/data/chat_repository.dart';
import '../../../shared/kit/kit.dart';
import '../../chat/presentation/widgets/chat_widgets.dart'
    show chatErrorMessage;
import '../../tasks/application/tasks_controller.dart';
import '../../tasks/presentation/widgets/task_labels.dart';
import '../application/search_controller.dart';
import '../domain/search.dart';

part 'widgets/search_results.dart';
part 'widgets/search_open.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _input = TextEditingController();
  String _query = '', _settled = '';
  SearchResults? _shown;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  /// Updates the quick actions at once and searches a moment after typing
  /// stops.
  void _changed(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _settled = value);
    });
  }

  void _setQuery(String value) {
    _input.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _debounce?.cancel();
    setState(() => _query = _settled = value);
  }

  @override
  Widget build(BuildContext context) {
    final term = _query.trim().toLowerCase();
    final settled = _settled.trim();
    final actions = <_SearchItem>[
      for (final (title, subtitle, icon, color, route) in const [
        (
          'common.new_task',
          'search.new_task_subtitle',
          TmsIcons.add,
          DesignColor.purple,
          TmsRoute.newTask,
        ),
        (
          'search.log_todays_report',
          'search.report_subtitle',
          TmsIcons.edit,
          DesignColor.teal,
          TmsRoute.reports,
        ),
        (
          'common.clock_in',
          'search.clock_in_subtitle',
          TmsIcons.login,
          DesignColor.blue,
          TmsRoute.attendance,
        ),
        (
          'quick_create.invite_guest',
          'search.guest_subtitle',
          TmsIcons.badge,
          DesignColor.amber,
          TmsRoute.visitors,
        ),
        (
          'common.new_note',
          'search.note_subtitle',
          TmsIcons.note,
          DesignColor.rose,
          TmsRoute.journal,
        ),
      ])
        _SearchItem(
          context.tr(title),
          context.tr(subtitle),
          icon,
          color,
          () => route.open(context),
        ),
    ];
    final actionHits = term.isEmpty
        ? actions
        : actions
              .where(
                (a) => '${a.title} ${a.subtitle}'.toLowerCase().contains(term),
              )
              .toList();
    final featured = term.isEmpty
        ? ref.watch(searchFeaturedProvider).value ?? const <SearchProject>[]
        : const <SearchProject>[];
    final recent = ref.watch(recentSearchesProvider);
    final search = settled.isEmpty || term.isEmpty
        ? null
        : ref.watch(searchResultsProvider(settled));
    // Keep the last results on screen while the next query loads.
    if (search?.value case final results?) _shown = results;
    if (term.isEmpty) _shown = null;
    final results = _shown ?? const SearchResults();
    final failure = search?.error;
    final taskHits = [
      for (final (i, hit) in results.tasks.indexed)
        _SearchItem(
          hit.task.title,
          _taskDetail(context, hit),
          TmsIcons.checkSquare,
          _tone(_taskTones, i),
          () => _openTask(hit),
        ),
    ];
    final projectHits = [
      for (final (i, hit)
          in (term.isEmpty ? featured : results.projects).indexed)
        _SearchItem(
          hit.project.name,
          _projectDetail(context, hit),
          TmsIcons.work,
          _tone(_projectTones, i),
          _openProject,
        ),
    ];
    final peopleHits = [
      for (final (i, person) in results.people.indexed)
        _SearchItem(
          person.name,
          _personDetail(context, person),
          TmsIcons.person,
          _tone(_personTones, i),
          () => _openPerson(person),
        ),
    ];
    final none =
        term.isNotEmpty &&
        search?.hasValue == true &&
        !search!.isLoading &&
        actionHits.isEmpty &&
        results.isEmpty;

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
                                  onChanged: _changed,
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
                      if (term.isEmpty && recent.isNotEmpty) ...[
                        _Label(context.tr('common.recent')),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final query in recent)
                              ActionChip(
                                avatar: Icon(
                                  TmsIcons.clock,
                                  size: 14,
                                  color: context.muted,
                                ),
                                label: Text(query),
                                onPressed: () => _setQuery(query),
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
                        _Group(context.tr('search.quick_actions'), actionHits),
                      if (taskHits.isNotEmpty)
                        _Group(context.tr('common.tasks'), taskHits),
                      if (projectHits.isNotEmpty)
                        _Group(
                          term.isEmpty
                              ? context.tr('search.jump_to')
                              : context.tr('common.projects'),
                          projectHits,
                        ),
                      if (peopleHits.isNotEmpty)
                        _Group(context.tr('search.people'), peopleHits),
                      if (failure != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 22),
                          child: DesignLabel(
                            failure is AccountFailure
                                ? failure.type.localizedMessage(context)
                                : context.tr('network.errors.unknown'),
                          ),
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
