import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/media_service.dart';
import '../../../core/config/environment.dart';
import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../data/profile_setup_repository.dart';
import '../data/onboarding_progress.dart';

final profileSetupProvider =
    NotifierProvider.autoDispose<ProfileSetupNotifier, ProfileSetupState>(
      ProfileSetupNotifier.new,
    );

enum ProfileSetupStep { profile, birthday, notifications }

enum ProfileSetupResult { stay, complete, photoFailed, saveFailed, expired }

class ProfileSetupState {
  const ProfileSetupState({
    required this.birthday,
    this.first = 'Chioma',
    this.last = 'Okafor',
    this.job = 'Tech Lead',
    this.color = 0,
    this.photo,
    this.photoUrl,
    this.step = ProfileSetupStep.profile,
    this.birthdayVisible = true,
    this.saving = false,
    this.roles = const {
      'common.member',
      'common.line_manager',
      'common.team_lead',
    },
    this.notices = const {
      'reviews': true,
      'chat': true,
      'report': true,
      'clock': false,
      'birthdays': true,
    },
  });

  final String first, last, job;
  final int color;
  final Uint8List? photo;
  final String? photoUrl;
  final ProfileSetupStep step;
  final DateTime birthday;
  final bool birthdayVisible, saving;
  final Set<String> roles;
  final Map<String, bool> notices;

  bool get canContinue =>
      !saving && (step != ProfileSetupStep.profile || first.trim().isNotEmpty);

  int get daysInBirthdayMonth => _daysInMonth(birthday.year, birthday.month);

  Iterable<int> get birthdayYears sync* {
    for (var year = DateTime.now().year; year >= 1900; year--) {
      yield year;
    }
  }

  ProfileSetupState copyWith({
    String? first,
    String? last,
    String? job,
    int? color,
    Uint8List? photo,
    bool clearPhoto = false,
    ProfileSetupStep? step,
    DateTime? birthday,
    bool? birthdayVisible,
    bool? saving,
    Set<String>? roles,
    Map<String, bool>? notices,
  }) => ProfileSetupState(
    first: first ?? this.first,
    last: last ?? this.last,
    job: job ?? this.job,
    color: color ?? this.color,
    photo: clearPhoto ? null : photo ?? this.photo,
    photoUrl: clearPhoto ? null : photoUrl,
    step: step ?? this.step,
    birthday: birthday ?? this.birthday,
    birthdayVisible: birthdayVisible ?? this.birthdayVisible,
    saving: saving ?? this.saving,
    roles: roles ?? this.roles,
    notices: notices ?? this.notices,
  );
}

class ProfileSetupNotifier extends Notifier<ProfileSetupState> {
  bool _pickingPhoto = false;
  String? _noticeWorkspaceId;
  final _noticeEdits = <String, bool>{};

  @override
  ProfileSetupState build() {
    if (!ref.read(environmentProvider).isLive) {
      return ProfileSetupState(birthday: DateTime(1997, 11, 23));
    }
    final account = ref.read(accountSessionProvider);
    final today = DateTime.now();
    return ProfileSetupState(
      first: account?.firstName ?? '',
      last: account?.lastName ?? '',
      job: account?.jobTitle ?? '',
      photoUrl: account?.photo,
      birthday:
          account?.birthday ?? DateTime(today.year, today.month, today.day),
      birthdayVisible: account?.birthdayVisible ?? true,
      roles: const {},
      notices: const {},
    );
  }

  Future<ProfileSetupResult> loadProfile() async {
    final repository = ref.read(profileSetupRepositoryProvider);
    if (repository is! LiveProfileSetupRepository) {
      return ProfileSetupResult.stay;
    }
    final session = ref.read(accountSessionProvider.notifier);
    state = state.copyWith(saving: true);
    try {
      final account = await repository.getProfile();
      session.update(account);
      final saved = await OnboardingProgress(account.id).load();
      final step = switch (saved) {
        'birthday' => ProfileSetupStep.birthday,
        'notifications' => ProfileSetupStep.notifications,
        _ => ProfileSetupStep.profile,
      };
      if (!ref.mounted) return ProfileSetupResult.stay;
      final notices = step == ProfileSetupStep.notifications
          ? await _loadNotices(repository)
          : null;
      if (ref.mounted) state = build().copyWith(step: step, notices: notices);
      return ProfileSetupResult.stay;
    } on AccountFailure catch (error) {
      return await session.expire(error)
          ? ProfileSetupResult.expired
          : ProfileSetupResult.saveFailed;
    } catch (_) {
      return ProfileSetupResult.saveFailed;
    } finally {
      if (ref.mounted) state = state.copyWith(saving: false);
    }
  }

  void setFirstName(String value) => state = state.copyWith(first: value);
  void setLastName(String value) => state = state.copyWith(last: value);
  void setJobTitle(String value) => state = state.copyWith(job: value);

  void selectColor(int index) =>
      state = state.copyWith(color: index, clearPhoto: true);

  void toggleRole(String role) {
    final roles = {...state.roles};
    if (!roles.add(role)) roles.remove(role);
    state = state.copyWith(roles: Set.unmodifiable(roles));
  }

  void setBirthday({int? year, int? month, int? day}) {
    final current = state.birthday;
    final selectedYear = year ?? current.year;
    final selectedMonth = month ?? current.month;
    final selectedDay = (day ?? current.day).clamp(
      1,
      _daysInMonth(selectedYear, selectedMonth),
    );
    state = state.copyWith(
      birthday: DateTime(selectedYear, selectedMonth, selectedDay),
    );
  }

  void setBirthdayVisibility(bool visible) =>
      state = state.copyWith(birthdayVisible: visible);

  Future<Map<String, bool>> _loadNotices(
    LiveProfileSetupRepository repository,
  ) async {
    final workspaces = await ref.read(accountWorkspacesProvider.future);
    _noticeWorkspaceId = null;
    for (final workspace in workspaces) {
      if (workspace.approval == 'approved') {
        _noticeWorkspaceId = workspace.id;
        return {...await repository.getNotices(workspace.id), ..._noticeEdits};
      }
    }
    return const {};
  }

  void setNotice(String key, bool enabled) {
    _noticeEdits[key] = enabled;
    state = state.copyWith(
      notices: Map.unmodifiable({...state.notices, key: enabled}),
    );
  }

  void previousStep() {
    final index = state.step.index;
    if (state.saving || index == 0) return;
    state = state.copyWith(step: ProfileSetupStep.values[index - 1]);
  }

  Future<ProfileSetupResult> choosePhoto() async {
    if (_pickingPhoto) return ProfileSetupResult.stay;
    _pickingPhoto = true;
    try {
      final bytes = await MediaService.pickImageBytes();
      if (ref.mounted && bytes != null) state = state.copyWith(photo: bytes);
      return ProfileSetupResult.stay;
    } catch (_) {
      return ProfileSetupResult.photoFailed;
    } finally {
      _pickingPhoto = false;
    }
  }

  Future<ProfileSetupResult> advance({bool skip = false}) async {
    final draft = state;
    if (draft.saving || (!skip && !draft.canContinue)) {
      return ProfileSetupResult.stay;
    }

    final repository = ref.read(profileSetupRepositoryProvider);
    final session = ref.read(accountSessionProvider.notifier);
    final live = repository is LiveProfileSetupRepository;
    final accountId = live ? ref.read(accountSessionProvider)?.id : null;
    final progress = accountId == null ? null : OnboardingProgress(accountId);
    state = state.copyWith(saving: true);
    try {
      switch (draft.step) {
        case ProfileSetupStep.profile:
          if (!skip) {
            final account = await repository.saveProfile(
              draft.first,
              draft.last,
              draft.job,
              draft.photo,
            );
            if (account != null) session.update(account);
          }
        case ProfileSetupStep.birthday:
          if (!skip || !live) {
            await repository.saveBirthday(
              skip ? null : draft.birthday,
              draft.birthdayVisible,
            );
          }
        case ProfileSetupStep.notifications:
          if (!skip) {
            await repository.saveNotices(
              live ? _noticeEdits : draft.notices,
              workspaceId: _noticeWorkspaceId,
            );
          }
          await progress?.save('complete');
          return ProfileSetupResult.complete;
      }
      final next = ProfileSetupStep.values[draft.step.index + 1];
      if (!ref.mounted) return ProfileSetupResult.stay;
      final notices = live && next == ProfileSetupStep.notifications
          ? await _loadNotices(repository)
          : null;
      await progress?.save(next.name);
      if (ref.mounted) state = state.copyWith(step: next, notices: notices);
      return ProfileSetupResult.stay;
    } on AccountFailure catch (error) {
      return await session.expire(error)
          ? ProfileSetupResult.expired
          : ProfileSetupResult.saveFailed;
    } catch (_) {
      return ProfileSetupResult.saveFailed;
    } finally {
      if (ref.mounted) state = state.copyWith(saving: false);
    }
  }
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
