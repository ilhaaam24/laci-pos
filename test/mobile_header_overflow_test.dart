import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laci/core/style/app_colors.dart';

Widget _buildTestMobileHeader({
  required bool isDark,
  required String businessName,
  required String staffName,
  required String roleName,
  required bool isShiftOpen,
  required int openBillCount,
}) {
  final initial = staffName.isNotEmpty ? staffName[0].toUpperCase() : 'K';

  return Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
    child: Row(
      children: [
        // Left: Logo + Store Name + Cashier Subtitle
        Expanded(
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      businessName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isShiftOpen
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$staffName • $roleName',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // Staff PIN Lock Badge
        Container(
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
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
                radius: 10.5,
                backgroundColor: AppColors.primary,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // Shift Status Badge
        Container(
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isShiftOpen
                ? (isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                      : const Color(0xFFECFDF5))
                : (isDark
                      ? const Color(0xFF78350F).withValues(alpha: 0.35)
                      : const Color(0xFFFFFBEB)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isShiftOpen
                  ? (isDark
                        ? const Color(0xFF059669).withValues(alpha: 0.5)
                        : const Color(0xFFA7F3D0))
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
                size: 14,
                color: isShiftOpen
                    ? (isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF059669))
                    : (isDark
                          ? const Color(0xFFFCD34D)
                          : const Color(0xFFD97706)),
              ),
              const SizedBox(width: 4),
              Text(
                isShiftOpen ? 'Shift' : 'Buka',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isShiftOpen
                      ? (isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF059669))
                      : (isDark
                            ? const Color(0xFFFCD34D)
                            : const Color(0xFFD97706)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // Open Bill Badge
        Container(
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: openBillCount > 0
                ? (isDark
                      ? const Color(0xFF78350F).withValues(alpha: 0.35)
                      : const Color(0xFFFEF3C7))
                : (isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(10),
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
                size: 16,
                color: openBillCount > 0
                    ? const Color(0xFFD97706)
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 4),
              if (openBillCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$openBillCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                )
              else
                Text(
                  '0',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

void main() {
  group('Mobile Header Overflow & Layout Tests', () {
    final phoneWidths = [
      320.0, // Smallest phone (iPhone SE 1st gen)
      360.0, // Standard small Android
      375.0, // iPhone SE 2nd/3rd gen, iPhone 8
      390.0, // iPhone 13/14/15/16 standard
      414.0, // iPhone Plus / Max older
      430.0, // iPhone 15/16 Pro Max
    ];

    for (final width in phoneWidths) {
      testWidgets(
        'Renders mobile header safely without overflow on width: $width dp',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width,
                    child: _buildTestMobileHeader(
                      isDark: false,
                      businessName: 'Kedai Kopi Kenangan Super Panjang Sekali',
                      staffName: 'Muhammad Ilham Ramadhan',
                      roleName: 'Kasir',
                      isShiftOpen: true,
                      openBillCount: 2,
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Crucial: Zero RenderFlex overflow exception
          expect(tester.takeException(), isNull);

          // All 3 badges rendered
          expect(find.text('M'), findsOneWidget); // Staff avatar initial
          expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget); // Staff PIN lock icon
          expect(find.text('Shift'), findsOneWidget); // Shift active badge
          expect(find.text('2'), findsOneWidget); // Open bill count
        },
      );

      testWidgets(
        'Renders mobile header with closed shift and zero bills on width: $width dp (dark mode)',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width,
                    child: _buildTestMobileHeader(
                      isDark: true,
                      businessName: 'Laci POS',
                      staffName: 'Budi',
                      roleName: 'Owner',
                      isShiftOpen: false,
                      openBillCount: 0,
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('B'), findsOneWidget);
          expect(find.text('Buka'), findsOneWidget);
          expect(find.text('0'), findsOneWidget);
        },
      );
    }
  });
}
