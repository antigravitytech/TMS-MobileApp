import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/shared_pref_service.dart';
import '../../authentication/application/account_session.dart';
import '../data/search_repository.dart';
import '../domain/search.dart';

/// Results for one query. The screen debounces typing, so each settled query
/// loads once; a superseded query's result is dropped with its provider.
final searchResultsProvider = FutureProvider.autoDispose
    .family<SearchResults, String>(
      (ref, query) => guardSession(
        ref,
        () => ref.watch(searchRepositoryProvider).search(query),
      ),
      retry: (_, _) => null,
    );

/// "Jump to" projects shown before anything is typed.
final searchFeaturedProvider = FutureProvider.autoDispose<List<SearchProject>>(
  (ref) => ref.watch(searchRepositoryProvider).featured(),
  retry: (_, _) => null,
);

/// Recent searches, newest first, kept on this phone.
final recentSearchesProvider =
    NotifierProvider.autoDispose<RecentSearches, List<String>>(
      RecentSearches.new,
    );

class RecentSearches extends Notifier<List<String>> {
  static const key = 'search.recent';
  static const limit = 5;

  @override
  List<String> build() {
    if (SharedPreferencesService.containsKey(key: key)) {
      return SharedPreferencesService.getStringList(key: key) ?? const [];
    }
    return ref.watch(searchRepositoryProvider).suggestedRecent;
  }

  /// Remembers a search the person acted on.
  Future<void> add(String query) async {
    final term = query.trim();
    if (term.isEmpty) return;
    state = [
      term,
      ...state.where((q) => q.toLowerCase() != term.toLowerCase()),
    ].take(limit).toList();
    await SharedPreferencesService.setStringList(key: key, value: state);
  }
}
