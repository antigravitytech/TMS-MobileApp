part of 'auth_repository.dart';

class LiveAuthRepository implements AuthRepository {
  LiveAuthRepository(this._network, this._tokens);

  final NetworkCallsRepository _network;
  final TokenUtils _tokens;
  // Requests may finish after sign-out or after a different login has committed.
  int _sessionRevision = 0;

  @override
  ({String email, String password}) get initialCredentials =>
      (email: '', password: '');

  @override
  Future<Account> signIn(
    String email,
    String password,
    bool remember,
    Duration delay,
  ) => _startSession('/auth/login/', {
    'email': email,
    'password': password,
    'remember_me': remember,
  });

  Future<Account> signup(Map<String, Object?> fields) =>
      _startSession('/auth/signup/', fields);

  Future<Account> _startSession(
    String path,
    Map<String, Object?> fields,
  ) async {
    final revision = _sessionRevision;
    final response = await _network.post<Map<String, dynamic>>(
      path,
      data: fields,
      withToken: false,
    );
    _checkSessionRevision(revision);
    final body = accountPayload(response);
    final token = body['access_token'];
    final tokenType = body['token_type'];
    if (token is! String ||
        token.isEmpty ||
        RegExp(r'\s').hasMatch(token) ||
        tokenType is! String ||
        tokenType.toLowerCase() != 'bearer') {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
    final user = _decodeAccount(body['user']);
    final commitRevision = ++_sessionRevision;
    await _accessStorage(() => _tokens.storeTokens(accessToken: token));
    _checkSessionRevision(commitRevision);
    return user;
  }

  @override
  Future<Account?> restore() async {
    final revision = _sessionRevision;
    final token = await _accessStorage(_tokens.getAccessToken);
    _checkSessionRevision(revision);
    if (token == null) return null;
    try {
      final response = await _network.get<Map<String, dynamic>>(
        '/auth/check-auth/',
      );
      _checkSessionRevision(revision);
      return _decodeAccount(accountPayload(response));
    } on AccountFailure catch (error) {
      if (error.type != NetworkFailureType.unauthorized) rethrow;
      final expiredRevision = ++_sessionRevision;
      await _accessStorage(_tokens.clearTokens);
      _checkSessionRevision(expiredRevision);
      return null;
    }
  }

  Future<List<AccountWorkspace>> workspaces() async {
    final revision = _sessionRevision;
    final workspaces = <AccountWorkspace>[];
    var lastPage = 1;
    for (var page = 1; page <= lastPage; page++) {
      final response = await _network.get<Map<String, dynamic>>(
        '/workspace/list-workspaces/',
        queryParameters: {'page': page, 'page_size': 100},
      );
      _checkSessionRevision(revision);
      final result = accountPayload(response);
      final pageCount = result['total_pages'];
      if (pageCount is! int || pageCount < 0) {
        throw const AccountFailure(NetworkFailureType.invalidResponse);
      }
      // Later pages can shrink the original range as workspaces disappear.
      if (page == 1 || pageCount < lastPage) lastPage = pageCount;
      final entries = _decode(
        () => (result['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(AccountWorkspace.fromJson)
            .where((workspace) => workspace.kind != 'specials')
            .toList(),
      );
      workspaces.addAll(entries);
    }
    return workspaces;
  }

  Future<void> createWorkspace(
    String name,
    String kind,
    Map<String, Object?> setup,
  ) async {
    await _action('/workspace/create-workspace/', {
      'name': name,
      'kind': kind,
      if (setup.isNotEmpty) 'setup': setup,
    }, authenticated: true);
  }

  Future<({Uri url, String state})> startOAuth(String provider) async {
    final data = accountPayload(
      await _network.get<Map<String, dynamic>>(
        '${_oauthPath(provider)}/start/',
        withToken: false,
      ),
    );
    final url = data['authorization_url'];
    final state = data['state'];
    final authorizationUri = url is String ? Uri.tryParse(url) : null;
    if (authorizationUri == null ||
        authorizationUri.scheme != 'https' ||
        authorizationUri.host.isEmpty ||
        state is! String ||
        state.trim().isEmpty) {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
    return (url: authorizationUri, state: state);
  }

  Future<Account> finishOAuth(
    String provider,
    String code,
    String state,
    Uri redirect,
  ) async => _startSession('${_oauthPath(provider)}/callback/', {
    'code': code,
    'state': state,
    'redirect_uri': redirect.toString(),
  });

  Future<void> requestReset(String email) =>
      _publicAction('/auth/request-password-reset/', {'email': email});

  Future<void> confirmReset(String token, String password) => _publicAction(
    '/auth/confirm-password-reset/',
    {'token': token, 'new_password': password},
  );

  Future<void> resendVerification(String email) =>
      _publicAction('/auth/resend-verification/', {'email': email});

  Future<void> verifyEmail({String? email, String? code, String? token}) async {
    final Map<String, Object?> fields;
    if (token != null &&
        token.trim().isNotEmpty &&
        email == null &&
        code == null) {
      fields = {'token': token};
    } else if (token == null &&
        email != null &&
        email.trim().isNotEmpty &&
        code != null &&
        RegExp(r'^\d{6}$').hasMatch(code)) {
      fields = {'email': email, 'code': code};
    } else {
      throw const AccountFailure(NetworkFailureType.validation);
    }
    await _publicAction('/auth/verify-email/', fields);
  }

  Future<void> requestEmailChange(String email, String password) => _action(
    '/auth/request-email-change/',
    {'new_email': email, 'password': password},
    authenticated: true,
  );

  Future<void> confirmEmailChange(String token) =>
      _publicAction('/auth/confirm-email-change/', {'token': token});

  Future<void> changePassword(String current, String replacement) => _action(
    '/auth/update-password/',
    {'current_password': current, 'new_password': replacement},
    authenticated: true,
  );

  Future<void> unsubscribe(String email) =>
      _publicAction('/auth/unsubscribe/', {'email': email});

  Future<void> _publicAction(String path, Map<String, Object?> fields) =>
      _action(path, fields);

  Future<void> _action(
    String path,
    Map<String, Object?> fields, {
    bool authenticated = false,
  }) async {
    final revision = _sessionRevision;
    final response = await _network.post<Map<String, dynamic>>(
      path,
      data: fields,
      withToken: authenticated,
    );
    if (authenticated) _checkSessionRevision(revision);
    accountPayload(response);
  }

  @override
  Future<void> signOut() {
    _sessionRevision++;
    return _accessStorage(_tokens.clearTokens);
  }

  String _oauthPath(String provider) => switch (provider) {
    'google' || 'microsoft' => '/auth/oauth/$provider',
    _ => throw const AccountFailure(NetworkFailureType.validation),
  };

  void _checkSessionRevision(int revision) {
    if (revision != _sessionRevision) {
      throw const AccountFailure(NetworkFailureType.cancelled);
    }
  }

  T _decode<T>(T Function() decode) {
    try {
      return decode();
    } on TypeError {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
  }

  Account _decodeAccount(Object? body) {
    final account = _decode(
      () => Account.fromJson(body as Map<String, dynamic>),
    );
    if (account.id.trim().isEmpty || account.email.trim().isEmpty) {
      throw const AccountFailure(NetworkFailureType.invalidResponse);
    }
    return account;
  }

  Future<T> _accessStorage<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on TokenStorageException {
      throw const AccountFailure(NetworkFailureType.tokenStorage);
    }
  }
}
