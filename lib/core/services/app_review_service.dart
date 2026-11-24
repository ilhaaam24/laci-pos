import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../di/injection.dart';
import 'session_service.dart';

class AppReviewService {
  AppReviewService._();

  static const String _txCountKey = 'app_review_tx_count';
  static const String _promptCountKey = 'app_review_prompt_count';
  static const String _lastPromptMsKey = 'app_review_last_prompt_ms';

  static const int _firstPromptThreshold = 5;
  static const int _secondPromptThreshold = 25;
  static const int _maxPrompts = 2;
  static const Duration _cooldown = Duration(days: 30);

  /// Records a successful real transaction and triggers the native Play Store /
  /// App Store in-app review prompt at positive milestones (5th and 25th tx).
  static Future<void> recordCompletedTransactionAndPromptIfEligible() async {
    if (kIsWeb) return;
    try {
      if (getIt<SessionService>().isDemoMode) return;
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final txCount = (prefs.getInt(_txCountKey) ?? 0) + 1;
      await prefs.setInt(_txCountKey, txCount);

      final promptCount = prefs.getInt(_promptCountKey) ?? 0;
      if (promptCount >= _maxPrompts) return;

      final shouldPrompt =
          (promptCount == 0 && txCount >= _firstPromptThreshold) ||
          (promptCount == 1 && txCount >= _secondPromptThreshold);
      if (!shouldPrompt) return;

      final lastPromptMs = prefs.getInt(_lastPromptMsKey);
      if (lastPromptMs != null) {
        final elapsed = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(lastPromptMs),
        );
        if (elapsed < _cooldown) return;
      }

      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await prefs.setInt(_promptCountKey, promptCount + 1);
        await prefs.setInt(
          _lastPromptMsKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      log('AppReviewService warning: $e');
    }
  }
}
