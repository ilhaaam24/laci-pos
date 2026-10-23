import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:laci/core/services/export_service.dart';
import 'package:laci/domain/entities/business_entity.dart';
import 'package:laci/domain/entities/transaction_entity.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('ExportService Tests', () {
    test('generateReportFilename sanitizes slashes and invalid characters', () {
      final filename = ExportService.generateReportFilename(
        period: '01/09 - 18/09',
        timestamp: DateTime(2026, 9, 18, 10, 0, 0),
      );
      expect(filename.contains('/'), isFalse);
      expect(filename, 'Laporan_01_09_-_18_09_20260918_100000.pdf');
    });

    test('buildReportPdf succeeds with productStats keys (name, qty, subtotal)', () async {
      final now = DateTime.now();
      final reportMap = {
        'startDate': now.subtract(const Duration(days: 1)),
        'endDate': now,
        'totalRevenue': 150000.0,
        'totalCost': 90000.0,
        'totalProfit': 60000.0,
        'totalTransactions': 3,
        'totalItems': 5,
        'cashTotal': 100000.0,
        'qrisTotal': 50000.0,
        'transferTotal': 0.0,
        // Notice: keys from report_page.dart are name, qty, subtotal
        'bestSellingProducts': [
          {'name': 'Kopi Susu', 'qty': 3, 'subtotal': 75000.0},
          {'name': 'Croissant', 'qty': 2, 'subtotal': 75000.0},
        ],
        'transactions': [
          TransactionEntity(
            id: 'trx_1',
            transactionCode: 'TRX-001',
            subtotal: 75000,
            totalAmount: 75000,
            payments: [
              PaymentDetail(type: PaymentType.cash, amount: 75000, timestamp: now),
            ],
            paymentStatus: PaymentStatus.paid,
            status: TransactionStatus.completed,
            amountPaid: 75000,
            changeAmount: 0,
            createdAt: now,
            items: const [],
            createdBy: 'Owner',
          ),
        ],
      };

      final businessInfo = BusinessInfo(
        id: 'biz_1',
        businessName: 'Laci Cafe',
        address: 'Jl. Melati No. 10',
        phone: '08123456789',
        createdAt: now,
        updatedAt: now,
      );

      final pdf = await ExportService.buildReportPdf(
        reportData: reportMap,
        period: 'Hari Ini',
        businessInfo: businessInfo,
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('buildReportPdf handles empty data safely without throwing', () async {
      final now = DateTime.now();
      final emptyReportMap = {
        'startDate': now,
        'endDate': now,
        'totalRevenue': 0.0,
        'totalCost': 0.0,
        'totalProfit': 0.0,
        'totalTransactions': 0,
        'totalItems': 0,
        'bestSellingProducts': <Map<String, dynamic>>[],
        'transactions': <TransactionEntity>[],
      };

      final pdf = await ExportService.buildReportPdf(
        reportData: emptyReportMap,
        period: 'Bulan Ini',
        businessInfo: null,
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });
  });
}
