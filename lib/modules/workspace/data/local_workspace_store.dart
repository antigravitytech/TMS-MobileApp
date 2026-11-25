import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';

class LocalWorkspaceStore {
  const LocalWorkspaceStore(this._preferences);

  static const key = 'local_workspaces.v1';
  final SharedPreferences _preferences;

  bool get hasSavedDirectory => _preferences.containsKey(key);

  WorkspaceDirectory load() {
    final stored = _preferences.getString(key);
    if (stored != null) {
      return WorkspaceDirectory.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    }
    return WorkspaceDirectory(
      activeId: WorkspaceDirectory.companyId,
      workspaces: [
        for (final kind in WorkspaceKind.values.skip(1))
          LocalWorkspace(id: kind.name, kind: kind),
      ],
    );
  }

  Future<void> save(WorkspaceDirectory directory) async {
    if (!await _preferences.setString(key, jsonEncode(directory.toJson()))) {
      throw StateError('Workspace preferences write failed');
    }
  }
}
