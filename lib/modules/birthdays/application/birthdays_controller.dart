import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../../home/application/live_home.dart';
import '../data/birthdays_repository.dart';
import '../domain/birthday.dart';

/// The workspace whose birthdays are shown: the signed-in workspace when
/// live, the preview otherwise. Null while a live workspace is unknown.
final birthdayWorkspaceProvider = Provider<String?>((ref) {
  if (!ref.watch(environmentProvider).isLive) return 'preview';
  return ref.watch(activeLiveWorkspaceProvider)?.id;
});

final birthdaysProvider =
    AsyncNotifierProvider.autoDispose<BirthdaysController, BirthdayCalendar>(
      BirthdaysController.new,
      // Requests already retry in the network layer; show failures at once.
      retry: (_, _) => null,
    );

class BirthdaysController extends AsyncNotifier<BirthdayCalendar> {
  BirthdaysRepository get _repository => ref.read(birthdaysRepositoryProvider);

  @override
  Future<BirthdayCalendar> build() async {
    final workspace = ref.watch(birthdayWorkspaceProvider);
    final me = ref.watch(
      accountSessionProvider.select((account) => account?.id),
    );
    if (workspace == null) {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
    final calendar = await _withSession(() => _repository.load(workspace));
    // Today's list includes me; I'm greeted instead of shown as a colleague.
    return calendar.copyWith(
      members: [
        for (final person in calendar.members)
          if (person.id != me) person,
      ],
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Sends [person] a card in the style at [style] of [birthdayCardStyles].
  Future<void> sendWish(
    BirthdayPerson person, {
    required String message,
    required int style,
  }) async {
    final card = birthdayCardStyles[style % birthdayCardStyles.length];
    await _withSession(
      () => _repository.sendWish(
        person,
        message: message,
        theme: card.theme,
        sticker: card.sticker,
      ),
    );
    final current = state.value;
    if (!ref.mounted || current == null) return;
    state = AsyncData(
      current.copyWith(
        members: [
          for (final row in current.members)
            row.id == person.id ? row.wished() : row,
        ],
      ),
    );
  }

  /// Marks a calendar entry as wished for this year.
  Future<void> celebrate(BirthdayEntry entry) async {
    final saved = await _withSession(() => _repository.celebrate(entry));
    final current = state.value;
    if (!ref.mounted || current == null) return;
    state = AsyncData(
      current.copyWith(
        entries: [
          for (final row in current.entries) row.id == saved.id ? saved : row,
        ],
      ),
    );
  }

  Future<T> _withSession<T>(Future<T> Function() operation) async {
    final session = ref.read(accountSessionProvider.notifier);
    final accountId = ref.read(accountSessionProvider)?.id;
    try {
      return await operation();
    } on AccountFailure catch (error) {
      if (ref.mounted && accountId != null) {
        await session.expire(error, accountId: accountId);
      }
      rethrow;
    }
  }
}
