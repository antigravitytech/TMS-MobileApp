import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../../../shared/kit/kit_controls.dart';
import '../../application/chores_controller.dart';

/// "New chore" sheet: name, who does it, due and points.
Future<void> showChoreAdd(BuildContext context, String workspaceId) =>
    designSheet<void>(
      context,
      title: context.tr('chores.new'),
      builder: (_) => _ChoreAddForm(workspaceId: workspaceId),
    );

class _ChoreAddForm extends ConsumerStatefulWidget {
  const _ChoreAddForm({required this.workspaceId});
  final String workspaceId;
  @override
  ConsumerState<_ChoreAddForm> createState() => _ChoreAddFormState();
}

class _ChoreAddFormState extends ConsumerState<_ChoreAddForm> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = ref.read(
      choresControllerProvider(widget.workspaceId).notifier,
    );
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final failed = context.tr('workspaces.try_again');
    final added = context.tr(
      'chores.added',
      namedArgs: {
        'name': ref
            .read(choresControllerProvider(widget.workspaceId))
            .draft
            .who,
      },
    );
    final who = await notifier.add(_name.text, context.tr('chores.example'));
    if (!mounted) return;
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(who == null ? failed : added),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext c) {
    final d = ref.watch(choresControllerProvider(widget.workspaceId)).draft;
    final actions = ref.read(
      choresControllerProvider(widget.workspaceId).notifier,
    );
    final label = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: c.muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitInput(
          controller: _name,
          hint: c.tr('chores.placeholder'),
          autofocus: true,
        ),
        const SizedBox(height: 16),
        Text(c.tr('chores.who'), style: label),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final name in choreAssignees)
                _Person(
                  name: name,
                  selected: d.who == name,
                  onTap: () => actions.pickWho(name),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(c.tr('chores.due'), style: label),
        const SizedBox(height: 8),
        KitSegment<String>(
          values: choreDues,
          selected: d.due,
          label: (k) => c.tr('chores.dues.$k'),
          onChanged: actions.pickDue,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.tr('chores.points'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    c.tr('chores.points_hint'),
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
            ),
            _Step('−', c.tr('chores.fewer'), () => actions.stepPoints(-5)),
            const SizedBox(width: 6),
            KitPoints(d.points, large: true),
            const SizedBox(width: 6),
            _Step('+', c.tr('chores.more'), () => actions.stepPoints(5)),
          ],
        ),
        const SizedBox(height: 20),
        DesignButton(c.tr('chores.add'), onPressed: _save),
      ],
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({
    required this.name,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final (initials, color) = kitPerson(name);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          spacing: 6,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: DesignMotion.curve,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 3,
                  color: selected ? DesignColor.purple : Colors.transparent,
                ),
              ),
              child: DesignAvatar(initials, size: 36, color: color),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? c.foreground : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.symbol, this.label, this.onTap);
  final String symbol, label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExcludeSemantics(
          child: Text(
            symbol,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ),
  );
}
