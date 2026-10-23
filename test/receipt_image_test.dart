import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:intl/date_symbol_data_local.dart';
import 'package:laci/core/services/receipt_image_service.dart';
import 'package:laci/domain/entities/business_entity.dart';
import 'package:laci/domain/entities/product_variant.dart';
import 'package:laci/domain/entities/transaction_entity.dart';
import 'package:laci/presentation/pages/checkout/widgets/receipt_image_widget.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('ReceiptImageWidget & JPG Rendering Tests', () {
    testWidgets('ReceiptImageWidget renders with complete store and transaction data', (tester) async {
      final now = DateTime(2026, 9, 22, 11, 45);
      final transaction = TransactionEntity(
        id: 'trx_jpg_01',
        transactionCode: 'INV-202609220001',
        customerName: 'Ahmad Fauzi',
        subtotal: 55000,
        discountAmount: 5000,
        taxAmount: 5000,
        totalAmount: 55000,
        amountPaid: 60000,
        changeAmount: 5000,
        createdAt: now,
        createdBy: 'Budi Kasir',
        notes: 'Dine In (Meja 08)',
        payments: [
          PaymentDetail(
            type: PaymentType.cash,
            amount: 60000,
            timestamp: now,
          ),
        ],
        items: const [
          TransactionItem(
            id: 'item_1',
            productId: 'prod_1',
            productName: 'Kopi Susu Senja',
            selectedVariant: ProductVariant(
              id: 'var_1',
              name: 'Large',
              price: 25000,
            ),
            selectedModifiers: [
              ModifierOption(id: 'mod_1', name: 'Less Ice', price: 0),
              ModifierOption(id: 'mod_2', name: 'Extra Shot', price: 5000),
            ],
            notes: 'Gula aren pisah',
            quantity: 2,
            price: 25000,
            costPrice: 12000,
            subtotal: 50000,
          ),
        ],
      );

      final businessInfo = BusinessInfo(
        id: 'biz_01',
        businessName: 'Laci Coffee & Eatery',
        address: 'Jl. Sudirman No. 45',
        phone: '08123456789',
        isTaxEnabled: true,
        taxName: 'PB1',
        taxRate: 10,
        isServiceChargeEnabled: true,
        serviceChargeRate: 5,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReceiptImageWidget(
                transaction: transaction,
                businessInfo: businessInfo,
              ),
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('LACI COFFEE & EATERY'), findsOneWidget);
      expect(find.text('Jl. Sudirman No. 45'), findsOneWidget);
      expect(find.text('Telp: 08123456789'), findsOneWidget);

      // Verify metadata
      expect(find.text('INV-202609220001'), findsOneWidget);
      expect(find.text('Ahmad Fauzi'), findsOneWidget);
      expect(find.text('Budi Kasir'), findsOneWidget);
      expect(find.text('Dine In (Meja 08)'), findsOneWidget);

      // Verify items and modifier/notes
      expect(find.text('Kopi Susu Senja (Large)'), findsOneWidget);
      expect(find.text('Less Ice, +Extra Shot'), findsOneWidget);
      expect(find.text('Catatan: Gula aren pisah'), findsOneWidget);

      // Verify totals and payments
      expect(find.text('TOTAL'), findsOneWidget);
      expect(find.text('Rp 55.000'), findsWidgets);
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('TERIMA KASIH TELAH BERBELANJA!'), findsOneWidget);
    });

    testWidgets('ReceiptImageWidget renders safely with minimal data without throwing', (tester) async {
      final now = DateTime(2026, 9, 22, 12, 0);
      final transaction = TransactionEntity(
        id: 'trx_min_01',
        transactionCode: 'INV-MIN-001',
        subtotal: 15000,
        totalAmount: 15000,
        amountPaid: 15000,
        changeAmount: 0,
        createdAt: now,
        createdBy: '',
        payments: [
          PaymentDetail(
            type: PaymentType.qris,
            amount: 15000,
            timestamp: now,
          ),
        ],
        items: const [
          TransactionItem(
            id: 'item_simple',
            productId: 'p_simple',
            productName: 'Air Mineral',
            quantity: 1,
            price: 15000,
            costPrice: 5000,
            subtotal: 15000,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReceiptImageWidget(
                transaction: transaction,
                businessInfo: null,
              ),
            ),
          ),
        ),
      );

      expect(find.text('LACI POS'), findsOneWidget);
      expect(find.text('Air Mineral'), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
    });

    test('JPEG encoder produces valid JPEG magic header (0xFF, 0xD8)', () {
      final testImage = img.Image(width: 100, height: 100);
      img.fill(testImage, color: img.ColorRgb8(255, 255, 255));

      final jpgBytes = Uint8List.fromList(img.encodeJpg(testImage, quality: 90));

      expect(jpgBytes.isNotEmpty, isTrue);
      expect(jpgBytes[0], equals(0xFF));
      expect(jpgBytes[1], equals(0xD8));
    });

    testWidgets('ReceiptImageService.generateReceiptJpgBytes renders long receipt without overflow', (tester) async {
      final now = DateTime(2026, 9, 22, 12, 0);
      final transaction = TransactionEntity(
        id: 'trx_long_test',
        transactionCode: 'INV-LONG-001',
        subtotal: 250000,
        totalAmount: 250000,
        amountPaid: 250000,
        changeAmount: 0,
        createdAt: now,
        createdBy: 'Kasir Utama',
        notes: 'Meja 12',
        customerName: 'Budi Santoso',
        payments: [
          PaymentDetail(type: PaymentType.cash, amount: 250000, timestamp: now),
        ],
        items: List.generate(
          10,
          (i) => TransactionItem(
            id: 'item_$i',
            productId: 'prod_$i',
            productName: 'Menu Pesanan Lezat Nomor $i',
            quantity: 2,
            price: 25000,
            costPrice: 10000,
            subtotal: 50000,
            notes: 'Catatan tambahan $i',
          ),
        ),
      );

      final businessInfo = BusinessInfo(
        id: 'b1',
        businessName: 'Laci POS Official Store',
        address: 'Jl. Merdeka No. 10 Jakarta Pusat',
        phone: '081299998888',
        createdAt: now,
        updatedAt: now,
      );

      Uint8List? capturedBytes;
      await tester.runAsync(() async {
        capturedBytes = await ReceiptImageService.generateReceiptJpgBytes(
          transaction: transaction,
          businessInfo: businessInfo,
        );
      });

      expect(capturedBytes, isNotNull);
      expect(capturedBytes!.isNotEmpty, isTrue);
      // Valid JPEG header
      expect(capturedBytes![0], equals(0xFF));
      expect(capturedBytes![1], equals(0xD8));

      // Decode and check it captured full height
      final decoded = img.decodeImage(capturedBytes!);
      expect(decoded, isNotNull);
      expect(decoded!.width, greaterThan(0));
      expect(decoded.height, greaterThan(800));
    });
  });
}
