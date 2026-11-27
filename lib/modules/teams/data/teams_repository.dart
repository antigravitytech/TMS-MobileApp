import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';
import '../../workspace/application/workspace_preview.dart';
import '../domain/team.dart';

part 'live_teams_repository.dart';
part 'mock_teams_repository.dart';

final teamsRepositoryProvider = Provider<TeamsRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) {
    return MockTeamsRepository(ref.read(workspacePreviewProvider));
  }
  return LiveTeamsRepository(
    ref.watch(networkCallsRepositoryProvider),
    workspace: ref.watch(activeLiveWorkspaceProvider),
  );
});

abstract class TeamsRepository {
  Future<TeamDirectory> teams();

  /// A team's members, loaded when its card is opened.
  Future<List<TeamMember>> members(TeamItem team);
}
