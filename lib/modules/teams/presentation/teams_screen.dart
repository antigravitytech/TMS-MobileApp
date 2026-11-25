import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../../shared/design/tms_icons.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});
  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  final expanded = <String>{'Tech Team'};
  static const teams = [
    (
      'Tech Team',
      'Chioma Okafor',
      64,
      [
        ('TB', 'Tunde Bakare', 3),
        ('AE', 'Amaka Eze', 2),
        ('DM', 'David Martins', 4),
        ('SJ', 'Sarah Johnson', 1),
      ],
    ),
    (
      'Product Team',
      'Ibrahim Musa',
      82,
      [('NA', 'Ngozi Adebayo', 2), ('IM', 'Ibrahim Musa', 1)],
    ),
  ];
  @override
  Widget build(BuildContext context) => DesignPage(
    title: context.tr('teams.teams'),
    subtitle: context.tr(
      'teams.workspace_count',
      namedArgs: {
        'count': 2.toString(),
        'workspace': ref.watch(workspacePreviewProvider).workspace,
      },
    ),
    children: [
      for (final (name, lead, progress, members) in teams)
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              DesignTile(
                title: name,
                subtitle: context.plural(
                  'teams.lead_members',
                  members.length,
                  name: 'count',
                  namedArgs: {'lead': lead},
                ),
                icon: TmsIcons.groups,
                trailing: Icon(
                  expanded.contains(name)
                      ? TmsIcons.chevronUp
                      : TmsIcons.chevronDown,
                ),
                onTap: () => setState(() {
                  if (!expanded.add(name)) expanded.remove(name);
                }),
              ),
              DesignLabel(
                context.tr(
                  'teams.this_week_progress_complete',
                  namedArgs: {'progress': progress.toString()},
                ),
              ),
              LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6,
                backgroundColor: context.raised,
                color: DesignColor.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              AnimatedSize(
                duration: DesignMotion.duration(context, DesignMotion.page),
                curve: DesignMotion.curve,
                child: expanded.contains(name)
                    ? Column(
                        children: [
                          for (final (initials, person, tasks) in members)
                            DesignTile(
                              title: person,
                              subtitle: context.plural(
                                'teams.open_tasks',
                                tasks,
                                name: 'count',
                              ),
                              leading: DesignAvatar(initials, size: 34),
                              onTap: () => TmsRoute.conversation.open(context),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
    ],
  );
}
