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
  Future<void> initialize();

  /// Requests purchase of a subscription (monthly or yearly)
  Future<bool> purchaseSubscription(String productId);

  /// Restores previous purchases for the signed-in user
  Future<bool> restorePurchases();

  /// Verifies a purchase and updates the business entity subscription
  BusinessInfo handleSuccessfulPurchase({
    required BusinessInfo currentBusiness,
    required String productId,
    required String purchaseToken,
  }) {
    final now = DateTime.now();
    DateTime newExpiresAt;
    String plan;

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
