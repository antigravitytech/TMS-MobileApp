import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../data/visitors_repository.dart';
import '../domain/visit_pass.dart';

/// My guests, refreshed on the repository's interval. Inviting and
/// answering update the list with the server's copy.
final visitorsProvider =
    AsyncNotifierProvider.autoDispose<VisitorsController, List<VisitPass>>(
      VisitorsController.new,
      retry: (_, _) => null,
    );

class VisitorsController extends AsyncNotifier<List<VisitPass>> {
  VisitorsRepository get _repository => ref.read(visitorsRepositoryProvider);

  @override
  Future<List<VisitPass>> build() async {
    final repository = ref.watch(visitorsRepositoryProvider);
    if (repository.polling case final every?) {
      final timer = Timer.periodic(every, (_) => _poll());
      ref.onDispose(timer.cancel);
    }
    return guardSession(ref, repository.passes);
  }

  Future<void> _poll() async {
    if (state.isLoading) return;
    try {
      final passes = await _repository.passes();
      if (ref.mounted) state = AsyncData(passes);
    } catch (_) {
      // The next poll tries again.
    }
  }

  Future<VisitPass> invite(GuestInvite invite) async {
    final pass = await guardSession(ref, () => _repository.invite(invite));
    if (ref.mounted) state = AsyncData([pass, ...?state.value]);
    return pass;
  }

  Future<void> answer(VisitPass pass, GuestAnswer answer) async {
    final updated = await guardSession(
      ref,
      () => _repository.answer(pass, answer),
    );
    if (!ref.mounted) return;
    state = AsyncData([
      for (final p in state.value ?? const <VisitPass>[])
        p.id == updated.id ? updated : p,
    ]);
  }
}
