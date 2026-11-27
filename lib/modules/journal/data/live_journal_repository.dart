part of 'journal_repository.dart';

typedef _Json = Map<String, dynamic>;

/// My private journal over `/note`.
class LiveJournalRepository implements JournalRepository {
  const LiveJournalRepository(this._network, {this.workspace});

  final NetworkCallsRepository _network;
  final AccountWorkspace? workspace;

  String get _ws {
    final id = workspace?.id;
    if (id == null) throw const AccountFailure(NetworkFailureType.unauthorized);
    return Uri.encodeComponent(id);
  }

  @override
  Future<List<JournalNote>> notes() async {
    final page = accountPayload(
      await _network.get<_Json>(
        '/note/list-notes/$_ws/',
        queryParameters: {'state': 'active', 'page_size': 100},
      ),
    );
    return _parse(
      () => [for (final n in (page['items'] as List).cast<_Json>()) _note(n)],
    );
  }

  @override
  Future<JournalNote> create(NoteDraft draft) async {
    final body = accountPayload(
      await _network.post<_Json>(
        '/note/create-note/$_ws/',
        data: {
          'title': draft.title,
          'body': draft.body,
          'color': draft.color,
          if (draft.remindAt case final at?)
            'remind_at': at.toUtc().toIso8601String(),
        },
      ),
    );
    return _parse(() => _note(body));
  }

  @override
  Future<JournalNote> pin(JournalNote note, bool pinned) async {
    final body = accountPayload(
      await _network.post<_Json>(
        '/note/pin-note/${Uri.encodeComponent(note.id)}/',
        data: {'pinned': pinned},
      ),
    );
    return _parse(() => _note(body));
  }

  static JournalNote _note(_Json n) {
    final color = n['color'] as String? ?? 'amber';
    return JournalNote(
      id: n['id'] as String,
      title: n['title'] as String? ?? '',
      body: n['body'] as String? ?? '',
      color: noteColors.contains(color) ? color : 'slate',
      pinned: n['pinned'] == true,
      remindAt: n['reminder_state'] == 'done'
          ? null
          : DateTime.tryParse(n['remind_at'] as String? ?? '')?.toLocal(),
      updatedAt: DateTime.parse(n['updated_at'] as String).toLocal(),
    );
  }

  static T _parse<T>(T Function() read) {
    try {
      return read();
    } on TypeError {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    } on FormatException {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
  }
}
