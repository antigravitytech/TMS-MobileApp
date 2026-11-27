import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../application/local_workspaces.dart';
import '../domain/workspace_kind.dart';
import 'widgets/workspace_ui.dart';

part 'widgets/workspace_tool_groups.dart';

typedef _Tool = (String, IconData, Color, Object);

class WorkspaceTools extends ConsumerWidget {
  const WorkspaceTools({super.key, required this.kind});
  final WorkspaceKind kind;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = switch (kind) {
      WorkspaceKind.business => _business,
      WorkspaceKind.family => _family,
      WorkspaceKind.individual => _individual,
      _ => _special,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (heading, items) in groups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 10),
            child: Text(
              context.tr(heading).toUpperCase(),
              style: TextStyle(
                color: context.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, bounds) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (label, icon, color, destination) in items)
                  SizedBox(
                    width: (bounds.maxWidth - 20) / 3,
                    child: DesignCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 12,
                      ),
                      onTap: () async {
                        if (destination is WorkspaceKind) {
                          await saveWorkspaceChange(context, () async {
                            await ref
                                .read(localWorkspacesProvider.notifier)
                                .select(destination.name);
                            if (context.mounted) TmsRoute.home.reset(context);
                          });
                        } else if (destination is WorkspaceSection) {
                          destination.open(context);
                        } else if (destination is TmsRoute) {
                          destination.open(context);
                        }
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 78),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            Text(
                              context.tr(label),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
