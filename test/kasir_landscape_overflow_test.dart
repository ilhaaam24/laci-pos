import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laci/core/style/app_colors.dart';

Widget _buildTestLandscapeHeader({
  required bool isDark,
  required TextEditingController searchController,
  required bool isGridView,
  required bool isShiftOpen,
  required int openBillCount,
  required ValueChanged<bool> onToggleView,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 620;
      final isUltraCompact = constraints.maxWidth < 480;

      return Container(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isUltraCompact ? 8 : (isCompact ? 10 : 16),
          vertical: isUltraCompact ? 7 : 10,
        ),
        child: Row(
          children: [
            // Center Search Box with Barcode Scan
            Expanded(
              child: Container(
                height: isUltraCompact ? 36 : 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(
                    isUltraCompact ? 10 : 12,
                  ),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: isUltraCompact ? 8 : 10,
                        right: isUltraCompact ? 4 : 8,
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        size: isUltraCompact ? 16 : 18,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontSize: isUltraCompact ? 12 : 13,
                        ),
                        decoration: InputDecoration(
                          hintText: isUltraCompact
                              ? 'Cari...'
                              : (isCompact
                                  ? 'Cari produk...'
                                  : 'Cari produk atau SKU...'),
                          hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontSize: isUltraCompact ? 12 : 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isUltraCompact ? 6 : 10,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isUltraCompact ? 30 : 34,
                      height: isUltraCompact ? 30 : 34,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppColors.primary,
                          size: isUltraCompact ? 18 : 20,
                        ),
                        onPressed: () {},
                      ),
                    ),
                    SizedBox(width: isUltraCompact ? 4 : 6),
                  ],
                ),
              ),
            ),
            SizedBox(width: isUltraCompact ? 5 : 8),

            // View Mode Toggle
            Container(
              height: isUltraCompact ? 34 : 38,
              width: isUltraCompact ? 34 : 38,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(
                  isUltraCompact ? 8 : 10,
                ),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isGridView
                      ? Icons.format_list_bulleted_rounded
                      : Icons.grid_view_rounded,
                  size: isUltraCompact ? 16 : 18,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                onPressed: () => onToggleView(!isGridView),
              ),
            ),
            SizedBox(width: isUltraCompact ? 4 : 6),

            // Staff Badge
            Container(
              height: isUltraCompact ? 34 : 36,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: isUltraCompact ? 5 : 7,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(
                  isUltraCompact ? 8 : 10,
                ),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: isUltraCompact ? 9 : 10.5,
                    backgroundColor: AppColors.primary,
                    child: const Text(
                      'K',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: isUltraCompact ? 3 : 4),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: isUltraCompact ? 12 : 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
            SizedBox(width: isUltraCompact ? 4 : 6),

            // Shift Badge
            Container(
              height: isUltraCompact ? 34 : 36,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: isUltraCompact ? 7 : 8,
              ),
              decoration: BoxDecoration(
                color: isShiftOpen
                    ? (isDark
                          ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                          : Colors.transparent)
                    : (isDark
                          ? const Color(0xFF78350F).withValues(alpha: 0.35)
                          : const Color(0xFFFFFBEB)),
                borderRadius: BorderRadius.circular(
                  isUltraCompact ? 8 : 10,
                ),
                border: Border.all(
                  color: isShiftOpen
                      ? (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0))
                      : (isDark
                            ? const Color(0xFFD97706).withValues(alpha: 0.5)
                            : const Color(0xFFFDE68A)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isShiftOpen
                        ? Icons.lock_open_rounded
                        : Icons.lock_outline_rounded,
                    size: isUltraCompact ? 13 : 14,
                    color: isShiftOpen
                        ? (isDark
                              ? const Color(0xFF34D399)
                              : AppColors.textSecondary)
                        : (isDark
                              ? const Color(0xFFFCD34D)
                              : const Color(0xFFD97706)),
                  ),
                  if (!isUltraCompact) ...[
                    const SizedBox(width: 4),
                    Text(
                      isShiftOpen ? 'Shift' : 'Buka',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: isUltraCompact ? 4 : 6),

            // Open Bill Badge
            Container(
              height: isUltraCompact ? 34 : 36,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: isUltraCompact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: openBillCount > 0
                    ? (isDark
                          ? const Color(0xFF78350F).withValues(alpha: 0.35)
                          : const Color(0xFFFEF3C7))
                    : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(
                  isUltraCompact ? 8 : 10,
                ),
                border: Border.all(
                  color: openBillCount > 0
                      ? (isDark
                            ? const Color(0xFFD97706).withValues(alpha: 0.5)
                            : const Color(0xFFF59E0B))
                      : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: isUltraCompact ? 14 : 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$openBillCount',
                    style: TextStyle(
                      fontSize: isUltraCompact ? 10 : 11,
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

Widget _buildTestLandscapeCartPanel({
  required bool isDark,
  required double screenHeight,
  required double panelWidth,
  required int itemCount,
}) {
  final isShortScreen = screenHeight < 520;

  return SizedBox(
    width: panelWidth,
    height: screenHeight,
    child: Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        children: [
          // Quick actions (1x4 on short screen)
          Padding(
            padding: EdgeInsets.fromLTRB(
              isShortScreen ? 10 : 14,
              isShortScreen ? 8 : 12,
              isShortScreen ? 10 : 14,
              isShortScreen ? 6 : 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Customer', style: TextStyle(fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Tables', style: TextStyle(fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Discount', style: TextStyle(fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Save Bill', style: TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Order details
          Padding(
            padding: EdgeInsets.fromLTRB(
              isShortScreen ? 10 : 14,
              isShortScreen ? 6 : 10,
              isShortScreen ? 10 : 14,
              isShortScreen ? 4 : 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: isShortScreen ? 13.5 : 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  height: isShortScreen ? 28 : 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  child: const Text('Dine In', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),

          // Items or empty state
          Expanded(
            child: itemCount == 0
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(isShortScreen ? 10 : 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: isShortScreen ? 32 : 48),
                          SizedBox(height: isShortScreen ? 6 : 12),
                          Text(
                            'Belum Ada Pesanan',
                            style: TextStyle(
                              fontSize: isShortScreen ? 12 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: itemCount,
                    padding: EdgeInsets.symmetric(
                      horizontal: isShortScreen ? 10 : 14,
                      vertical: isShortScreen ? 4 : 8,
                    ),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('Item ${i + 1} - Rp 10.000'),
                    ),
                  ),
          ),

          // Summary box
          Padding(
            padding: EdgeInsets.fromLTRB(
              isShortScreen ? 10 : 14,
              isShortScreen ? 2 : 4,
              isShortScreen ? 10 : 14,
              isShortScreen ? 6 : 10,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isShortScreen ? 10 : 12,
                vertical: isShortScreen ? 6 : 12,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(isShortScreen ? 10 : 12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal', style: TextStyle(fontSize: isShortScreen ? 11 : 12)),
                      Text('Rp 0', style: TextStyle(fontSize: isShortScreen ? 11 : 12)),
                    ],
                  ),
                  SizedBox(height: isShortScreen ? 3 : 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tax (10%)', style: TextStyle(fontSize: isShortScreen ? 11 : 12)),
                      Text('Rp 0', style: TextStyle(fontSize: isShortScreen ? 11 : 12)),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: isShortScreen ? 4 : 8),
                    child: const Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: TextStyle(fontSize: isShortScreen ? 13 : 15, fontWeight: FontWeight.bold)),
                      Text('Rp 0', style: TextStyle(fontSize: isShortScreen ? 15 : 17, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
              isShortScreen ? 10 : 14,
              0,
              isShortScreen ? 10 : 14,
              isShortScreen ? 8 : 14,
            ),
            child: Row(
              children: [
                SizedBox(
                  height: isShortScreen ? 38 : 46,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Text('Tahan', style: TextStyle(fontSize: isShortScreen ? 12 : 13)),
                  ),
                ),
                SizedBox(width: isShortScreen ? 6 : 8),
                Expanded(
                  child: SizedBox(
                    height: isShortScreen ? 38 : 46,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text('Proses Transaksi', style: TextStyle(fontSize: isShortScreen ? 12.5 : 14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('Kasir Landscape Phone Responsive & Zero-Overflow Tests', () {
    late TextEditingController searchController;

    setUp(() {
      searchController = TextEditingController();
    });

    tearDown(() {
      searchController.dispose();
    });

    // 1. Test middle column header widths on landscape smartphones (300 - 410 dp)
    for (final middleWidth in [300.0, 320.0, 350.0, 380.0, 410.0]) {
      testWidgets('Header renders without horizontal overflow on narrow middle column width: $middleWidth dp', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: middleWidth,
                  child: _buildTestLandscapeHeader(
                    isDark: false,
                    searchController: searchController,
                    isGridView: true,
                    isShiftOpen: true,
                    openBillCount: 0,
                    onToggleView: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Must NOT throw any RenderFlex overflow exceptions
        expect(tester.takeException(), isNull);

        // Search text field hint is visible
        expect(find.text('Cari...'), findsOneWidget);

        // Barcode scanner icon is visible
        expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      });
    }

    // 2. Test cart panel heights on landscape smartphones (340 - 420 dp)
    for (final screenHeight in [340.0, 360.0, 380.0, 400.0, 420.0]) {
      testWidgets('Cart panel renders without vertical overflow on short landscape height: $screenHeight dp (empty cart)', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: _buildTestLandscapeCartPanel(
                  isDark: false,
                  screenHeight: screenHeight,
                  panelWidth: 315.0,
                  itemCount: 0,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Must NOT have any RenderFlex overflow
        expect(tester.takeException(), isNull);

        // Essential actions and buttons must be visible
        expect(find.text('Customer'), findsOneWidget);
        expect(find.text('Tables'), findsOneWidget);
        expect(find.text('Discount'), findsOneWidget);
        expect(find.text('Save Bill'), findsOneWidget);
        expect(find.text('Belum Ada Pesanan'), findsOneWidget);
        expect(find.text('Tahan'), findsOneWidget);
        expect(find.text('Proses Transaksi'), findsOneWidget);
      });

      testWidgets('Cart panel renders without vertical overflow on short landscape height: $screenHeight dp (with items)', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: _buildTestLandscapeCartPanel(
                  isDark: false,
                  screenHeight: screenHeight,
                  panelWidth: 315.0,
                  itemCount: 5,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Must NOT have any RenderFlex overflow
        expect(tester.takeException(), isNull);
        expect(find.text('Proses Transaksi'), findsOneWidget);
      });
    }
  });
}
