import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../application/local_workspaces.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import 'workspace_ui.dart';

class GigTemplates extends ConsumerStatefulWidget {
  const GigTemplates({super.key, required this.workspace});
  final LocalWorkspace workspace;
  @override
  ConsumerState<GigTemplates> createState() => _TemplatesState();
}

class _TemplatesState extends ConsumerState<GigTemplates> {
  static const icons = [
    TmsIcons.edit,
    TmsIcons.laptop,
    TmsIcons.calendar,
    TmsIcons.camera,
    TmsIcons.barChart,
    TmsIcons.shoppingCart,
    TmsIcons.work,
    TmsIcons.school,
    TmsIcons.chat,
    TmsIcons.heart,
  ];
  bool saving = false;
  Future<void> start(int i) async {
    if (saving) return;
    setState(() => saving = true);
    final key = 'studio.gigs.g$i';
    final record = WorkspaceRecord(
      id: '',
      section: WorkspaceSection.gigs,
      title: context.tr('$key.name'),
      notes: context.tr('$key.description'),
      status: WorkspaceStatus.inProgress,
      todos: {for (var j = 0; j < 3; j++) context.tr('$key.m$j'): false},
    );
    final ok = await saveWorkspaceChange(
      context,
      () => ref
          .read(localWorkspacesProvider.notifier)
          .saveRecord(widget.workspace.id, record),
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      designToast(
        context,
        context.tr('studio.gig_started', namedArgs: {'name': record.title}),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 10,
    children: [
      DesignTitle(context.tr('studio.start_gig')),
      SizedBox(
        height: 142,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: icons.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final tint = [
              DesignColor.purple,
              DesignColor.blue,
              DesignColor.teal,
              DesignColor.rose,
              DesignColor.amber,
              DesignColor.green,
            ][i % 6];
            return SizedBox(
              width: 170,
              child: DesignCard(
                onTap: saving ? null : () => start(i),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Icon(icons[i], color: tint),
                    Text(
                      context.tr('studio.gigs.g$i.name'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        context.tr('studio.gigs.g$i.description'),
                        style: TextStyle(fontSize: 12, color: context.muted),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      DesignTitle(context.tr('studio.running')),
    ],
  );
}
