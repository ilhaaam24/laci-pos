import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:laci/domain/entities/business_entity.dart';
import 'package:laci/domain/entities/transaction_entity.dart';
import 'package:laci/presentation/pages/checkout/widgets/receipt_image_widget.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  testWidgets('Test ReceiptImageService.generateReceiptJpgBytes directly', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 22, 12, 0);
    final transaction = TransactionEntity(
      id: 'trx_test',
      transactionCode: 'INV-TEST-001',
      subtotal: 20000,
      totalAmount: 20000,
      amountPaid: 20000,
      changeAmount: 0,
      createdAt: now,
      createdBy: 'Kasir',
      payments: [
        PaymentDetail(type: PaymentType.cash, amount: 20000, timestamp: now),
      ],
      items: List.generate(
        15,
        (i) => TransactionItem(
          id: 'item_$i',
          productId: 'prod_$i',
          productName:
              'Menu Spesial Panjang Nomor $i dengan Tambahan Toping Enak',
          quantity: 2,
          price: 25000,
          costPrice: 10000,
          subtotal: 50000,
          notes: 'Catatan pesanan ekstra pedas dan tanpa sayur',
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                final wrappedWidget = Directionality(
                  textDirection: TextDirection.ltr,
                  child: MediaQuery(
                    data: const MediaQueryData(),
                    child: Material(
                      color: Colors.white,
                      child: ReceiptImageWidget(
                        transaction: transaction,
                        businessInfo: BusinessInfo(
                          id: 'b1',
                          businessName: 'Toko Test',
                          createdAt: now,
                          updatedAt: now,
                        ),
                      ),
                    ),
                  ),
                );

                final pngBytes = await ScreenshotController()
                    .captureFromLongWidget(
                      wrappedWidget,
                      delay: const Duration(milliseconds: 50),
                      pixelRatio: 2.0,
                      constraints: const BoxConstraints(
                        maxWidth: 400,
                        maxHeight: double.infinity,
                      ),
                    );
                expect(pngBytes.isNotEmpty, isTrue);
                final decoded = img.decodeImage(pngBytes);
                expect(decoded, isNotNull);
                expect(decoded!.width, greaterThan(0));
                expect(decoded.height, greaterThan(1000));

                final jpgBytes = Uint8List.fromList(
                  img.encodeJpg(decoded, quality: 90),
                );
                expect(jpgBytes.isNotEmpty, isTrue);
                expect(jpgBytes[0], equals(0xFF));
                expect(jpgBytes[1], equals(0xD8));
              },
              child: const Text('Capture'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Capture'));
    await tester.pumpAndSettle();
  });
}
