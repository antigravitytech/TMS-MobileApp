part of '../search_screen.dart';

/// Where each result leads. Opening a result remembers the search.
extension on _SearchScreenState {
  void _remember() => ref.read(recentSearchesProvider.notifier).add(_query);

  /// The task found is complete enough to open without another request.
  void _openTask(SearchTask hit) {
    _remember();
    ref.read(openedTaskProvider.notifier).open(hit.task);
    TmsRoute.task.open(context);
  }

  void _openProject() {
    _remember();
    TmsRoute.projects.open(context);
  }

  /// Opens a direct message; the preview's people open its reference chat.
  Future<void> _openPerson(SearchPerson person) async {
    _remember();
    if (person.id.isEmpty) return TmsRoute.conversation.open(context);
    try {
      final inbox = await ref.read(chatDirectoryProvider.future);
      final row = await ref.read(chatRepositoryProvider).start(inbox, [
        ChatContact(
          kitPerson(person.name).$1,
          'a1',
          person.name,
          person.jobTitle,
          false,
          id: person.id,
        ),
      ], group: false);
      if (!mounted) return;
      ref.read(chatSessionProvider(inbox.workspace).notifier).open(row);
      ref.invalidate(chatDirectoryProvider);
      TmsRoute.conversation.open(context);
    } catch (error) {
      if (mounted) designToast(context, chatErrorMessage(context, error));
    }
  }
}
