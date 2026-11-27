import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../../shared/kit/kit.dart';
import '../../application/event_controller.dart';

class EventProgramme extends StatelessWidget {
  const EventProgramme({
    super.key,
    required this.view,
    required this.state,
    required this.actions,
  });
  final EventView view;
  final EventState state;
  final EventController actions;
  @override
  Widget build(BuildContext c) {
    final items = view.programme;
    final locale = c.locale.toString();
    final time = DateFormat.jm(locale);
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
        children: const [SpecialEmpty('programme')],
      );
    }
    final end = items.last.date!.add(Duration(minutes: items.last.duration));
    final now = state.now.clamp(0, items.length - 1);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        if (state.running)
          KitPop(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: DesignColor.purple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                spacing: 10,
                children: [
                  const Icon(TmsIcons.playFilled, color: DesignColor.ink),
                  Expanded(
                    child: Text(
                      c.tr('event.now', namedArgs: {'name': items[now].title}),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: DesignColor.ink,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      actions.next(items.length);
                      final n = (now + 1).clamp(0, items.length - 1);
                      designToast(
                        c,
                        c.tr(
                          'event.up_next',
                          namedArgs: {'name': items[n].title},
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0x40ffffff),
                      foregroundColor: DesignColor.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: Text(c.tr('event.next')),
                  ),
                ],
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text:
                      '${time.format(items.first.date!).toLowerCase()} – ${time.format(end).toLowerCase()} ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  children: [
                    TextSpan(
                      text: c.plural('event.items', items.length),
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
            KitMiniButton(
              c.tr(state.running ? 'event.stop' : 'event.run_day'),
              primary: !state.running,
              onPressed: () => actions.run(!state.running),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final (i, p) in items.indexed)
          _TimelineItem(
            key: ValueKey(p.id),
            time: time.format(p.date!).replaceAll(RegExp(r'\s?[AP]M$'), ''),
            item: p,
            part: p.fields['part'] ?? '',
            now: state.running && i == now,
            past: state.running && i < now,
            last: i == items.length - 1,
          ),
      ],
    );
  }
}

/// `.tl-it`: time on the left, a dot on the line, then the item.
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    super.key,
    required this.time,
    required this.item,
    required this.part,
    required this.now,
    required this.past,
    required this.last,
  });
  final String time, part;
  final WorkspaceRecord item;
  final bool now, past, last;
  @override
  Widget build(BuildContext c) {
    final meta = [
      c.plural('event.minutes', item.duration),
      if (item.notes.isNotEmpty) item.notes,
    ].join(' · ');
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: past ? .5 : 1,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 48,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  time,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.muted,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 30,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (!last)
                    Positioned(
                      top: 10,
                      bottom: 0,
                      child: Container(width: 2, color: c.outline),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: AnimatedContainer(
                      duration: DesignMotion.fast,
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: now
                            ? DesignColor.purple
                            : past
                            ? KitColor.done
                            : c.background,
                        border: Border.all(
                          width: 2.5,
                          color: now
                              ? DesignColor.purple
                              : past
                              ? KitColor.done
                              : c.foreground.withValues(alpha: .25),
                        ),
                        boxShadow: now
                            ? const [
                                BoxShadow(
                                  color: Color(0x2e9184d9),
                                  spreadRadius: 5,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (part.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          c.tr('event.parts.$part').toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: c.muted,
                          ),
                        ),
                      ),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(meta, style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
