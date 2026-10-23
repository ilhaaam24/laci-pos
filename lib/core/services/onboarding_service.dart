import 'package:shared_preferences/shared_preferences.dart';

/// Service to track and persist whether the user has completed or skipped the new user onboarding flow.
class OnboardingService {
  static const String _onboardingKey = 'laci_has_completed_onboarding_v1';

  /// Check whether the user has already completed or skipped the onboarding flow.
  static Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark onboarding as completed so it will not show automatically on subsequent launches.
  static Future<void> setOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } catch (_) {
      // Ignore write errors gracefully
    }
  }

  /// Reset onboarding state back to uncompleted (useful for re-running from Settings or tests).
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingKey);
    } catch (_) {
      // Ignore write errors gracefully
    }
  }
}
