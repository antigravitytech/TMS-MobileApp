import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';

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
      71,
      'projects.thu_26_nov',
    ),
    ('Mobile App Launch', 'projects.at_risk', 25, 83, 'projects.fri_27_nov'),
    ('Q4 hiring plan', 'projects.on_track', 62, 91, 'projects.mon_30_nov'),
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
      DesignIcon(
        icon: TmsIcons.add,
        label: context.tr('projects.new_project'),
        onPressed: addProject,
      ),
    ],
    children: [
      DesignChoices(
        items: filters.map(context.tr).toList(),
        selected: filter,
        onChanged: (i) => setState(() => filter = i),
      ),
      for (final (name, status, done, accepted, due) in projects.where(
        (p) => filter == 0 || p.$2 == filters[filter],
      ))
        DesignCard(
          key: ValueKey(name),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 9,
            children: [
              DesignTile(
                title: name,
                subtitle: context.tr(
                  'projects.next_promise_due',
                  namedArgs: {'due': context.tr(due)},
                ),
                icon: TmsIcons.work,
                trailing: AnimatedRotation(
                  turns: expanded.contains(name) ? .5 : 0,
                  duration: DesignMotion.duration(context, DesignMotion.fast),
                  child: const Icon(TmsIcons.chevronDown),
                ),
                onTap: () => setState(() {
                  if (!expanded.add(name)) expanded.remove(name);
                }),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: DesignPill(
                  context.tr(status),
                  color: status == 'projects.on_track'
                      ? DesignColor.green
                      : status == 'projects.at_risk'
                      ? DesignColor.amber
                      : DesignColor.rose,
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
                      DesignColor.green,
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
                          DesignLabel(
                            context.tr(
                              'projects.milestone_promised_due',
                              namedArgs: {'due': context.tr(due)},
                            ),
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
                                  child: DesignButton(
                                    label,
                                    secondary: true,
                                    onPressed: () => route.open(context),
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

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 6,
    children: [
      DesignLabel(label),
      Text(
        '$value%',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
      ),
      LinearProgressIndicator(
        value: value / 100,
        minHeight: 6,
        color: color,
        backgroundColor: context.raised,
        borderRadius: BorderRadius.circular(8),
      ),
    ],
  );
}
