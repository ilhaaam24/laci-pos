import 'package:shared_preferences/shared_preferences.dart';

/// Service to track and manage onboarding tutorial / coach mark states.
class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  static const String _posTutorialKey = 'laci_has_seen_pos_tutorial_v1';

  /// Check whether the user has already seen or skipped the POS tutorial.
  Future<bool> hasSeenPosTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_posTutorialKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark the POS tutorial as seen or completed.
  Future<void> setPosTutorialSeen(bool seen) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_posTutorialKey, seen);
    } catch (_) {
      // Ignore write errors gracefully
    }
  }

  /// Reset the tutorial state so it can be re-run on demand from Settings or Help.
  Future<void> resetPosTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_posTutorialKey);
    } catch (_) {
      // Ignore write errors gracefully
    }
  }
}
