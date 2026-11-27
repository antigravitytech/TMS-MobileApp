import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';

part 'widgets/project_widgets.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  static const filters = [
    'common.all_projects',
    'projects.off_track',
    'projects.at_risk',
    'projects.on_track',
  ];
  final projects = <(String, String, int, int, String)>[
    (
      'Customer Portal Revamp',
      'projects.off_track',
      36,
      0,
      'projects.thu_26_nov',
    ),
    (
      'POS rollout — Lagos, Abuja, Kano',
      'projects.off_track',
      40,
      40,
      'projects.mon_30_nov',
    ),
    ('Mobile App Launch', 'projects.at_risk', 25, 0, 'projects.fri_27_nov'),
    ('Q4 hiring plan', 'projects.at_risk', 62, 0, 'projects.mon_30_nov'),
  ];
  int filter = 0;
  final expanded = <String>{'Customer Portal Revamp'};
  Future<void> addProject() async {
    String name = '';
    final result = await designSheet<String>(
      context,
      title: context.tr('projects.new_project'),
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            DesignField(
              label: context.tr('projects.project_name'),
              onChanged: (value) => update(() => name = value),
            ),
            DesignButton(
              context.tr('projects.create_project'),
              onPressed: name.trim().isEmpty
                  ? null
                  : () => Navigator.pop(sheet, name.trim()),
            ),
          ],
        ),
      ),
    );
    if (mounted && result != null) {
      setState(() {
        projects.add((result, 'projects.on_track', 0, 0, 'projects.not_set'));
        filter = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) => DesignPage(
    title: context.tr('common.projects'),
    actions: [
      SizedBox(
        width: 48,
        height: 48,
        child: IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: DesignColor.purple,
            foregroundColor: DesignColor.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          tooltip: context.tr('projects.new_project'),
          icon: const Icon(TmsIcons.add, size: 24),
          onPressed: addProject,
        ),
      ),
    ],
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            for (var i = 0; i < 3; i++)
              _ProjectFilter(
                label: i == 0
                    ? context.tr('common.all')
                    : context.tr(filters[i]),
                count: projects
                    .where((p) => i == 0 || p.$2 == filters[i])
                    .length,
                color: [
                  const Color(0xffc4bdf6),
                  DesignColor.red,
                  DesignColor.amber,
                ][i],
                selected: filter == i,
                onTap: () => setState(() => filter = i),
              ),
          ],
        ),
      ),
      for (final (name, status, done, accepted, _) in projects.where(
        (p) => filter == 0 || p.$2 == filters[filter],
      ))
        DesignCard(
          key: ValueKey(name),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 9,
            children: [
              InkWell(
                onTap: () => setState(() {
                  final wasOpen = expanded.contains(name);
                  expanded.clear();
                  if (!wasOpen) expanded.add(name);
                }),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (status == 'projects.off_track'
                                        ? DesignColor.red
                                        : DesignColor.amber)
                                    .withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: status == 'projects.off_track'
                                      ? DesignColor.red
                                      : DesignColor.amber,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.tr(status),
                                style: TextStyle(
                                  color: status == 'projects.off_track'
                                      ? DesignColor.red
                                      : DesignColor.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: context.raised,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            context.tr(
                              name.startsWith('POS')
                                  ? 'projects.advanced'
                                  : 'projects.simple',
                            ),
                            style: TextStyle(
                              color: context.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        DesignAvatar(
                          name.startsWith('POS') ? 'IM' : 'CO',
                          size: 28,
                          color: name.startsWith('POS')
                              ? DesignColor.blue
                              : const Color(0xffc4bdf6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        'projects.promise_summary',
                        namedArgs: {
                          'milestone': context.tr(
                            name.startsWith('POS')
                                ? 'projects.abuja_live'
                                : name == 'Mobile App Launch'
                                ? 'projects.beta'
                                : 'projects.discovery',
                          ),
                          'days': name.startsWith('POS')
                              ? '11'
                              : name == 'Mobile App Launch'
                              ? '2'
                              : '19',
                        },
                      ),
                      style: TextStyle(color: context.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                spacing: 14,
                children: [
                  Expanded(
                    child: _Metric(
                      context.tr('projects.tasks_done'),
                      done,
                      DesignColor.purple,
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      context.tr('projects.accepted'),
                      accepted,
                      DesignColor.teal,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: DesignMotion.duration(context, DesignMotion.page),
                curve: DesignMotion.curve,
                child: expanded.contains(name)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 10,
                        children: [
                          Divider(height: 18, color: context.outline),
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: DesignColor.blue.withValues(
                                    alpha: .13,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: DesignColor.blue.withValues(
                                      alpha: .3,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  TmsIcons.flag,
                                  size: 20,
                                  color: DesignColor.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr(
                                        name.startsWith('POS')
                                            ? 'projects.abuja_milestone'
                                            : 'projects.discovery_milestone',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      context.tr(
                                        name.startsWith('POS')
                                            ? 'projects.abuja_forecast'
                                            : 'projects.discovery_forecast',
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            spacing: 6,
                            children: [
                              for (final (label, route) in [
                                (context.tr('common.tasks'), TmsRoute.tasks),
                                (context.tr('common.files'), TmsRoute.files),
                                (
                                  context.tr('common.chat'),
                                  TmsRoute.conversation,
                                ),
                              ])
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => route.open(context),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: context.raised,
                                      foregroundColor: context.foreground,
                                      minimumSize: const Size(0, 48),
                                      padding: EdgeInsets.zero,
                                      side: BorderSide(color: context.outline),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
