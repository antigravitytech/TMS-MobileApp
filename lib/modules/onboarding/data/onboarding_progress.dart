import '../../../core/services/shared_pref_service.dart';

class OnboardingProgress {
  const OnboardingProgress(this.accountId);

  final String accountId;

  String get _key => 'live.onboarding.$accountId';

  Future<String?> load() async {
    await SharedPreferencesService.init();
    return SharedPreferencesService.getString(key: _key);
  }

  Future<void> save(String step) =>
      SharedPreferencesService.setString(key: _key, value: step);
}
