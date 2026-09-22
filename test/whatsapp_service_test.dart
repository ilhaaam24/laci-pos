import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:laci/core/services/whatsapp_service.dart';
import 'package:laci/domain/entities/business_entity.dart';
import 'package:laci/domain/entities/shift_entity.dart';
import 'package:laci/domain/entities/transaction_entity.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('WhatsappService Message Building Tests', () {
    test(
      'buildReceiptMessage formats receipt with items, business info, and totals correctly',
      () {
        final now = DateTime(2026, 9, 21, 13, 0);
        final transaction = TransactionEntity(
          id: 'trx_123',
          transactionCode: 'INV-202609210001',
          customerName: 'Budi Santoso',
          subtotal: 50000,
          taxAmount: 5000,
          discountAmount: 2000,
          totalAmount: 53000,
          amountPaid: 60000,
          changeAmount: 7000,
          payments: [
            PaymentDetail(
              type: PaymentType.cash,
              amount: 60000,
              timestamp: now,
            ),
          ],
          paymentStatus: PaymentStatus.paid,
          status: TransactionStatus.completed,
          createdAt: now,
          createdBy: 'Kasir 1',
          items: const [
            TransactionItem(
              id: 'item_1',
              productId: 'prod_1',
              productName: 'Kopi Susu Gula Aren',
              quantity: 2,
              price: 25000,
              costPrice: 15000,
              subtotal: 50000,
            ),
          ],
        );

        final businessInfo = BusinessInfo(
          id: 'biz_1',
          businessName: 'Kopi Kenangan Senja',
          address: 'Jl. Melati No. 10',
          phone: '081234567890',
          createdAt: now,
          updatedAt: now,
        );

        final message = WhatsappService.buildReceiptMessage(
          transaction: transaction,
          businessInfo: businessInfo,
        );

        expect(message.contains('STRUK PEMBAYARAN'), isTrue);
        expect(message.contains('Kopi Kenangan Senja'), isTrue);
        expect(message.contains('INV-202609210001'), isTrue);
        expect(message.contains('Budi Santoso'), isTrue);
        expect(message.contains('Kopi Susu Gula Aren'), isTrue);
        expect(message.contains('2 x Rp 25.000 = Rp 50.000'), isTrue);
        expect(message.contains('Total: Rp 53.000'), isTrue);
        expect(message.contains('Kembali: Rp 7.000'), isTrue);
      },
    );

    test(
      'buildShiftReportMessage formats X-Report and Z-Report accurately',
      () {
        final startTime = DateTime(2026, 9, 21, 8, 0);
        final endTime = DateTime(2026, 9, 21, 16, 0);

        final activeShift = ShiftEntity(
          id: 'shift_1',
          userId: 'user_1',
          userName: 'Siti Aminah',
          startCash: 100000,
          startTime: startTime,
          createdAt: startTime,
          updatedAt: startTime,
        );

        final summary = ShiftSummary(
          shift: activeShift,
          startCash: 100000,
          totalTransactions: 10,
          totalSales: 500000,
          totalCashSales: 300000,
          totalQrisSales: 150000,
          totalDebitSales: 0,
          totalTransferSales: 50000,
          totalCashIn: 50000,
          totalCashOut: 20000,
          cashMovements: [
            CashMovementEntity(
              id: 'm1',
              shiftId: 'shift_1',
              userId: 'user_1',
              userName: 'Siti Aminah',
              type: CashMovementType.cashIn,
              amount: 50000,
              reason: 'Tukar Pecahan Kecil',
              createdAt: startTime,
            ),
          ],
        );

        final xReport = WhatsappService.buildShiftReportMessage(
          shift: activeShift,
          summary: summary,
        );
        expect(xReport.contains('REKAP SEMENTARA SHIFT (X-REPORT)'), isTrue);
        expect(xReport.contains('*Kasir:* Siti Aminah'), isTrue);
        expect(xReport.contains('Modal Awal:'), isTrue);
        expect(xReport.contains('*Penjualan Tunai:* Rp 300.000'), isTrue);
        expect(xReport.contains('*QRIS:* Rp 150.000'), isTrue);

        final closedShift = activeShift.copyWith(
          status: ShiftStatus.closed,
          endTime: endTime,
          endCashActual: 430000,
          cashDifference: 0,
        );

        final zReport = WhatsappService.buildShiftReportMessage(
          shift: closedShift,
          summary: summary,
        );
        expect(zReport.contains('LAPORAN TUTUP SHIFT (Z-REPORT)'), isTrue);
        expect(zReport.contains('PAS (Rp 0)'), isTrue);
      },
    );
  });
}
