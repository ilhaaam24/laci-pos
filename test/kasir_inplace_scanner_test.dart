import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laci/core/style/app_colors.dart';

Widget _buildTestEmbeddedScannerView({
  required bool isDark,
  required bool isScannerTorchOn,
  required String? lastScannedProductName,
  required bool lastScanSuccess,
  required VoidCallback onToggleTorch,
  required VoidCallback onClose,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      final availableHeight = constraints.maxHeight;

      final targetBoxSize = math.min(
        math.min(availableWidth * 0.75, availableHeight * 0.65),
        260.0,
      );
      final boxSize = targetBoxSize < 140.0 ? 140.0 : targetBoxSize;
      final isCompactWidth = availableWidth < 460;
      final isShortScreen = availableHeight < 320;

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // Dummy Camera Background
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Text(
                    'Camera Feed Preview',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ),
              ),

              // Viewfinder Overlay
              Center(
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      // Center target line
                      Center(
                        child: Container(
                          height: 1.5,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Floating Controls Header
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompactWidth ? 8 : 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isCompactWidth
                                ? 'Scan'
                                : (isShortScreen ? 'Scan Aktif' : 'Continuous Scan'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Torch Button
                    Material(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onToggleTorch,
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Icon(
                            isScannerTorchOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: isScannerTorchOn ? Colors.amber : Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Close Button
                    Material(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: onClose,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompactWidth ? 8 : 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.6),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              if (!isCompactWidth && !isShortScreen) ...[
                                const SizedBox(width: 4),
                                const Text(
                                  'Tutup',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Notification Feedback
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (lastScannedProductName != null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: lastScanSuccess
                              ? const Color(0xFF065F46).withValues(alpha: 0.92)
                              : const Color(0xFF991B1B).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: lastScanSuccess
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF87171),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              lastScanSuccess
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                lastScannedProductName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Hint text
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Arahkan barcode ke dalam kotak untuk memindai berturut-turut',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void main() {
  group('In-Place Continuous Barcode Scanner Tests', () {
    testWidgets(
      'Embedded scanner renders on phone portrait (390 x 844) without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 390,
                height: 500,
                child: _buildTestEmbeddedScannerView(
                  isDark: false,
                  isScannerTorchOn: false,
                  lastScannedProductName: null,
                  lastScanSuccess: true,
                  onToggleTorch: () {},
                  onClose: () {},
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Scan'), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Embedded scanner renders on phone landscape short screen (844 x 390) without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(844, 390);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 450,
                height: 310, // Short screen height available for catalog/scanner
                child: _buildTestEmbeddedScannerView(
                  isDark: true,
                  isScannerTorchOn: true,
                  lastScannedProductName: 'Kopi Susu Gula Aren (+1)',
                  lastScanSuccess: true,
                  onToggleTorch: () {},
                  onClose: () {},
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        // On compact screen (<460 width), text adapts to 'Scan'
        expect(find.text('Scan'), findsOneWidget);
        expect(find.text('Kopi Susu Gula Aren (+1)'), findsOneWidget);
      },
    );

    testWidgets(
      'Embedded scanner renders on tablet (1280 x 800) middle column without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        bool closed = false;
        bool torchToggled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 650,
                height: 720,
                child: _buildTestEmbeddedScannerView(
                  isDark: false,
                  isScannerTorchOn: false,
                  lastScannedProductName: 'Produk Tidak Ditemukan: 123456',
                  lastScanSuccess: false,
                  onToggleTorch: () => torchToggled = true,
                  onClose: () => closed = true,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Continuous Scan'), findsOneWidget);
        expect(
          find.text('Produk Tidak Ditemukan: 123456'),
          findsOneWidget,
        );

        // Tap Close button
        await tester.tap(find.text('Tutup'));
        await tester.pump();
        expect(closed, isTrue);

        // Tap Torch button
        await tester.tap(find.byIcon(Icons.flash_off_rounded));
        await tester.pump();
        expect(torchToggled, isTrue);
      },
    );
  });
}
