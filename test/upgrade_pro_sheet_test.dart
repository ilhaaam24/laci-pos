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
    testWidgets('Renders all feature items and default Yearly plan', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradeProContent(),
          ),
        ),
      );

      expect(find.text('Laci POS'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('Katalog Produk Tanpa Batas'), findsOneWidget);
      expect(find.text('Multi-Kasir & PIN Cepat'), findsOneWidget);
      expect(find.text('Laporan Laba Kotor & Analisis HPP'), findsOneWidget);
      expect(find.text('Export Dokumen Excel & PDF'), findsOneWidget);
      expect(find.text('Logo Toko & Bebas Watermark'), findsOneWidget);
      expect(find.text('Cloud Backup & Multi-Perangkat'), findsOneWidget);

      // Verify Pricing
      expect(find.text('Tahunan'), findsOneWidget);
      expect(find.textContaining('30%'), findsOneWidget);
      expect(find.text('Rp 249.000'), findsOneWidget);
      expect(find.text('Bulanan'), findsOneWidget);
      expect(find.text('Rp 29.000'), findsOneWidget);

      // Default CTA button
      expect(
        find.text('Upgrade Sekarang (Rp 249.000 / Tahun)'),
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

    testWidgets('Toggling to Monthly changes CTA button label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpgradeProContent(),
          ),
        ),
      );

      // Tap Monthly card
      await tester.tap(find.text('Bulanan'));
      await tester.pumpAndSettle();

      expect(
        find.text('Upgrade Sekarang (Rp 29.000 / Bulan)'),
        findsOneWidget,
      );

      // Tap Yearly card back
      await tester.tap(find.text('Tahunan'));
      await tester.pumpAndSettle();

      expect(
        find.text('Upgrade Sekarang (Rp 249.000 / Tahun)'),
        findsOneWidget,
      );
    });
  });
}
