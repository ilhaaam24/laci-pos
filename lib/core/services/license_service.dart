import '../../domain/entities/business_entity.dart';

class VoucherValidationResult {
  final bool isValid;
  final String? plan; // 'monthly', 'yearly', 'lifetime'
  final int durationDays;
  final String? errorMessage;

  const VoucherValidationResult({
    required this.isValid,
    this.plan,
    this.durationDays = 0,
    this.errorMessage,
  });
}

class LicenseService {
  // Secret salt used to generate and verify valid voucher codes
  static const String _licenseSalt = 'LACI_POS_PRO_SECRET_KEY_2026';

  /// Pure Dart 32-bit DJB2 polynomial checksum generator.
  /// Generates a consistent 4-character uppercase alphanumeric checksum.
  static String _calculateChecksum(String input) {
    int hash = 5381;
    for (int i = 0; i < input.length; i++) {
      hash = (((hash << 5) + hash) + input.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    final hex = hash.toRadixString(16).toUpperCase().padLeft(4, '0');
    return hex.length >= 4 ? hex.substring(hex.length - 4) : hex.padLeft(4, '0');
  }

  /// Generates a valid offline license code for a specific plan and sequence/order number.
  /// Format: `PRO<DAYS>-<ORDER_ID>-<CHECKSUM>`
  /// Example: `PRO365-9821-A7F2`
  static String generateVoucherCode({
    required String plan, // 'monthly' (30), 'yearly' (365), 'lifetime' (36500)
    required String orderId,
  }) {
    final cleanOrder = orderId.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final prefix = plan == 'monthly'
        ? 'PRO30'
        : plan == 'yearly'
            ? 'PRO365'
            : 'PROLIFE';

    final dataToHash = '$prefix-$cleanOrder-$_licenseSalt';
    final checksum = _calculateChecksum(dataToHash);

    return '$prefix-$cleanOrder-$checksum';
  }

  /// Validates a voucher code string.
  /// Supports:
  /// 1. Algorithmic checksum vouchers (generated via `generateVoucherCode`)
  /// 2. Official promotional demo codes (for easy testing & launch promotions)
  static VoucherValidationResult validateCode(String rawCode) {
    final code = rawCode.trim().toUpperCase().replaceAll(' ', '');

    if (code.isEmpty) {
      return const VoucherValidationResult(
        isValid: false,
        errorMessage: 'Kode lisensi tidak boleh kosong',
      );
    }

    // 1. Promotional demo / tester codes
    if (code == 'PRO-BULANAN-2026' || code == 'PRO-MONTHLY' || code == 'LACI30') {
      return const VoucherValidationResult(
        isValid: true,
        plan: 'monthly',
        durationDays: 30,
      );
    }

    if (code == 'PRO-TAHUNAN-2026' || code == 'PRO-YEARLY' || code == 'LACI365') {
      return const VoucherValidationResult(
        isValid: true,
        plan: 'yearly',
        durationDays: 365,
      );
    }

    if (code == 'PRO-LIFETIME-2026' || code == 'LACILIFETIME') {
      return const VoucherValidationResult(
        isValid: true,
        plan: 'lifetime',
        durationDays: 36500, // 100 years
      );
    }

    // 2. Cryptographic vouchers check
    // Format: `PREFIX-ORDER-CHECKSUM`
    final parts = code.split('-');
    if (parts.length == 3) {
      final prefix = parts[0];
      final orderId = parts[1];
      final checksum = parts[2];

      int days = 0;
      String plan = 'monthly';
      if (prefix == 'PRO30') {
        days = 30;
        plan = 'monthly';
      } else if (prefix == 'PRO365') {
        days = 365;
        plan = 'yearly';
      } else if (prefix == 'PROLIFE') {
        days = 36500;
        plan = 'lifetime';
      } else {
        return const VoucherValidationResult(
          isValid: false,
          errorMessage: 'Format kode lisensi tidak dikenali',
        );
      }

      final expectedData = '$prefix-$orderId-$_licenseSalt';
      final expectedChecksum = _calculateChecksum(expectedData);

      if (checksum == expectedChecksum) {
        return VoucherValidationResult(
          isValid: true,
          plan: plan,
          durationDays: days,
        );
      }
    }

    return const VoucherValidationResult(
      isValid: false,
      errorMessage: 'Kode lisensi tidak valid atau salah ketik',
    );
  }

  /// Calculates the new expiration date when activating a voucher.
  /// Stacks with remaining days if the business is already Pro.
  static BusinessInfo applyVoucherToBusiness({
    required BusinessInfo current,
    required VoucherValidationResult voucher,
  }) {
    final now = DateTime.now();
    DateTime baseDate = now;

    // If currently active Pro, stack the duration onto the current expiration date
    if (current.isPro && current.subscriptionExpiresAt != null) {
      baseDate = current.subscriptionExpiresAt!;
    }

    final newExpiresAt = baseDate.add(Duration(days: voucher.durationDays));

    return current.copyWith(
      subscriptionTier: 'pro',
      subscriptionExpiresAt: newExpiresAt,
      subscriptionPlan: voucher.plan,
      updatedAt: now,
    );
  }
}
