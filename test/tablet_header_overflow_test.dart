import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laci/core/style/app_colors.dart';

Widget _buildTestTabletHeader({
  required bool isDark,
  required bool isPortrait,
  required String businessName,
  required bool isGridView,
  required bool isShiftOpen,
  required int openBillCount,
  required TextEditingController searchController,
  required ValueChanged<bool> onToggleView,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isCompact = isPortrait || constraints.maxWidth < 620;

      return Container(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: 10,
        ),
        child: Row(
            children: [
              // Center Search Box
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.search_rounded, size: 18),
                    ),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: isCompact
                              ? 'Cari...'
                              : 'Cari produk atau SKU...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // View Mode Toggle
            isCompact
                ? Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isGridView
                            ? Icons.format_list_bulleted_rounded
                            : Icons.grid_view_rounded,
                        size: 18,
                      ),
                      onPressed: () => onToggleView(!isGridView),
                    ),
                  )
                : Container(
                    height: 38,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          color: isGridView
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.format_list_bulleted_rounded,
                          color: !isGridView
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
            const SizedBox(width: 6),

            // Shift Badge
            isCompact
                ? Container(
                    height: 38,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isShiftOpen
                          ? AppColors.primary
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isShiftOpen
                            ? const Color(0xFF10B981).withValues(alpha: 0.5)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      isShiftOpen
                          ? Icons.lock_open_rounded
                          : Icons.lock_outline_rounded,
                      size: 18,
                      color: isShiftOpen
                          ? Colors.white
                          : const Color(0xFF92400E),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isShiftOpen
                          ? AppColors.primary
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isShiftOpen ? 'Shift: Kasir' : 'Buka Shift',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            const SizedBox(width: 6),

            // Open Bill Badge
            isCompact
                ? Container(
                    height: 38,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(
                      horizontal: openBillCount > 0 ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: openBillCount > 0
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: openBillCount > 0
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 18),
                        if (openBillCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$openBillCount',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: openBillCount > 0
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          'Open Bill ($openBillCount)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      );
    },
  );
}

void main() {
  group('Tablet Header Responsive & Overflow Tests', () {
    late TextEditingController searchController;

    setUp(() {
      searchController = TextEditingController();
    });

    tearDown(() {
      searchController.dispose();
    });

    // Test across tablet portrait widths:
    // 768 width (iPad Portrait: 768 - 92 - 350 = 326)
    // 800 width (Galaxy Tab Portrait: 800 - 92 - 350 = 358)
    // 820 width (iPad Air Portrait: 820 - 92 - 350 = 378)
    // Extreme narrow split-screen width: 280
    for (final middleColumnWidth in [280.0, 326.0, 358.0, 378.0]) {
      testWidgets(
        'Renders without overflow on portrait middle column width: $middleColumnWidth dp',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: middleColumnWidth,
                    child: _buildTestTabletHeader(
                      isDark: false,
                      isPortrait: true,
                      businessName: 'Toko Kopi Kenangan Super Panjang Sekali',
                      isGridView: true,
                      isShiftOpen: true,
                      openBillCount: 3,
                      searchController: searchController,
                      onToggleView: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Zero RenderFlex overflow exception
          expect(tester.takeException(), isNull);

          // Store name is omitted in portrait/compact to allow search bar breathing room
          expect(
            find.text('Toko Kopi Kenangan Super Panjang Sekali'),
            findsNothing,
          );
          expect(find.text('Mode Kasir POS'), findsNothing);

          // Search bar is visible with compact hint
          expect(find.text('Cari...'), findsOneWidget);

          // Compact lock icon for active shift is visible
          expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);

          // Bill count badge is visible
          expect(find.text('3'), findsOneWidget);

          // Single toggle button icon is present
          expect(
            find.byIcon(Icons.format_list_bulleted_rounded),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets('Renders spacious search bar & controls on wide landscape tablet (width: 700+ dp)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 750.0,
                child: _buildTestTabletHeader(
                  isDark: false,
                  isPortrait: false,
                  businessName: 'Kedai Kopi Laci',
                  isGridView: true,
                  isShiftOpen: true,
                  openBillCount: 2,
                  searchController: searchController,
                  onToggleView: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Logo and store branding is omitted in landscape mode too to keep header spacious and uncluttered
      expect(find.text('Kedai Kopi Laci'), findsNothing);
      expect(find.text('Mode Kasir POS'), findsNothing);

      // Search bar full hint
      expect(find.text('Cari produk atau SKU...'), findsOneWidget);

      // Full shift pill text is visible
      expect(find.text('Shift: Kasir'), findsOneWidget);

      // Full Open Bill pill text is visible
      expect(find.text('Open Bill (2)'), findsOneWidget);
    });
  });
}
