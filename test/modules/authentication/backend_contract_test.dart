import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/core/config/environment.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/core/network/network_calls_repository.dart';
import 'package:sabi_pipu_tms/modules/authentication/domain/account.dart';
import 'package:sabi_pipu_tms/core/network/token_utils.dart';
import 'package:sabi_pipu_tms/modules/authentication/data/auth_repository.dart';
import 'package:sabi_pipu_tms/modules/onboarding/data/profile_setup_repository.dart';

const _user = {
  'id': 'fixture-user',
  'email': 'member@example.test',
  'first_name': 'Ari',
  'last_name': 'Lee',
  'is_verified': true,
};

const _token = 'fixture-access-token';

void main() {
  test(
    'mock sign-in and restoration never resolve the network stack',
    () async {
      final container = ProviderContainer.test(
        overrides: [
          networkCallsRepositoryProvider.overrideWith(
            (_) => fail('Mock contacted network'),
          ),
        ],
      );
      final repository = container.read(authRepositoryProvider);
      expect(repository, isA<MockAuthRepository>());
      expect(
        await repository.signIn(
          'member@example.test',
          'fixture-password',
          true,
          Duration.zero,
        ),
        isNull,
      );
      expect(await repository.restore(), isNull);
    },
  );

  group('live wire contracts', () {
    late HttpServer server;
    late ProviderContainer container;
    late List<_Request> requests;
    late bool expired, pendingLogin;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      await TokenUtils().clearTokens();
      expired = false;
      pendingLogin = false;
      requests = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        final path = request.uri.path;
        requests.add(
          _Request(
            request.method,
            path,
            request.headers.value(HttpHeaders.authorizationHeader),
            request.headers.contentType?.mimeType,
            await const Utf8Decoder(allowMalformed: true).bind(request).join(),
          ),
        );
        final body = switch (path) {
          '/auth/login/' when pendingLogin => {
            'code': 'workspace_pending_approval',
          },
          '/auth/login/' || '/auth/signup/' || '/auth/oauth/google/callback/' =>
            {'user': _user, 'access_token': _token, 'token_type': 'bearer'},
          '/auth/check-auth/' ||
          '/auth/get-profile/' ||
          '/auth/update-profile-json/' ||
          '/auth/update-profile/' => _user,
          '/workspace/list-workspaces/' => {
            'total_pages': 1,
            'items': [
              {
                'id': 'one',
                'name': 'Team',
                'kind': 'business',
                'approval_status': 'pending',
              },
              {
                'id': 'two',
                'name': 'Event',
                'kind': 'specials',
                'approval_status': 'approved',
              },
            ],
          },
          '/notification/get-preferences/one/' => {
            'events': [
              {'event': 'chat', 'in_app': true, 'email': true},
            ],
          },
          _ => {'message': 'OK'},
        };
        request.response.statusCode = switch (path) {
          '/auth/signup/' => 201,
          '/auth/login/' when pendingLogin => 403,
          '/auth/check-auth/' when expired => 401,
          _ => 200,
        };
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(body));
        await request.response.close();
      });
      container = ProviderContainer.test(
        overrides: [
          environmentProvider.overrideWithValue(
            AppEnvironment(
              source: DataSource.live,
              apiBaseUrl: 'http://127.0.0.1:${server.port}',
            ),
          ),
        ],
      );
    });

    test(
      'login persists the JWT, supplies bearer auth and clears an expired session',
      () async {
        final repository =
            container.read(authRepositoryProvider) as LiveAuthRepository;
        expect(await repository.restore(), isNull);
        final user = await repository.signIn(
          'member@example.test',
          'fixture-password',
          true,
          Duration.zero,
        );
        expect(user.email, 'member@example.test');
        expect(requests.single.authorization, isNull);
        expect(jsonDecode(requests.single.body), {
          'email': 'member@example.test',
          'password': 'fixture-password',
          'remember_me': true,
        });

        expect((await repository.restore())?.id, user.id);
        expect(requests.last.authorization, 'Bearer $_token');
        expect((await repository.workspaces()).single.approval, 'pending');
        await repository.requestReset(user.email);
        expect(requests.last.authorization, isNull);
        expired = true;
        expect(await repository.restore(), isNull);
        expect(await TokenUtils().getAccessToken(), isNull);
      },
    );

    test(
      'public auth requests never attach a previously stored bearer token',
      () async {
        final auth =
            container.read(authRepositoryProvider) as LiveAuthRepository;
        await auth.signIn(
          'member@example.test',
          'fixture-password',
          false,
          Duration.zero,
        );
        await auth.verifyEmail(email: _user['email'] as String, code: '123456');
        expect(jsonDecode(requests.last.body), {
          'email': _user['email'],
          'code': '123456',
        });
        expect(requests.last.authorization, isNull);
        await auth.verifyEmail(token: 'fixture-link');
        expect(jsonDecode(requests.last.body), {'token': 'fixture-link'});
        await auth.confirmReset('fixture-reset', 'fixture-password');
        expect(jsonDecode(requests.last.body), {
          'token': 'fixture-reset',
          'new_password': 'fixture-password',
        });
        expect(requests.last.authorization, isNull);
        await auth.changePassword('fixture-password', 'fixture-new-password');
        expect(requests.last.authorization, 'Bearer $_token');
        expect(jsonDecode(requests.last.body), {
          'current_password': 'fixture-password',
          'new_password': 'fixture-new-password',
        });
        await auth.signOut();
        pendingLogin = true;
        await expectLater(
          auth.signIn(
            'member@example.test',
            'fixture-password',
            false,
            Duration.zero,
          ),
          throwsA(
            isA<AccountFailure>()
                .having((e) => e.type, 'type', NetworkFailureType.forbidden)
                .having((e) => e.code, 'code', 'workspace_pending_approval'),
          ),
        );
        expect(await TokenUtils().getAccessToken(), isNull);
      },
    );

    test(
      'signup and live profile writes use documented methods and payloads',
      () async {
        final auth =
            container.read(authRepositoryProvider) as LiveAuthRepository;
        final profile =
            container.read(profileSetupRepositoryProvider)
                as LiveProfileSetupRepository;
        final user = await auth.signup({
          'workspace_name': 'Team',
          'workspace_type': 'family',
          'workspace_setup': {
            'members': [
              {'name': 'Lee', 'type': 'co_head'},
            ],
          },
          'first_name': 'Ari',
          'email': 'member@example.test',
          'password': 'fixture-password',
        });
        expect(user.id, (await profile.getProfile()).id);
        await profile.saveProfile('Ari', 'Lee', 'Writer', null);
        expect(requests.last.method, 'PATCH');
        expect(requests.last.authorization, 'Bearer $_token');
        expect(jsonDecode(requests.last.body)['job_title'], 'Writer');
        await profile.saveProfile(
          'Ari',
          'Lee',
          'Writer',
          Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        );
        expect(requests.last.path, '/auth/update-profile/');
        expect(requests.last.contentType, 'multipart/form-data');
        expect(requests.last.body, contains('name="photo"'));
        expect(
          requests.last.body.toLowerCase(),
          contains('content-type: image/png'),
        );
        await profile.saveBirthday(DateTime(1995, 11, 9), false);
        expect(jsonDecode(requests.last.body), {
          'date_of_birth': '1995-11-09',
          'visibility': 'private',
        });
        final count = requests.length;
        await profile.saveNotices({'chat': false});
        expect(requests, hasLength(count));
        await profile.saveNotices({'chat': false}, workspaceId: 'one');
        expect(requests.last.path, '/notification/update-preferences/one/');
        expect(jsonDecode(requests.last.body), {
          'events': [
            {'event': 'chat', 'in_app': false, 'email': true},
          ],
        });
        await auth.signOut();
        expect(await TokenUtils().getAccessToken(), isNull);
      },
    );
  });
}

class _Request {
  const _Request(
    this.method,
    this.path,
    this.authorization,
    this.contentType,
    this.body,
  );
  final String method, path, body;
  final String? authorization, contentType;
}
