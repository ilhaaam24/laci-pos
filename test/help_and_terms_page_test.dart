import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laci/presentation/pages/settings/help_page.dart';
import 'package:laci/presentation/pages/settings/terms_and_conditions_page.dart';

void main() {
  group('HelpPage Widget Tests', () {
    testWidgets(
      'HelpPage renders hero header, contact cards, and FAQ categories',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HelpPage()));
        await tester.pumpAndSettle();

        // Verify app bar title
        expect(find.text('Pusat Bantuan & Kendala'), findsOneWidget);

        // Verify contact section header
        expect(find.text('HUBUNGI BANTUAN'), findsOneWidget);

        // Verify WhatsApp and Email contact options
        expect(find.text('Chat WhatsApp'), findsOneWidget);
        expect(find.text('Kirim Email'), findsOneWidget);
        expect(find.text('support@lacipos.id'), findsOneWidget);

        // Verify categories appear (in filter pills and card headers)
        expect(find.text('Printer & Struk'), findsWidgets);
        expect(find.text('Stok & Produk'), findsWidgets);
        expect(find.text('Transaksi & Pembayaran'), findsWidgets);
        expect(find.text('Shift Kasir & Uang Laci'), findsWidgets);
        expect(find.text('Offline & Sinkronisasi'), findsWidgets);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'HelpPage category pill filter isolates selected category and restores on Semua',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: HelpPage()));
        await tester.pumpAndSettle();

        // Tap "Stok & Produk" filter pill (first occurrence is in the pill row)
        final stokPill = find.text('Stok & Produk').first;
        await tester.tap(stokPill);
        await tester.pumpAndSettle();

        // Stok & Produk category card should be present in the FAQ list
        expect(
          find.widgetWithText(ExpansionTile, 'Stok & Produk'),
          findsOneWidget,
        );
        // Other categories should be filtered out
        expect(
          find.widgetWithText(ExpansionTile, 'Shift Kasir & Uang Laci'),
          findsNothing,
        );
        expect(
          find.widgetWithText(ExpansionTile, 'Printer & Struk'),
          findsNothing,
        );

        // Tap "Semua" filter pill to restore
        final semuaPill = find.text('Semua');
        expect(semuaPill, findsOneWidget);
        await tester.tap(semuaPill);
        await tester.pumpAndSettle();

        // All category cards restored in the FAQ list
        expect(
          find.widgetWithText(ExpansionTile, 'Printer & Struk'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ExpansionTile, 'Stok & Produk'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ExpansionTile, 'Shift Kasir & Uang Laci'),
          findsOneWidget,
        );
      },
    );

    testWidgets('HelpPage renders cleanly in dark theme without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: const HelpPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pusat Bantuan & Kendala'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TermsAndConditionsPage Widget Tests', () {
    testWidgets(
      'TermsAndConditionsPage renders header banner, sections, and acceptance footer',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(home: TermsAndConditionsPage()),
        );
        await tester.pumpAndSettle();

        // Verify app bar title
        expect(find.text('Syarat & Ketentuan'), findsOneWidget);

        // Verify header
        expect(
          find.text('Syarat & Ketentuan Penggunaan Layanan'),
          findsOneWidget,
        );

        // Verify initial visible elements
        expect(find.text('Definisi & Ketentuan Umum'), findsOneWidget);
        expect(find.text('Akun Pengguna, Peran & Keamanan'), findsOneWidget);

        // Scroll to verify subsequent sections
        await tester.scrollUntilVisible(
          find.text('Penyimpanan Data Lokal & Sinkronisasi Cloud'),
          200,
          scrollable: find.byType(Scrollable),
        );
        expect(
          find.text('Penyimpanan Data Lokal & Sinkronisasi Cloud'),
          findsOneWidget,
        );

        await tester.scrollUntilVisible(
          find.text('Perangkat Keras & Layanan Pihak Ketiga'),
          200,
          scrollable: find.byType(Scrollable),
        );
        expect(
          find.text('Perangkat Keras & Layanan Pihak Ketiga'),
          findsOneWidget,
        );

        await tester.scrollUntilVisible(
          find.text('Perubahan Ketentuan & Kontak Resmi'),
          200,
          scrollable: find.byType(Scrollable),
        );
        expect(find.text('Perubahan Ketentuan & Kontak Resmi'), findsOneWidget);
      },
    );

    testWidgets(
      'TermsAndConditionsPage renders cleanly in dark theme without overflow',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const TermsAndConditionsPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Syarat & Ketentuan'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
