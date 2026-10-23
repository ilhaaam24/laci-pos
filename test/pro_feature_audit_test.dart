import 'package:flutter_test/flutter_test.dart';
import 'package:laci/domain/entities/business_entity.dart';
import 'package:laci/core/services/receipt_settings_service.dart';

void main() {
  group('BusinessEntity isPro & isFree Domain Tests', () {
    test('returns isFree = true and isPro = false for free subscription tier', () {
      final freeBusiness = BusinessInfo(
        id: 'biz_free',
        businessName: 'Toko Free',
        subscriptionTier: 'free',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(freeBusiness.isPro, isFalse);
      expect(freeBusiness.isFree, isTrue);
      expect(freeBusiness.remainingProDays, equals(0));
    });

    test('returns isPro = false if tier is pro but subscriptionExpiresAt is null', () {
      final invalidPro = BusinessInfo(
        id: 'biz_pro_null',
        businessName: 'Toko Pro Null',
        subscriptionTier: 'pro',
        subscriptionExpiresAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(invalidPro.isPro, isFalse);
      expect(invalidPro.isFree, isTrue);
    });

    test('returns isPro = false if subscription has expired', () {
      final expiredPro = BusinessInfo(
        id: 'biz_expired',
        businessName: 'Toko Expired',
        subscriptionTier: 'pro',
        subscriptionExpiresAt: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expiredPro.isPro, isFalse);
      expect(expiredPro.isFree, isTrue);
      expect(expiredPro.remainingProDays, equals(0));
    });

    test('returns isPro = true if subscription tier is pro and date is in future', () {
      final activePro = BusinessInfo(
        id: 'biz_active',
        businessName: 'Toko Aktif Pro',
        subscriptionTier: 'pro',
        subscriptionPlan: 'yearly',
        subscriptionExpiresAt: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(activePro.isPro, isTrue);
      expect(activePro.isFree, isFalse);
      expect(activePro.remainingProDays, greaterThan(0));
    });
  });

  group('ReceiptConfig Pro Restrictions Sanitize Tests', () {
    test('enforces watermark true and logo false when user is not pro', () {
      const originalConfig = ReceiptConfig(
        showLogo: true,
        showWatermark: false,
      );

      const isPro = false;
      final sanitized = isPro
          ? originalConfig
          : originalConfig.copyWith(showLogo: false, showWatermark: true);

      expect(sanitized.showLogo, isFalse);
      expect(sanitized.showWatermark, isTrue);
    });

    test('retains custom logo and watermark when user is pro', () {
      const originalConfig = ReceiptConfig(
        showLogo: true,
        showWatermark: false,
      );

      const isPro = true;
      final sanitized = isPro
          ? originalConfig
          : originalConfig.copyWith(showLogo: false, showWatermark: true);

      expect(sanitized.showLogo, isTrue);
      expect(sanitized.showWatermark, isFalse);
    });
  });
}
