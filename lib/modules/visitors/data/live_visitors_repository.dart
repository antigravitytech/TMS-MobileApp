part of 'visitors_repository.dart';

typedef _Json = Map<String, dynamic>;

/// Guest passes over `/visitor`.
class LiveVisitorsRepository implements VisitorsRepository {
  LiveVisitorsRepository(this._network, {this.workspace});

  final NetworkCallsRepository _network;
  final AccountWorkspace? workspace;

  /// The desk new invitations go to, looked up the first time.
  String? _desk;

  @override
  Duration? get polling => const Duration(seconds: 8);

  String get _ws {
    final id = workspace?.id;
    if (id == null) throw const AccountFailure(NetworkFailureType.unauthorized);
    return Uri.encodeComponent(id);
  }

  @override
  Future<List<VisitPass>> passes() async {
    final rows = accountPayload(
      await _network.get<List<dynamic>>(
        '/visitor/list-passes/$_ws/',
        queryParameters: {'scope': 'mine'},
      ),
    );
    return _parse(() => [for (final p in rows.cast<_Json>()) _pass(p)]);
  }

  @override
  Future<VisitPass> invite(GuestInvite invite) async {
    final ws = _ws;
    final desk = _desk ??= await _defaultDesk(ws);
    final body = _payload(
      await _network.post<_Json>(
        '/visitor/create-pass/$ws/',
        data: {
          'guest_name': invite.name,
          'party_size': 1,
          if (invite.purpose.isNotEmpty) 'purpose': invite.purpose,
          'desk_id': desk,
          'valid_on': DateFormat('yyyy-MM-dd').format(invite.day),
          'arrived': false,
        },
      ),
    );
    return _parse(() => _pass(body));
  }

  Future<String> _defaultDesk(String ws) async {
    final desks = accountPayload(
      await _network.get<List<dynamic>>('/visitor/list-desks/$ws/'),
    );
    return _parse(() {
      final all = desks.cast<_Json>();
      final desk =
          all.where((d) => d['is_default'] == true).firstOrNull ?? all.first;
      return desk['id'] as String;
    });
  }

  @override
  Future<VisitPass> answer(VisitPass pass, GuestAnswer answer) async {
    final body = _payload(
      await _network.post<_Json>(
        '/visitor/pass-action/$_ws/${Uri.encodeComponent(pass.id)}/',
        data: {
          'action': answer.action,
          if (answer == GuestAnswer.hold) 'minutes': 10,
        },
      ),
    );
    return _parse(() => _pass(body));
  }

  /// The payload, or [VisitorRefused] with the server's sentence when an
  /// action was refused (403, 404 or 409).
  static T _payload<T>(ApiResponse<T> response) {
    final body = response.response?.data;
    if (!response.isSuccess &&
        const {403, 404, 409}.contains(response.statusCode) &&
        body is Map &&
        body['detail'] is String) {
      throw VisitorRefused(body['detail'] as String);
    }
    return accountPayload(response);
  }

  static VisitPass _pass(_Json p) => VisitPass(
    id: p['id'] as String,
    code: p['code'] as String,
    guest: p['guest_name'] as String,
    purpose: p['purpose'] as String? ?? '',
    validOn: DateTime.parse(p['valid_on'] as String),
    status: p['status'] as String,
    arrivedAt: DateTime.tryParse(p['arrived_at'] as String? ?? '')?.toLocal(),
    canAnswer: p['can_answer'] == true,
  );

  static T _parse<T>(T Function() read) {
    try {
      return read();
    } on TypeError {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    } on FormatException {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    } on StateError {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
  }
}
