import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:laci/core/style/app_colors.dart';
import 'package:laci/domain/entities/transaction_entity.dart';
import 'package:laci/presentation/blocs/cart/cart_bloc.dart';

Widget _buildTestFloatingCartBanner({
  required BuildContext context,
  required CartState state,
  required NumberFormat formatter,
  required VoidCallback onSaveBill,
  required VoidCallback onOpenOrders,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final screenWidth = MediaQuery.of(context).size.width;

  final totalQuantity = state.items.fold(0, (sum, item) => sum + item.quantity);

  return Positioned(
    bottom: 12,
    left: 14,
    right: 14,
    child: Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : AppColors.textSecondary.withValues(alpha: 0.2),
          width: 0.5,
        ),
        color: isDark ? const Color(0xFF1E293B) : AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Left: Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$totalQuantity',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Middle: Quantity & Subtotal in Expanded
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalQuantity Item Terpilih',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatter.format(state.totalAmount).trim(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Tahan Bill Button
          Tooltip(
            message: 'Tahan Pesanan (Open Bill)',
            child: InkWell(
              onTap: onSaveBill,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 38,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth >= 360 ? 9 : 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF78350F)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (screenWidth >= 360) ...[
                      const SizedBox(width: 4),
                      Text(
                        'Tahan',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFFCD34D)
                              : const Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Right: CTA Button
          InkWell(
            onTap: onOpenOrders,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pesanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('FloatingCartBanner Overflow & Responsiveness Tests', () {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final testItem = TransactionItem(
      id: 'it_1',
      productId: 'p_1',
      productName: 'Kopi Kenangan Mantan Gula Aren Extra',
      price: 15000000,
      costPrice: 5000000,
      quantity: 99,
      subtotal: 15000000,
    );

    final cartState = CartState(items: [testItem], totalAmount: 15000000);

    for (final width in [320.0, 360.0, 375.0, 390.0, 412.0]) {
      testWidgets('Renders without overflow on width: $width dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Builder(
                    builder: (context) => _buildTestFloatingCartBanner(
                      context: context,
                      state: cartState,
                      formatter: formatter,
                      onSaveBill: () {},
                      onOpenOrders: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify "Tahan" button
        if (width >= 360) {
          expect(find.text('Tahan'), findsOneWidget);
        }

        // Verify CTA button is rendered as 'Pesanan'
        expect(find.text('Pesanan'), findsOneWidget);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
