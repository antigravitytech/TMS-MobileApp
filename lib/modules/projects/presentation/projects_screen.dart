import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../../shared/kit/kit.dart';
import '../../tasks/presentation/tasks_screen.dart' show taskErrorMessage;
import '../application/projects_controller.dart';
import '../domain/project.dart';

part 'widgets/project_card.dart';
part 'widgets/project_widgets.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});
  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  /// The filter chips; null is "All".
  static const filters = [null, ProjectHealth.offTrack, ProjectHealth.atRisk];

  ProjectHealth? filter;
  String? expanded;

  Future<void> addProject() async {
    var name = '';
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
    if (!mounted || result == null) return;
    try {
      await ref.read(projectsProvider.notifier).create(result);
      if (mounted) setState(() => filter = null);
    } catch (error) {
      if (mounted) designToast(context, taskErrorMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(projectsProvider);
    final projects = async.value;
    return DesignPage(
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
            onPressed: projects == null ? null : addProject,
          ),
        ),
      ],
      children: [
        if (projects == null && !async.hasError)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (projects == null) ...[
          DesignEmpty(
            context.tr('projects.load_failed'),
            taskErrorMessage(context, async.error),
          ),
          DesignButton(
            context.tr('workspaces.try_again'),
            secondary: true,
            onPressed: () => ref.invalidate(projectsProvider),
          ),
        ] else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                for (final (i, health) in filters.indexed)
                  _ProjectFilter(
                    label: health == null
                        ? context.tr('common.all')
                        : context.tr('projects.${health.code}'),
                    count: projects
                        .where((p) => health == null || p.health == health)
                        .length,
                    color: [
                      const Color(0xffc4bdf6),
                      DesignColor.red,
                      DesignColor.amber,
                    ][i],
                    selected: filter == health,
                    onTap: () => setState(() => filter = health),
                  ),
              ],
            ),
          ),
          if (projects.isEmpty)
            DesignEmpty(
              context.tr('common.nothing_here'),
              context.tr('projects.empty'),
            ),
          for (final (i, project)
              in projects
                  .where((p) => filter == null || p.health == filter)
                  .indexed)
            _ProjectCard(
              key: ValueKey(project.id),
              project: project,
              // The first card starts open, as in the design.
              open: expanded == null ? i == 0 : expanded == project.id,
              onToggle: () => setState(
                () => expanded = expanded == project.id ? '' : project.id,
              ),
            ),
        ],
      ],
    );
  }
}
