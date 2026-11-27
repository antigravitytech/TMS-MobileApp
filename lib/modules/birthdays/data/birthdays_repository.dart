import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/domain/account.dart';
import '../../workspace/application/workspace_preview.dart';
import '../domain/birthday.dart';

part 'live_birthdays_repository.dart';
part 'mock_birthdays_repository.dart';

final birthdaysRepositoryProvider = Provider<BirthdaysRepository>((ref) {
  if (!ref.watch(environmentProvider).isLive) {
    return MockBirthdaysRepository(ref.read(workspacePreviewProvider));
  }
  return LiveBirthdaysRepository(ref.watch(networkCallsRepositoryProvider));
});

abstract class BirthdaysRepository {
  /// Colleagues' birthdays, my own calendar entries and today's card count.
  Future<BirthdayCalendar> load(String workspaceId);

  /// Sends [person] a birthday card in our direct message.
  Future<void> sendWish(
    BirthdayPerson person, {
    required String message,
    required String theme,
    required String sticker,
  });

  /// Toggles this year's "wished" mark on a calendar entry.
  Future<BirthdayEntry> celebrate(BirthdayEntry entry);
}
