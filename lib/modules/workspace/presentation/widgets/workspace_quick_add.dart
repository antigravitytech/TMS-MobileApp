import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../router/tms_routes.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../domain/workspace_kind.dart';
import 'workspace_quick_add_actions.dart';
import 'workspace_ui.dart';

class WorkspaceQuickAdd extends StatelessWidget {
  const WorkspaceQuickAdd({super.key, required this.kind});
  final WorkspaceKind kind;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0xb09184d9),
          offset: Offset(0, 14),
          blurRadius: 30,
          spreadRadius: -6,
        ),
      ],
    ),
    child: SizedBox.square(
      dimension: 60,
      child: FloatingActionButton(
        heroTag: null,
        elevation: 0,
        backgroundColor: DesignColor.purple,
        foregroundColor: DesignColor.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tooltip: context.tr('workspace_quick_add.label'),
        onPressed: () => showGeneralDialog<void>(
          context: context,
          barrierDismissible: true,
          barrierLabel: context.tr('common.back'),
          barrierColor: Colors.transparent,
          transitionDuration: DesignMotion.duration(context, DesignMotion.page),
          transitionBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          pageBuilder: (_, _, _) => _WorkspaceAddMenu(kind: kind),
        ),
        child: const Icon(TmsIcons.add, size: 26),
      ),
    ),
  );
}

class _WorkspaceAddMenu extends StatelessWidget {
  const _WorkspaceAddMenu({required this.kind});
  final WorkspaceKind kind;
  @override
  Widget build(BuildContext context) {
    final family = kind == WorkspaceKind.family;
    final actions = quickAddActions(kind);
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xf510141b), Color(0xe510141b), Color(0xf53d3658)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Text(
                    context.tr('workspace_quick_add.label').toUpperCase(),
                    style: TextStyle(
                      color: context.lavender,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    context.tr(quickAddHeading(kind)),
                    style: const TextStyle(
                      fontSize: 38,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 9,
                        children: [
                          for (var i = 0; i < actions.length; i++)
                            DesignEntrance(
                              order: i,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  if (family &&
                                      actions[i].$4 ==
                                          WorkspaceSection.chores) {
                                    TmsRoute.familyTask.open(context);
                                  } else {
                                    actions[i].$4.open(context);
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xfff4f3ff),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        context.tr(actions[i].$1),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: DesignColor.ink,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Transform.rotate(
                                      angle: i.isEven ? .08 : -.08,
                                      child: Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: actions[i].$3,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Icon(
                                          actions[i].$2,
                                          color: DesignColor.ink,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          IconButton.filled(
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xfff4f3ff),
                              foregroundColor: DesignColor.ink,
                              fixedSize: const Size(60, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(TmsIcons.close),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
