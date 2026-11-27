import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/account_session.dart';
import '../../authentication/data/auth_repository.dart';
import '../../authentication/domain/account.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../workspace/domain/workspace_setup.dart';

final workspaceEnrollmentProvider = Provider<WorkspaceEnrollment>(
  (ref) => WorkspaceEnrollment(
    ref.read(authRepositoryProvider) as LiveAuthRepository,
    ref.read(accountSessionProvider.notifier),
  ),
);

class WorkspaceEnrollment {
  const WorkspaceEnrollment(this._repository, this._session);

  final LiveAuthRepository _repository;
  final AccountSession _session;

  Future<void> create(WorkspaceSignup signup) async {
    try {
      await _repository.createWorkspace(
        signup.name,
        signup.backendKind,
        signup.details,
        subtype: signup.subtype,
      );
    } on AccountFailure catch (error) {
      await _session.expire(error);
      rethrow;
    }
  }
}

class WorkspaceSignup {
  const WorkspaceSignup(this.name, this.kind, this.setup);

  final String name;
  final WorkspaceKind kind;
  final WorkspaceSetup setup;

  String? get subtype =>
      WorkspaceKind.specials.contains(kind) ? kind.name : null;
  String get backendKind => subtype == null ? kind.name : 'specials';

  Map<String, Object?> get details {
    final eventDate = setup.date;
    return {
      if (subtype != null && setup.occasion.trim().isNotEmpty)
        'event_name': setup.occasion.trim(),
      if (subtype != null && eventDate != null)
        'event_date': eventDate.toIso8601String().split('T').first,
      if (setup.occupation != null) 'job': setup.occupation!.name,
      if (kind == WorkspaceKind.individual) 'has_clients': setup.withClients,
      if (setup.members.isNotEmpty)
        'members': [
          for (final member in setup.members)
            {
              'name': member.name,
              'type': switch (member.role) {
                HouseholdRole.coHead => 'co_head',
                HouseholdRole.staff => 'domestic_staff',
                _ => member.role.name,
              },
            },
        ],
    };
  }

  Map<String, Object?> get fields => {
    'workspace_name': name,
    'workspace_type': backendKind,
    'workspace_subtype': ?subtype,
    if (details case final setup when setup.isNotEmpty)
      'workspace_setup': setup,
  };
}
