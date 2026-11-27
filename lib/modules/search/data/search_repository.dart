import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';
import '../../projects/data/projects_repository.dart';
import '../../projects/domain/project.dart';
import '../../tasks/data/tasks_repository.dart';
import '../../tasks/domain/task.dart';
import '../domain/search.dart';

part 'live_search_repository.dart';
part 'mock_search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) {
    return MockSearchRepository(ref.watch(tasksRepositoryProvider));
  }
  return LiveSearchRepository(
    ref.watch(networkCallsRepositoryProvider),
    workspace: ref.watch(activeLiveWorkspaceProvider),
  );
});

abstract class SearchRepository {
  /// Tasks, projects and people matching [query].
  Future<SearchResults> search(String query);

  /// What to show under "Jump to" before anything is typed.
  Future<List<SearchProject>> featured();

  /// Recent searches to offer the first time Search opens.
  List<String> get suggestedRecent;
}
