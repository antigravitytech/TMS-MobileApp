import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';
import '../domain/project.dart';

part 'live_projects_repository.dart';
part 'mock_projects_repository.dart';

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) {
    final account = ref.read(accountSessionProvider);
    return MockProjectsRepository(
      account == null
          ? 'Chioma Okafor'
          : '${account.firstName} ${account.lastName}',
    );
  }
  return LiveProjectsRepository(
    ref.watch(networkCallsRepositoryProvider),
    workspace: ref.watch(activeLiveWorkspaceProvider),
  );
});

abstract class ProjectsRepository {
  /// Projects the user can see, with the figures their cards show.
  Future<List<ProjectItem>> list();

  /// Creates a project with just a name; the server fills the rest.
  Future<ProjectItem> create(String name);
}
