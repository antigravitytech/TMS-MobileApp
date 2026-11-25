import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../router/tms_routes.dart';
import 'design_tokens.dart';
import 'design_widgets.dart';
import 'tms_icons.dart';

class QuickCreate extends StatelessWidget {
  const QuickCreate({super.key});
  static const actions = [
    (
      'common.new_task',
      TmsIcons.checkSquare,
      DesignColor.purple,
      TmsRoute.newTask,
    ),
    (
      'quick_create.log_report',
      TmsIcons.report,
      DesignColor.teal,
      TmsRoute.reports,
    ),
    ('common.clock_in', TmsIcons.login, DesignColor.blue, TmsRoute.attendance),
    ('common.new_note', TmsIcons.note, DesignColor.amber, TmsRoute.journal),
    (
      'quick_create.invite_guest',
      TmsIcons.addPerson,
      DesignColor.green,
      TmsRoute.visitors,
    ),
    (
      'common.send_a_card',
      TmsIcons.birthday,
      DesignColor.rose,
      TmsRoute.birthdays,
    ),
  ];

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    heroTag: null,
    tooltip: context.tr('quick_create.quick_create'),
    backgroundColor: DesignColor.purple,
    foregroundColor: DesignColor.ink,
    onPressed: () async {
      final route = await showGeneralDialog<TmsRoute>(
        context: context,
        barrierDismissible: true,
        barrierLabel: context.tr('quick_create.close_quick_create'),
        barrierColor: const Color(0xdd080910),
        transitionDuration: DesignMotion.duration(context, DesignMotion.page),
        transitionBuilder: (_, progress, _, child) =>
            FadeTransition(opacity: progress, child: child),
        pageBuilder: (context, _, _) => const _QuickCreateMenu(),
      );
      if (context.mounted && route != null) route.open(context);
    },
    child: const Icon(TmsIcons.add, size: 32),
  );
}

class _QuickCreateMenu extends StatelessWidget {
  const _QuickCreateMenu();
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.bottomRight,
      child: Material(
        color: Colors.transparent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 22, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr('quick_create.quick_create'),
                  style: TextStyle(
                    color: Color(0xffd2cefd),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr('quick_create.whats_the_move_chioma'),
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.1,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (var i = QuickCreate.actions.length - 1; i >= 0; i--)
                DesignEntrance(
                  order: i,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: [0, 16, 28, 32, 28, 16][i].toDouble(),
                    ),
                    child: _QuickAction(action: QuickCreate.actions[i]),
                  ),
                ),
              FloatingActionButton(
                heroTag: null,
                tooltip: context.tr('quick_create.close_quick_create'),
                backgroundColor: DesignColor.purple,
                onPressed: () => Navigator.pop(context),
                child: const Icon(TmsIcons.close, color: DesignColor.ink),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.action});
  final (String, IconData, Color, TmsRoute) action;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => Navigator.pop(context, action.$4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Text(
          context.tr(action.$1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: action.$3,
          foregroundColor: DesignColor.ink,
          child: Icon(action.$2),
        ),
      ],
    ),
  );
}
