import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DataSource { mock, live }

class AppEnvironment {
  const AppEnvironment({
    this.source = DataSource.mock,
    this.apiBaseUrl = '',
    this.oauthRedirectUri = '',
  });

  factory AppEnvironment.fromDefines() {
    const source = String.fromEnvironment('DATA_SOURCE', defaultValue: 'mock');
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const oauthRedirectUri = String.fromEnvironment('OAUTH_REDIRECT_URI');
    return switch (source) {
      'mock' => const AppEnvironment(),
      'live' => AppEnvironment(
        source: DataSource.live,
        apiBaseUrl: apiBaseUrl,
        oauthRedirectUri: oauthRedirectUri,
      ),
      _ => throw StateError('DATA_SOURCE must be mock or live'),
    };
  }

  final DataSource source;
  final String apiBaseUrl;
  final String oauthRedirectUri;

  Uri? get oauthCallback {
    final uri = Uri.tryParse(oauthRedirectUri);
    if (!isLive ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.path != '/auth/callback' ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return uri;
  }

  bool get isLive => source == DataSource.live;
}

final environmentProvider = Provider<AppEnvironment>(
  (_) => const AppEnvironment(),
);
