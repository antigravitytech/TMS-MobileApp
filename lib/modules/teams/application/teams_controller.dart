import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../data/teams_repository.dart';
import '../domain/team.dart';

final teamsProvider = FutureProvider.autoDispose<TeamDirectory>(
  (ref) => guardSession(ref, () => ref.watch(teamsRepositoryProvider).teams()),
  retry: (_, _) => null,
);

/// A team's members, loaded the first time its card is opened and kept
/// while the screen is open.
final teamMembersProvider = FutureProvider.autoDispose
    .family<List<TeamMember>, TeamItem>(
      (ref, team) => guardSession(
        ref,
        () => ref.read(teamsRepositoryProvider).members(team),
      ),
      retry: (_, _) => null,
    );
