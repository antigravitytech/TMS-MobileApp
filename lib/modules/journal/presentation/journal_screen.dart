import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../tasks/presentation/tasks_screen.dart' show taskErrorMessage;
import '../application/journal_controller.dart';
import '../domain/note.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});
  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  static const filters = [
    'common.all',
    'common.pinned',
    'journal.reminders',
    'common.recent',
  ];
  static const colors = [
    Color(0xff393450),
    Color(0xff343d36),
    Color(0xff48333d),
    Color(0xff304456),
    Color(0xff4c4131),
    Color(0xff343d44),
  ];
  int tab = 0;
  Future<void> compose() async {
    String title = '', body = '';
    int color = 0;
    DateTime? remindAt;
    final note = await showModalBottomSheet<NoteDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => AnimatedContainer(
          duration: DesignMotion.fast,
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.viewPaddingOf(context).bottom +
                20,
          ),
          decoration: BoxDecoration(
            color: Color.lerp(context.panel, colors[color], .65),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.muted.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              TextField(
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: context.tr('common.title'),
                  border: InputBorder.none,
                ),
                onChanged: (value) => title = value,
              ),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: context.tr('journal.thought_hint'),
                  border: InputBorder.none,
                ),
                onChanged: (value) => body = value,
              ),
              Wrap(
                spacing: 3,
                children: [
                  for (var i = 0; i < colors.length; i++)
                    IconButton(
                      tooltip: context.tr(
                        'journal.note_colour',
                        namedArgs: {'number': (i + 1).toString()},
                      ),
                      icon: CircleAvatar(
                        radius: 14,
                        backgroundColor: colors[i],
                        child: color == i
                            ? const Icon(
                                TmsIcons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      onPressed: () => update(() => color = i),
                    ),
                ],
              ),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: DesignButton(
                      remindAt == null
                          ? context.tr('journal.remind_me')
                          : _day(context, remindAt!),
                      secondary: true,
                      icon: TmsIcons.clock,
                      onPressed: () async {
                        final now = DateTime.now();
                        final day = await showDatePicker(
                          switchToInputEntryModeIcon: const Icon(
                            TmsIcons.keyboard,
                          ),
                          switchToCalendarEntryModeIcon: const Icon(
                            TmsIcons.calendar,
                          ),
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 5),
                        );
                        if (context.mounted && day != null) {
                          // 9:00 that day, or an hour from now if that has
                          // passed; reminders must be in the future.
                          final morning = DateTime(
                            day.year,
                            day.month,
                            day.day,
                            9,
                          );
                          update(
                            () => remindAt = morning.isAfter(DateTime.now())
                                ? morning
                                : DateTime.now().add(const Duration(hours: 1)),
                          );
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: DesignButton(
                      context.tr('journal.save_note'),
                      color: context.foreground,
                      onPressed: () => Navigator.pop<NoteDraft>(sheet, (
                        title: title.trim().isEmpty
                            ? context.tr('journal.untitled')
                            : title.trim(),
                        body: body.trim(),
                        color: noteColors[color],
                        remindAt: remindAt,
                      )),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || note == null) return;
    try {
      await ref.read(journalProvider.notifier).create(note);
      if (mounted) setState(() => tab = 0);
    } catch (error) {
      if (mounted) designToast(context, taskErrorMessage(context, error));
    }
  }

  static String _day(BuildContext context, DateTime at) =>
      DateFormat('d MMM', context.locale.toString()).format(at);

  Future<void> _togglePin(JournalNote note) async {
    try {
      await ref.read(journalProvider.notifier).togglePin(note);
    } catch (error) {
      if (mounted) designToast(context, taskErrorMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(journalProvider);
    final notes = async.value ?? const <JournalNote>[];
    final week = DateTime.now().subtract(const Duration(days: 7));
    final visible = notes
        .where(
          (note) => switch (tab) {
            1 => note.pinned,
            2 => note.remindAt != null,
            3 => note.updatedAt.isAfter(week),
            _ => true,
          },
        )
        .toList();
    return DesignPage(
      title: context.tr('common.journal'),
      subtitle: context.tr('journal.yours_alone_not_your_managers'),
      actions: [
        DesignIcon(
          icon: TmsIcons.search,
          label: context.tr('journal.search_notes'),
          onPressed: () => TmsRoute.search.open(context),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: context.tr('common.new_note'),
        backgroundColor: DesignColor.purple,
        onPressed: compose,
        child: const Icon(TmsIcons.add, color: DesignColor.ink),
      ),
      children: [
        DesignChoices(
          items: filters.map(context.tr).toList(),
          selected: tab,
          onChanged: (i) => setState(() => tab = i),
        ),
        if (async.value == null && !async.hasError)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (async.value == null) ...[
          DesignLabel(taskErrorMessage(context, async.error)),
          DesignButton(
            context.tr('workspaces.try_again'),
            secondary: true,
            onPressed: () => ref.invalidate(journalProvider),
          ),
        ] else if (visible.isEmpty)
          DesignEmpty(
            context.tr('journal.no_notes_here'),
            context.tr('journal.new_notes_will_appear_in_your_journal'),
            icon: TmsIcons.note,
          ),
        for (var i = 0; i < visible.length; i += 2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Expanded(child: _card(visible[i])),
              if (i + 1 < visible.length)
                Expanded(child: _card(visible[i + 1]))
              else
                const Spacer(),
            ],
          ),
      ],
    );
  }

  Widget _card(JournalNote note) => DesignCard(
    color: colors[noteColors.indexOf(note.color).clamp(0, colors.length - 1)],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 7,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                note.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: note.pinned
                  ? context.tr('journal.unpin')
                  : context.tr('journal.pin'),
              onPressed: () => _togglePin(note),
              icon: Icon(
                note.pinned ? TmsIcons.pin : TmsIcons.pin,
                color: Colors.white70,
                size: 17,
              ),
            ),
          ],
        ),
        if (note.body.isNotEmpty) DesignLabel(note.body, color: Colors.white70),
        if (note.remindAt case final at?)
          DesignPill(
            _day(context, at),
            icon: TmsIcons.clock,
            color: Colors.white70,
          ),
      ],
    ),
  );
}
