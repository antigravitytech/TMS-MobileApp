import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import 'local_workspaces.dart';

final focusTimerProvider = ChangeNotifierProvider.family<FocusTimer, String>(
  (ref, id) => FocusTimer(id, ref.read(localWorkspacesProvider.notifier)),
);

class FocusTimer extends ChangeNotifier {
  FocusTimer(this.id, this.directory);
  final String id;
  final LocalWorkspaces directory;
  final _clock = Stopwatch();
  String? client;
  bool saving = false;
  Duration get elapsed => _clock.elapsed;
  bool get running => _clock.isRunning;
  void choose(String? next) {
    if (running || saving) return;
    client = next;
    notifyListeners();
  }

  void start() {
    if (saving || running) return;
    _clock.start();
    notifyListeners();
  }

  Future<bool> finish(String title, String admin) async {
    if (!running || saving) return false;
    saving = true;
    _clock.stop();
    notifyListeners();
    final quarters = (_clock.elapsedMilliseconds / 900000).round();
    try {
      await directory.saveRecord(
        id,
        WorkspaceRecord(
          id: '',
          section: WorkspaceSection.time,
          title: title,
          person: client ?? admin,
          duration: (quarters < 1 ? 1 : quarters) * 15,
          date: DateTime.now(),
          flagged: client != null,
        ),
      );
      _clock.reset();
      return true;
    } catch (_) {
      _clock.start();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
