import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStateService {
  static const _seenKey = 'has_seen_onboarding_v1';
  static const _firstProjectGuideKey = 'has_seen_first_project_guide_v1';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  Future<bool> hasSeenFirstProjectGuide() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstProjectGuideKey) ?? false;
  }

  Future<void> markFirstProjectGuideSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstProjectGuideKey, true);
  }

  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenKey);
    await prefs.remove(_firstProjectGuideKey);
  }
}
