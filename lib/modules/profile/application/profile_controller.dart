import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

/// My profile. Setting a status updates it in place.
final profileProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, ProfileSummary>(
      ProfileController.new,
      retry: (_, _) => null,
    );

class ProfileController extends AsyncNotifier<ProfileSummary> {
  @override
  Future<ProfileSummary> build() =>
      guardSession(ref, () => ref.watch(profileRepositoryProvider).summary());

  Future<void> setPresence(Presence presence) async {
    final stored = await guardSession(
      ref,
      () => ref.read(profileRepositoryProvider).setPresence(presence),
    );
    ref.invalidate(myPresenceProvider);
    final profile = state.value;
    if (ref.mounted && profile != null) {
      state = AsyncData(profile.withPresence(stored));
    }
  }
}

/// Just my status, for the More page header.
final myPresenceProvider = FutureProvider.autoDispose<Presence>(
  (ref) =>
      guardSession(ref, () => ref.watch(profileRepositoryProvider).presence()),
  retry: (_, _) => null,
);
