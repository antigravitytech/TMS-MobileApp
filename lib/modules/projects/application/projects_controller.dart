import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../../tasks/application/tasks_controller.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';

/// The project list. A new project is added here without reloading it.
final projectsProvider =
    AsyncNotifierProvider.autoDispose<ProjectsController, List<ProjectItem>>(
      ProjectsController.new,
      retry: (_, _) => null,
    );

class ProjectsController extends AsyncNotifier<List<ProjectItem>> {
  @override
  Future<List<ProjectItem>> build() =>
      guardSession(ref, () => ref.watch(projectsRepositoryProvider).list());

  Future<ProjectItem> create(String name) async {
    final project = await guardSession(
      ref,
      () => ref.read(projectsRepositoryProvider).create(name),
    );
    if (ref.mounted) {
      state = AsyncData([...?state.value, project]);
      // New task's project picker should offer it.
      ref.invalidate(taskOptionsProvider);
    }
    return project;
  }
}
