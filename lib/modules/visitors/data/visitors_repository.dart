import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';
import '../domain/visit_pass.dart';

part 'live_visitors_repository.dart';
part 'mock_visitors_repository.dart';

final visitorsRepositoryProvider = Provider<VisitorsRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) return MockVisitorsRepository();
  return LiveVisitorsRepository(
    ref.watch(networkCallsRepositoryProvider),
    workspace: ref.watch(activeLiveWorkspaceProvider),
  );
});

abstract class VisitorsRepository {
  /// How often the guest list should refresh while open; null when it only
  /// changes locally.
  Duration? get polling;

  /// My guests today and upcoming invitations.
  Future<List<VisitPass>> passes();
  Future<VisitPass> invite(GuestInvite invite);

  /// Admits, holds (for 10 minutes) or declines a waiting guest.
  Future<VisitPass> answer(VisitPass pass, GuestAnswer answer);
}
