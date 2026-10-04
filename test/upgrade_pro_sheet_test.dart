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
    testWidgets('Renders header, Free vs PRO comparison, and Lifetime pricing card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradeProContent(),
          ),
        ),
      );

      expect(find.text('Laci POS'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);

      // Verify Comparison Table
      expect(find.text('FITUR BISNIS'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('PRO 👑'), findsOneWidget);

      expect(find.text('Katalog Produk'), findsOneWidget);
      expect(find.text('Maks 150'), findsOneWidget);
      expect(find.text('Tanpa Batas 🚀'), findsOneWidget);

      expect(find.text('Multi-Kasir & PIN'), findsOneWidget);
      expect(find.text('1 Kasir'), findsOneWidget);
      expect(find.text('Banyak Staf 👥'), findsOneWidget);

      expect(find.text('Laporan Laba & HPP'), findsOneWidget);
      expect(find.text('Export Excel & PDF'), findsOneWidget);
      expect(find.text('Logo & Bebas Watermark'), findsOneWidget);
      expect(find.text('Cloud Backup & Sync'), findsOneWidget);

      // Verify Lifetime Pricing
      expect(find.text('SEKALI BAYAR • AKTIF SELAMANYA'), findsOneWidget);
      expect(find.text('Hemat 67%'), findsOneWidget);
      expect(find.text('Rp 49.000'), findsOneWidget);
      expect(find.text('Rp 149.000'), findsOneWidget);

      // Default CTA button
      expect(
        find.text('Beli Lisensi via WhatsApp (Rp 49.000)'),
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

    testWidgets('Renders and triggers voucher activation button when callback provided', (tester) async {
      bool voucherTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpgradeProContent(
              onVoucherTap: () => voucherTapped = true,
            ),
          ),
        ),
      );

      final voucherBtn = find.text('Sudah Punya Kode Voucher? Aktivasi di Sini');
      expect(voucherBtn, findsOneWidget);

      await tester.ensureVisible(voucherBtn);
      await tester.tap(voucherBtn);
      await tester.pumpAndSettle();

      expect(voucherTapped, isTrue);
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
