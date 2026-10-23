import 'dart:async';
import '../../domain/entities/business_entity.dart';

/// Configuration and Product Identifiers for Google Play In-App Billing
class LaciPosIapConfig {
  static const String monthlySubscriptionId = 'lacipos_pro_monthly';
  static const String yearlySubscriptionId = 'lacipos_pro_yearly';
  static const String lifetimeNonConsumableId = 'lacipos_pro_lifetime';

  static const List<String> allSubscriptionIds = [
    monthlySubscriptionId,
    yearlySubscriptionId,
  ];

  static const List<String> allProductIds = [
    monthlySubscriptionId,
    yearlySubscriptionId,
    lifetimeNonConsumableId,
  ];
}

/// Abstract contract for In-App Purchase Service
/// Ready to connect with package:in_app_purchase or package:purchases_flutter (RevenueCat)
abstract class IapService {
  /// Initializes the in-app purchase connection and listens to purchase updates
  Future<void> initialize({String? appUserId});

  /// Identifies the current business user in the payment provider
  Future<void> identifyUser(String businessId);

  /// Logs out the user from the payment provider
  Future<void> logout();

  /// Requests purchase of a subscription (monthly or yearly)
  Future<bool> purchaseSubscription(String productId);

  /// Restores previous purchases for the signed-in user
  Future<bool> restorePurchases();

  /// Gets the current active expiration date from provider
  Future<DateTime?> getExpirationDate();

  /// Verifies a purchase and updates the business entity subscription
  BusinessInfo handleSuccessfulPurchase({
    required BusinessInfo currentBusiness,
    required String productId,
    required String purchaseToken,
    DateTime? expirationDate,
  }) {
    final now = DateTime.now();
    DateTime newExpiresAt;
    String plan;

    if (expirationDate != null && expirationDate.isAfter(now)) {
      newExpiresAt = expirationDate;
      if (productId == LaciPosIapConfig.yearlySubscriptionId) {
        plan = 'yearly';
      } else if (productId == LaciPosIapConfig.lifetimeNonConsumableId) {
        plan = 'lifetime';
      } else {
        plan = 'monthly';
      }
    } else {
      if (productId == LaciPosIapConfig.yearlySubscriptionId) {
        newExpiresAt = now.add(const Duration(days: 365));
        plan = 'yearly';
      } else if (productId == LaciPosIapConfig.lifetimeNonConsumableId) {
        newExpiresAt = now.add(const Duration(days: 36500));
        plan = 'lifetime';
      } else {
        newExpiresAt = now.add(const Duration(days: 30));
        plan = 'monthly';
      }
    }

    return currentBusiness.copyWith(
      subscriptionTier: 'pro',
      subscriptionExpiresAt: newExpiresAt,
      subscriptionPlan: plan,
      updatedAt: now,
    );
  }

  /// Disposes streams and resources
  void dispose();
}

/// Standalone fallback implementation of [IapService] used when store billing is inactive.
/// Allows the app to run completely free of third-party store billing SDKs (RevenueCat/Google Play)
/// while keeping the architecture ready for voucher licensing or future IAP reactivation.
class NoopIapService implements IapService {
  @override
  Future<void> initialize({String? appUserId}) async {}

  @override
  Future<void> identifyUser(String businessId) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<bool> purchaseSubscription(String productId) async => false;

  @override
  Future<bool> restorePurchases() async => false;

  @override
  Future<DateTime?> getExpirationDate() async => null;

  @override
  BusinessInfo handleSuccessfulPurchase({
    required BusinessInfo currentBusiness,
    required String productId,
    required String purchaseToken,
    DateTime? expirationDate,
  }) {
    final now = DateTime.now();
    DateTime newExpiresAt;
    String plan;

    if (expirationDate != null && expirationDate.isAfter(now)) {
      newExpiresAt = expirationDate;
      if (productId == LaciPosIapConfig.yearlySubscriptionId) {
        plan = 'yearly';
      } else if (productId == LaciPosIapConfig.lifetimeNonConsumableId) {
        plan = 'lifetime';
      } else {
        plan = 'monthly';
      }
    } else {
      if (productId == LaciPosIapConfig.yearlySubscriptionId) {
        newExpiresAt = now.add(const Duration(days: 365));
        plan = 'yearly';
      } else if (productId == LaciPosIapConfig.lifetimeNonConsumableId) {
        newExpiresAt = now.add(const Duration(days: 36500));
        plan = 'lifetime';
      } else {
        newExpiresAt = now.add(const Duration(days: 30));
        plan = 'monthly';
      }
    }

    return currentBusiness.copyWith(
      subscriptionTier: 'pro',
      subscriptionExpiresAt: newExpiresAt,
      subscriptionPlan: plan,
      updatedAt: now,
    );
  }

  @override
  void dispose() {}
}
