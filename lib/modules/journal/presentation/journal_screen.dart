import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
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
  final notes = <_Note>[
    _Note(
      'Hiring plan',
      'Check in with Ibrahim about the backend shortlist.',
      0,
      pinned: true,
    ),
    _Note(
      'Portal review',
      'Bring the severity ranking and clips to standup.',
      1,
    ),
    _Note(
      'Tunde’s birthday',
      'Cake at lunch. Bring the card.',
      2,
      reminder: '23 Nov',
    ),
    _Note('Sprint 14 retro', 'Ask for feedback on the review queue.', 3),
  ];
  int tab = 0;
  Future<void> compose() async {
    String title = '', body = '';
    int color = 0;
    String? reminder;
    final note = await showModalBottomSheet<_Note>(
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
                      reminder ?? context.tr('journal.remind_me'),
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
                          update(
                            () => reminder = MaterialLocalizations.of(
                              context,
                            ).formatShortDate(day),
                          );
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: DesignButton(
                      context.tr('journal.save_note'),
                      color: context.foreground,
                      onPressed: () => Navigator.pop(
                        sheet,
                        _Note(
                          title.trim().isEmpty
                              ? context.tr('journal.untitled')
                              : title.trim(),
                          body.trim(),
                          color,
                          reminder: reminder,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted && note != null) {
      setState(() {
        notes.insert(0, note);
        tab = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = notes
        .where(
          (note) => switch (tab) {
            1 => note.pinned,
            2 => note.reminder != null,
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
        if (visible.isEmpty)
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

  Widget _card(_Note note) => DesignCard(
    color: colors[note.color],
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
              onPressed: () => setState(() => note.pinned = !note.pinned),
              icon: Icon(
                note.pinned ? TmsIcons.pin : TmsIcons.pin,
                color: Colors.white70,
                size: 17,
              ),
            ),
          ],
        ),
        if (note.body.isNotEmpty) DesignLabel(note.body, color: Colors.white70),
        if (note.reminder != null)
          DesignPill(
            note.reminder!,
            icon: TmsIcons.clock,
            color: Colors.white70,
          ),
      ],
    ),
  );
}

class _Note {
  _Note(
    this.title,
    this.body,
    this.color, {
    this.pinned = false,
    this.reminder,
  });
  final String title, body;
  final int color;
  final String? reminder;
  bool pinned;
}
