import 'dart:developer';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? get _analytics {
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  /// Returns a [NavigatorObserver] for automatic screen-view tracking.
  static NavigatorObserver? get navigatorObserver {
    final instance = _analytics;
    if (instance == null) return null;
    return FirebaseAnalyticsObserver(analytics: instance);
  }

  static Future<void> setUser({
    required String? userId,
    String? role,
    String? businessId,
    bool isDemo = false,
  }) async {
    try {
      final analytics = _analytics;
      if (analytics == null) return;
      await analytics.setUserId(id: userId);
      await analytics.setUserProperty(name: 'user_role', value: role);
      await analytics.setUserProperty(name: 'business_id', value: businessId);
      await analytics.setUserProperty(
        name: 'is_demo',
        value: userId == null ? null : isDemo.toString(),
      );
    } catch (e) {
      log('AnalyticsService.setUser warning: $e');
    }
  }

  static Future<void> logLogin(String method) async {
    try {
      await _analytics?.logLogin(loginMethod: method);
    } catch (e) {
      log('AnalyticsService.logLogin warning: $e');
    }
  }

  static Future<void> logSignUp(String method) async {
    try {
      await _analytics?.logSignUp(signUpMethod: method);
    } catch (e) {
      log('AnalyticsService.logSignUp warning: $e');
    }
  }

  static Future<void> logDemoModeStarted() async {
    try {
      await _analytics?.logEvent(name: 'demo_mode_started');
    } catch (e) {
      log('AnalyticsService.logDemoModeStarted warning: $e');
    }
  }

  static Future<void> logBusinessSetupCompleted({
    required String templateType,
    required bool seededSamples,
    required int sampleCount,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'business_setup_completed',
        parameters: {
          'template_type': templateType,
          'seeded_samples': seededSamples ? 1 : 0,
          'sample_count': sampleCount,
        },
      );
    } catch (e) {
      log('AnalyticsService.logBusinessSetupCompleted warning: $e');
    }
  }

  static Future<void> logTransactionCompleted({
    required double totalAmount,
    required int itemCount,
    required String paymentMethods,
    required bool isDemo,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'transaction_completed',
        parameters: {
          'total_amount': totalAmount.round(),
          'item_count': itemCount,
          'payment_methods': paymentMethods,
          'is_demo': isDemo ? 1 : 0,
        },
      );
    } catch (e) {
      log('AnalyticsService.logTransactionCompleted warning: $e');
    }
  }

  static Future<void> logQrisFullscreenOpened() async {
    try {
      await _analytics?.logEvent(name: 'qris_fullscreen_opened');
    } catch (e) {
      log('AnalyticsService.logQrisFullscreenOpened warning: $e');
    }
  }

  static Future<void> logUpgradeProViewed({String? featureName}) async {
    try {
      await _analytics?.logEvent(
        name: 'upgrade_pro_sheet_viewed',
        parameters: {
          if (featureName != null && featureName.isNotEmpty)
            'feature_name': featureName,
        },
      );
    } catch (e) {
      log('AnalyticsService.logUpgradeProViewed warning: $e');
    }
  }
}
