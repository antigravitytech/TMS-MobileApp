import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../../core/services/shared_pref_service.dart';
import '../../authentication/domain/account.dart';
import '../../workspace/application/workspace_preview.dart';

final profileSetupRepositoryProvider = Provider<ProfileSetupRepository>((ref) {
  if (ref.watch(environmentProvider).isLive) {
    return LiveProfileSetupRepository(
      ref.watch(networkCallsRepositoryProvider),
    );
  }
  return MockProfileSetupRepository(
    ref.read(workspacePreviewProvider).saveProfile,
  );
});

abstract class ProfileSetupRepository {
  Future<Account?> saveProfile(
    String first,
    String last,
    String job,
    Uint8List? photo,
  );
  Future<void> saveBirthday(DateTime? date, bool visible);
  Future<void> saveNotices(Map<String, bool> notices, {String? workspaceId});
}

class MockProfileSetupRepository implements ProfileSetupRepository {
  const MockProfileSetupRepository(this._save);

  final void Function(String, String, String) _save;

  @override
  Future<Account?> saveProfile(
    String first,
    String last,
    String job,
    Uint8List? photo,
  ) async {
    _save(first, last, job);
    return null;
  }

  @override
  Future<void> saveBirthday(DateTime? date, bool visible) async {
    await SharedPreferencesService.setString(
      key: 'onboarding.birthday',
      value: date?.toIso8601String() ?? '',
    );
    await SharedPreferencesService.setBool(
      key: 'onboarding.birthday_visible',
      value: visible,
    );
  }

  @override
  Future<void> saveNotices(
    Map<String, bool> notices, {
    String? workspaceId,
  }) async {
    for (final entry in notices.entries) {
      await SharedPreferencesService.setBool(
        key: 'onboarding.nudge.${entry.key}',
        value: entry.value,
      );
    }
  }
}

class LiveProfileSetupRepository implements ProfileSetupRepository {
  const LiveProfileSetupRepository(this._network);

  final NetworkCallsRepository _network;

  Future<Account> getProfile() async => Account.fromJson(
    accountPayload(
      await _network.get<Map<String, dynamic>>('/auth/get-profile/'),
    ),
  );

  @override
  Future<Account> saveProfile(
    String first,
    String last,
    String job,
    Uint8List? photo,
  ) async {
    final fields = {
      'first_name': first.trim(),
      'last_name': last.trim(),
      'job_title': job.trim(),
    };
    if (photo != null) {
      final type = lookupMimeType('', headerBytes: photo);
      final extension = switch (type) {
        'image/png' => 'png',
        'image/jpeg' => 'jpg',
        'image/gif' => 'gif',
        'image/webp' => 'webp',
        'image/bmp' || 'image/x-ms-bmp' => 'bmp',
        'image/tiff' => 'tiff',
        _ => throw const AccountFailure(NetworkFailureType.validation),
      };
      final result = await _network.put<Map<String, dynamic>>(
        '/auth/update-profile/',
        data: FormData.fromMap({
          ...fields,
          'photo': MultipartFile.fromBytes(
            photo,
            filename: 'profile-photo.$extension',
            contentType: DioMediaType(
              'image',
              extension == 'jpg' ? 'jpeg' : extension,
            ),
          ),
        }),
      );
      return Account.fromJson(accountPayload(result));
    }
    final result = await _network.patch<Map<String, dynamic>>(
      '/auth/update-profile-json/',
      data: fields,
    );
    return Account.fromJson(accountPayload(result));
  }

  @override
  Future<void> saveBirthday(DateTime? date, bool visible) async {
    accountPayload(
      await _network.put<Map<String, dynamic>>(
        '/birthday/set-my-birthday/',
        data: {
          'date_of_birth': date?.toIso8601String().split('T').first,
          'visibility': visible ? 'workspace' : 'private',
        },
      ),
    );
  }

  static const notificationEvents = {
    'reviews': ['submitted', 'returned', 'approved'],
    'chat': ['chat'],
    'birthdays': ['birthday'],
  };

  Future<Map<String, ({bool inApp, bool email})>> _getEvents(String id) async {
    final response = accountPayload(
      await _network.get<Map<String, dynamic>>(
        '/notification/get-preferences/$id/',
      ),
    );
    return {
      for (final event
          in (response['events'] as List).cast<Map<String, dynamic>>())
        event['event'] as String: (
          inApp: event['in_app'] as bool,
          email: event['email'] as bool,
        ),
    };
  }

  Future<Map<String, bool>> getNotices(String workspaceId) async {
    final events = await _getEvents(Uri.encodeComponent(workspaceId));
    return {
      for (final group in notificationEvents.entries)
        group.key: group.value.any((event) => events[event]?.inApp ?? false),
    };
  }

  @override
  Future<void> saveNotices(
    Map<String, bool> notices, {
    String? workspaceId,
  }) async {
    if (notices.isEmpty || workspaceId == null) return;
    final id = Uri.encodeComponent(workspaceId);
    final current = await _getEvents(id);
    accountPayload(
      await _network.put<Map<String, dynamic>>(
        '/notification/update-preferences/$id/',
        data: {
          'events': [
            for (final group in notificationEvents.entries)
              if (notices.containsKey(group.key))
                for (final event in group.value)
                  {
                    'event': event,
                    'in_app': notices[group.key],
                    'email': current[event]?.email ?? false,
                  },
          ],
        },
      ),
    );
  }
}
