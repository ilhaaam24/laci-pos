import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/svg.dart';
import 'package:laci/core/style/app_colors.dart';
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
    final planLabel = businessInfo.subscriptionPlan == 'yearly'
        ? 'Paket Tahunan'
        : businessInfo.subscriptionPlan == 'monthly'
            ? 'Paket Bulanan'
            : 'Lisensi Pro';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
          width: 1.5,
        ),
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
                  '$planLabel • Sisa masa aktif: $remainingDays hari',
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
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            color: const Color(0xFFD97706),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onUpgradeTap,
          ),
        ],
      ),
    );
  }

  // Free Tier Card
  return InkWell(
    onTap: onUpgradeTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: SvgPicture.asset(
              "assets/icons/premium.svg",
              fit: BoxFit.contain,
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
                    const Flexible(
                      child: Text(
                        'Upgrade ke Laci POS Pro',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const ProBadge(),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Akses multi-kasir, produk unlimited, dan laporan laba kotor',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Lihat Paket',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
        expect(find.text('Lihat Paket'), findsOneWidget);
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
        expect(tester.takeException(), isNull);
      });
    }
  });
}
