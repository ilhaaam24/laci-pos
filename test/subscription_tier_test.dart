import 'package:flutter_test/flutter_test.dart';
import 'package:laci/data/models/business_model.dart';
import 'package:laci/domain/entities/business_entity.dart';

void main() {
  group('BusinessInfo Subscription Tier Tests', () {
    test('Default BusinessInfo is free tier and isPro is false', () {
      final info = BusinessInfo(
        id: 'biz-1',
        businessName: 'Toko Kopi ABC',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(info.subscriptionTier, 'free');
      expect(info.subscriptionExpiresAt, isNull);
      expect(info.isPro, isFalse);
      expect(info.isFree, isTrue);
      expect(info.remainingProDays, 0);
    });

    test('BusinessInfo with active Pro status returns isPro true and correct remaining days', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final info = BusinessInfo(
        id: 'biz-1',
        businessName: 'Toko Kopi ABC',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        subscriptionTier: 'pro',
        subscriptionExpiresAt: futureDate,
        subscriptionPlan: 'monthly',
      );

      expect(info.subscriptionTier, 'pro');
      expect(info.subscriptionPlan, 'monthly');
      expect(info.isPro, isTrue);
      expect(info.isFree, isFalse);
      expect(info.remainingProDays, greaterThanOrEqualTo(29));
      expect(info.remainingProDays, lessThanOrEqualTo(31));
    });

    test('BusinessInfo with expired Pro status returns isPro false', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final info = BusinessInfo(
        id: 'biz-1',
        businessName: 'Toko Kopi ABC',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        subscriptionTier: 'pro',
        subscriptionExpiresAt: pastDate,
      );

      expect(info.isPro, isFalse);
      expect(info.isFree, isTrue);
      expect(info.remainingProDays, 0);
    });

    test('BusinessInfoModel serializes and deserializes subscription tier accurately in JSON', () {
      final futureDate = DateTime(2026, 12, 31, 23, 59, 59);
      final model = BusinessInfoModel(
        id: 'biz-pro-123',
        businessName: 'Kafe Laci',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        subscriptionTier: 'pro',
        subscriptionExpiresAt: futureDate,
        subscriptionPlan: 'yearly',
      );

      final json = model.toJson();
      expect(json['subscriptionTier'], 'pro');
      expect(json['subscriptionExpiresAt'], futureDate.toIso8601String());
      expect(json['subscriptionPlan'], 'yearly');

      final deserialized = BusinessInfoModel.fromJson(json);
      expect(deserialized.id, 'biz-pro-123');
      expect(deserialized.businessName, 'Kafe Laci');
      expect(deserialized.subscriptionTier, 'pro');
      expect(deserialized.subscriptionPlan, 'yearly');
      expect(deserialized.subscriptionExpiresAt, futureDate);
      expect(deserialized.isPro, isTrue);
    });

    test('BusinessInfo copyWith updates subscription tier and expiration correctly', () {
      final base = BusinessInfo(
        id: 'biz-1',
        businessName: 'Toko Kopi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final expiry = DateTime.now().add(const Duration(days: 365));
      final upgraded = base.copyWith(
        subscriptionTier: 'pro',
        subscriptionExpiresAt: expiry,
        subscriptionPlan: 'yearly',
      );

      expect(upgraded.subscriptionTier, 'pro');
      expect(upgraded.subscriptionPlan, 'yearly');
      expect(upgraded.isPro, isTrue);
      expect(base.isPro, isFalse);
    });
  });
}
