import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';
import '../../workspace/application/workspace_preview.dart';
import '../domain/profile.dart';

part 'live_profile_repository.dart';
part 'mock_profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) {
    return MockProfileRepository(ref.read(workspacePreviewProvider));
  }
  return LiveProfileRepository(
    ref.watch(networkCallsRepositoryProvider),
    workspace: ref.watch(activeLiveWorkspaceProvider),
    account: ref.watch(accountSessionProvider),
  );
});

abstract class ProfileRepository {
  /// My profile in the active workspace.
  Future<ProfileSummary> summary();

  /// My current status alone, for screens that only show that.
  Future<Presence> presence();

  /// Sets my status and returns what the server stored.
  Future<Presence> setPresence(Presence presence);
}
