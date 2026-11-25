import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/media_service.dart';
import '../../../core/services/shared_pref_service.dart';
import '../../workspace/application/workspace_preview.dart';

final profileSetupProvider =
    NotifierProvider.autoDispose<ProfileSetupNotifier, ProfileSetupState>(
      ProfileSetupNotifier.new,
    );

enum ProfileSetupStep { profile, birthday, notifications }

enum ProfileSetupResult { stay, complete, photoFailed, saveFailed }

class ProfileSetupState {
  const ProfileSetupState({
    required this.birthday,
    this.first = 'Chioma',
    this.last = 'Okafor',
    this.job = 'Tech Lead',
    this.color = 0,
    this.photo,
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

  @override
  ProfileSetupState build() =>
      ProfileSetupState(birthday: DateTime(1997, 11, 23));

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

  void setNotice(String key, bool enabled) => state = state.copyWith(
    notices: Map.unmodifiable({...state.notices, key: enabled}),
  );

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

    if (draft.step == ProfileSetupStep.profile) {
      if (!skip) {
        ref
            .read(workspacePreviewProvider)
            .saveProfile(draft.first, draft.last, draft.job);
      }
      state = state.copyWith(step: ProfileSetupStep.birthday);
      return ProfileSetupResult.stay;
    }

    state = state.copyWith(saving: true);
    try {
      if (draft.step == ProfileSetupStep.birthday) {
        await SharedPreferencesService.setString(
          key: 'onboarding.birthday',
          value: skip ? '' : draft.birthday.toIso8601String(),
        );
        await SharedPreferencesService.setBool(
          key: 'onboarding.birthday_visible',
          value: draft.birthdayVisible,
        );
        if (ref.mounted) {
          state = state.copyWith(step: ProfileSetupStep.notifications);
        }
        return ProfileSetupResult.stay;
      }

      if (!skip) {
        for (final entry in draft.notices.entries) {
          await SharedPreferencesService.setBool(
            key: 'onboarding.nudge.${entry.key}',
            value: entry.value,
          );
        }
      }
      return ProfileSetupResult.complete;
    } catch (_) {
      return ProfileSetupResult.saveFailed;
    } finally {
      if (ref.mounted) state = state.copyWith(saving: false);
    }
  }
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
