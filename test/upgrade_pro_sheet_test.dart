import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laci/presentation/widgets/pro_badge.dart';
import 'package:laci/presentation/widgets/upgrade_pro_sheet.dart';

void main() {
  group('ProBadge Widget Tests', () {
    testWidgets('ProBadge renders with PRO text and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: ProBadge()),
          ),
        ),
      );

      expect(find.text('PRO'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });

    testWidgets('ProBadge triggers onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProBadge(onTap: () => tapped = true),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProBadge));
      expect(tapped, isTrue);
    });
  });

  group('UpgradeProContent Widget Tests', () {
    testWidgets('Renders header, minimalist feature checklist, and pricing card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradeProContent(),
          ),
        ),
      );

      expect(find.text('Laci POS'), findsOneWidget);
      expect(find.text('Rp 49.000 • Sekali Bayar Selamanya'), findsOneWidget);

      // Verify Minimalist Feature Checklist
      expect(find.text('FITUR UNGGULAN PRO'), findsOneWidget);
      expect(find.text('Katalog Produk & Transaksi Tanpa Batas'), findsOneWidget);
      expect(find.text('Multi-Kasir & Hak Akses PIN Staf'), findsOneWidget);
      expect(find.text('Laporan Laba/Rugi & Export Excel/PDF'), findsOneWidget);
      expect(find.text('Cetak Struk Tanpa Watermark + Logo Toko'), findsOneWidget);

      // Verify Pricing
      expect(find.text('Rp 49.000'), findsOneWidget);
      expect(find.text('Rp 149.000'), findsOneWidget);
      expect(find.text('Hemat 67%'), findsOneWidget);
      expect(find.text('Sekali bayar • Tanpa langganan bulanan'), findsOneWidget);

      // Primary CTA button
      expect(
        find.text('Hubungi Admin'),
        findsOneWidget,
      );
    });

    testWidgets('Displays feature lock note when featureName is passed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradeProContent(
              featureName: 'Export Laporan Rekap PDF',
            ),
          ),
        ),
      );

      expect(
        find.text('Fitur ini membutuhkan Pro: Export Laporan Rekap PDF'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    for (final width in [320.0, 360.0, 375.0, 390.0, 414.0]) {
      testWidgets('Renders UpgradeProContent on width $width without overflow', (tester) async {
        tester.view.physicalSize = Size(width, 844.0);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UpgradeProContent(
                featureName: 'Katalog Produk Lebih dari 150 Item',
                onVoucherTap: () {},
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
