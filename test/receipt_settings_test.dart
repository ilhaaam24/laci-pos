import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:laci/core/services/receipt_settings_service.dart';
import 'package:laci/domain/entities/business_entity.dart';
import 'package:laci/domain/entities/transaction_entity.dart';
import 'package:laci/presentation/pages/checkout/widgets/receipt_image_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReceiptSettingsService & Config Tests', () {
    test('ReceiptSettingsService defaults to standard configuration', () async {
      final service = ReceiptSettingsService();
      await service.init();

      final cfg = service.config;
      expect(cfg.showLogo, isTrue);
      expect(cfg.customLogoPath, isNull);
      expect(cfg.headerMessage, isEmpty);
      expect(cfg.footerMessage, equals('TERIMA KASIH TELAH BERBELANJA!'));
      expect(
        cfg.footerNote,
        equals('Simpan struk digital ini sebagai bukti transaksi yang sah.'),
      );
      expect(cfg.socialMediaOrWifi, isEmpty);
      expect(cfg.showAddress, isTrue);
      expect(cfg.showPhone, isTrue);
      expect(cfg.showCashierName, isTrue);
      expect(cfg.showCustomerName, isTrue);
      expect(cfg.showTableNumber, isTrue);
      expect(cfg.showItemNotes, isTrue);
    });

    test(
      'ReceiptSettingsService saveConfig persists custom settings to SharedPreferences',
      () async {
        final service = ReceiptSettingsService();
        await service.init();

        const newConfig = ReceiptConfig(
          showLogo: false,
          customLogoPath: '/path/to/logo.png',
          headerMessage: 'Spesialis Kopi Susu & Toast',
          footerMessage: 'Sampai Jumpa Kembali!',
          footerNote: 'Barang yang dibeli tidak dapat ditukar',
          socialMediaOrWifi: 'IG: @kopisenja | WiFi: senja123',
          showAddress: false,
          showPhone: false,
          showCashierName: false,
          showCustomerName: false,
          showTableNumber: false,
          showItemNotes: false,
        );

        await service.saveConfig(newConfig);

        expect(service.config.showLogo, isFalse);
        expect(service.config.customLogoPath, equals('/path/to/logo.png'));
        expect(
          service.config.headerMessage,
          equals('Spesialis Kopi Susu & Toast'),
        );
        expect(service.config.footerMessage, equals('Sampai Jumpa Kembali!'));
        expect(
          service.config.footerNote,
          equals('Barang yang dibeli tidak dapat ditukar'),
        );
        expect(
          service.config.socialMediaOrWifi,
          equals('IG: @kopisenja | WiFi: senja123'),
        );
        expect(service.config.showAddress, isFalse);
        expect(service.config.showPhone, isFalse);
        expect(service.config.showCashierName, isFalse);
        expect(service.config.showCustomerName, isFalse);
        expect(service.config.showTableNumber, isFalse);
        expect(service.config.showItemNotes, isFalse);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('pref_receipt_show_logo'), isFalse);
        expect(
          prefs.getString('pref_receipt_header_msg'),
          equals('Spesialis Kopi Susu & Toast'),
        );
        expect(
          prefs.getString('pref_receipt_footer_msg'),
          equals('Sampai Jumpa Kembali!'),
        );
        expect(prefs.getBool('pref_receipt_show_address'), isFalse);

        // Test resetToDefault
        await service.resetToDefault();
        expect(service.config.showLogo, isTrue);
        expect(service.config.headerMessage, isEmpty);
        expect(service.config.showAddress, isTrue);
      },
    );
  });

  group('ReceiptImageWidget with Custom ReceiptConfig Tests', () {
    testWidgets(
      'ReceiptImageWidget respects custom config toggles and messages',
      (tester) async {
        final now = DateTime(2026, 9, 22, 14, 0);
        final transaction = TransactionEntity(
          id: 'trx_cfg_01',
          transactionCode: 'INV-CFG-001',
          customerName: 'Siti Badriah',
          subtotal: 30000,
          totalAmount: 30000,
          amountPaid: 30000,
          changeAmount: 0,
          createdAt: now,
          createdBy: 'Kasir Satu',
          notes: 'Dine In (Meja 03)',
          payments: [
            PaymentDetail(
              type: PaymentType.cash,
              amount: 30000,
              timestamp: now,
            ),
          ],
          items: const [
            TransactionItem(
              id: 'item_1',
              productId: 'p1',
              productName: 'Roti Bakar Coklat',
              notes: 'Coklat banyak',
              quantity: 1,
              price: 30000,
              costPrice: 10000,
              subtotal: 30000,
            ),
          ],
        );

        final businessInfo = BusinessInfo(
          id: 'biz_01',
          businessName: 'Kopi & Roti Kenangan',
          address: 'Jl. Pemuda No. 12',
          phone: '0811223344',
          createdAt: now,
          updatedAt: now,
        );

        const customConfig = ReceiptConfig(
          showLogo: false,
          headerMessage: 'Kenikmatan di Setiap Gigitan',
          footerMessage: 'MATUR NUWUN!',
          footerNote: 'Simpan bukti bayar ini.',
          socialMediaOrWifi: 'Free WiFi: KopiRoti123',
          showAddress: false,
          showPhone: false,
          showCashierName: false,
          showCustomerName: false,
          showTableNumber: false,
          showItemNotes: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ReceiptImageWidget(
                  transaction: transaction,
                  businessInfo: businessInfo,
                  config: customConfig,
                ),
              ),
            ),
          ),
        );

        // Business Name and custom Tagline should appear
        expect(find.text('KOPI & ROTI KENANGAN'), findsOneWidget);
        expect(find.text('Kenikmatan di Setiap Gigitan'), findsOneWidget);

        // Address and Phone should be hidden
        expect(find.text('Jl. Pemuda No. 12'), findsNothing);
        expect(find.text('Telp: 0811223344'), findsNothing);

        // Cashier, Customer, Table, and Item Notes should be hidden
        expect(find.text('Kasir Satu'), findsNothing);
        expect(find.text('Siti Badriah'), findsNothing);
        expect(find.text('Dine In (Meja 03)'), findsNothing);
        expect(find.text('Catatan: Coklat banyak'), findsNothing);

        // Custom footer and wifi should appear
        expect(find.text('MATUR NUWUN!'), findsOneWidget);
        expect(find.text('Simpan bukti bayar ini.'), findsOneWidget);
        expect(find.text('Free WiFi: KopiRoti123'), findsOneWidget);
      },
    );
  });
}
