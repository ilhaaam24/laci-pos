import 'package:flutter_test/flutter_test.dart';
import 'package:laci/core/services/iap_service.dart';
import 'package:laci/core/services/license_service.dart';
import 'package:laci/domain/entities/business_entity.dart';

class _FakeIapService extends IapService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> purchaseSubscription(String productId) async => true;

  @override
  Future<bool> restorePurchases() async => true;

  @override
  void dispose() {}
}

void main() {
  group('LicenseService Voucher Tests', () {
    test('Validates promotional codes successfully', () {
      final monthly = LicenseService.validateCode('PRO-BULANAN-2026');
      expect(monthly.isValid, isTrue);
      expect(monthly.plan, 'monthly');
      expect(monthly.durationDays, 30);

      final yearly = LicenseService.validateCode('PRO-TAHUNAN-2026');
      expect(yearly.isValid, isTrue);
      expect(yearly.plan, 'yearly');
      expect(yearly.durationDays, 365);

      final lifetime = LicenseService.validateCode('PRO-LIFETIME-2026');
      expect(lifetime.isValid, isTrue);
      expect(lifetime.plan, 'lifetime');
      expect(lifetime.durationDays, 36500);
    });

    test('Generates and validates algorithmic checksum vouchers', () {
      final monthlyCode = LicenseService.generateVoucherCode(
        plan: 'monthly',
        orderId: 'ORD1001',
      );
      expect(monthlyCode.startsWith('PRO30-ORD1001-'), isTrue);

      final resultMonthly = LicenseService.validateCode(monthlyCode);
      expect(resultMonthly.isValid, isTrue);
      expect(resultMonthly.plan, 'monthly');
      expect(resultMonthly.durationDays, 30);

      final yearlyCode = LicenseService.generateVoucherCode(
        plan: 'yearly',
        orderId: 'INV9988',
      );
      final resultYearly = LicenseService.validateCode(yearlyCode);
      expect(resultYearly.isValid, isTrue);
      expect(resultYearly.plan, 'yearly');
      expect(resultYearly.durationDays, 365);
    });

    test('Rejects invalid vouchers with modified characters or empty strings', () {
      expect(LicenseService.validateCode('').isValid, isFalse);
      expect(LicenseService.validateCode('INVALID-CODE').isValid, isFalse);
      expect(LicenseService.validateCode('PRO30-ORD1001-XXXX').isValid, isFalse);
    });

    test('Applies voucher to Free business activating Pro tier', () {
      final base = BusinessInfo(
        id: 'biz-1',
        businessName: 'Warung Kopi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final voucher = LicenseService.validateCode('PRO-BULANAN-2026');
      final upgraded = LicenseService.applyVoucherToBusiness(
        current: base,
        voucher: voucher,
      );

      expect(upgraded.isPro, isTrue);
      expect(upgraded.subscriptionTier, 'pro');
      expect(upgraded.subscriptionPlan, 'monthly');
      expect(upgraded.remainingProDays, greaterThanOrEqualTo(29));
    });

    test('Stacks voucher duration onto existing Pro subscription', () {
      final initialExpiry = DateTime.now().add(const Duration(days: 10));
      final base = BusinessInfo(
        id: 'biz-1',
        businessName: 'Warung Kopi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        subscriptionTier: 'pro',
        subscriptionExpiresAt: initialExpiry,
        subscriptionPlan: 'monthly',
      );

      final voucher = LicenseService.validateCode('PRO-TAHUNAN-2026');
      final extended = LicenseService.applyVoucherToBusiness(
        current: base,
        voucher: voucher,
      );

      expect(extended.isPro, isTrue);
      expect(extended.remainingProDays, greaterThanOrEqualTo(374));
      expect(extended.subscriptionPlan, 'yearly');
    });
  });

  group('IapService Tests', () {
    test('handleSuccessfulPurchase updates BusinessInfo with monthly and yearly plans', () {
      final fakeIap = _FakeIapService();
      final base = BusinessInfo(
        id: 'biz-1',
        businessName: 'Toko Bunga',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final monthlyPurchased = fakeIap.handleSuccessfulPurchase(
        currentBusiness: base,
        productId: LaciPosIapConfig.monthlySubscriptionId,
        purchaseToken: 'token-xyz',
      );

      expect(monthlyPurchased.isPro, isTrue);
      expect(monthlyPurchased.subscriptionPlan, 'monthly');
      expect(monthlyPurchased.remainingProDays, greaterThanOrEqualTo(29));

      final yearlyPurchased = fakeIap.handleSuccessfulPurchase(
        currentBusiness: base,
        productId: LaciPosIapConfig.yearlySubscriptionId,
        purchaseToken: 'token-abc',
      );

      expect(yearlyPurchased.isPro, isTrue);
      expect(yearlyPurchased.subscriptionPlan, 'yearly');
      expect(yearlyPurchased.remainingProDays, greaterThanOrEqualTo(364));
    });
  });
}
