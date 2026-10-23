import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laci/domain/entities/business_entity.dart';
import 'package:laci/presentation/widgets/pro_badge.dart';

Widget _buildTestProMembershipCard({
  required BusinessInfo businessInfo,
  required bool isDark,
  required VoidCallback onUpgradeTap,
}) {
  final isPro = businessInfo.isPro;

  if (isPro) {
    final remainingDays = businessInfo.remainingProDays;
    final isLifetime =
        businessInfo.subscriptionPlan == 'lifetime' || remainingDays > 3650;
    final planLabel = isLifetime
        ? 'Lisensi Lifetime'
        : businessInfo.subscriptionPlan == 'yearly'
            ? 'Paket Tahunan'
            : businessInfo.subscriptionPlan == 'monthly'
                ? 'Paket Bulanan'
                : 'Lisensi Pro';
    final expiryLabel =
        isLifetime ? 'Aktif Selamanya' : 'Sisa masa aktif: $remainingDays hari';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Laci POS Pro Aktif',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const ProBadge(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$planLabel • $expiryLabel',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Verified Active Badge (No Paywall triggered)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: Color(0xFF059669),
                ),
                SizedBox(width: 4),
                Text(
                  'Aktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Free Tier Card with CTA Button
  return Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onUpgradeTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Upgrade ke Laci POS Pro',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const ProBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Buka semua fitur tanpa batas',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Dedicated CTA Button
              ElevatedButton(
                onPressed: onUpgradeTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14),
                    SizedBox(width: 3),
                    Text(
                      'Aktivasi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Pro Membership Card Responsiveness & Overflow Tests', () {
    final widths = [320.0, 360.0, 375.0, 390.0, 412.0];

    for (final width in widths) {
      testWidgets('Renders Free Membership Card on width $width without overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final freeInfo = BusinessInfo(
          id: 'b1',
          businessName: 'Toko Test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          subscriptionTier: 'free',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTestProMembershipCard(
                  businessInfo: freeInfo,
                  isDark: false,
                  onUpgradeTap: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Upgrade ke Laci POS Pro'), findsOneWidget);
        expect(find.text('Aktivasi'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Renders Pro Active Membership Card on width $width without overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final proInfo = BusinessInfo(
          id: 'b1',
          businessName: 'Toko Test Pro',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          subscriptionTier: 'pro',
          subscriptionPlan: 'yearly',
          subscriptionExpiresAt: DateTime.now().add(const Duration(days: 300)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTestProMembershipCard(
                  businessInfo: proInfo,
                  isDark: false,
                  onUpgradeTap: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Laci POS Pro Aktif'), findsOneWidget);
        expect(find.text('Aktif'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
