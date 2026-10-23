import 'package:flutter_test/flutter_test.dart';
import 'package:laci/domain/entities/transaction_entity.dart';

void main() {
  group('TransactionEntity & Report Logic Tests', () {
    test('TransactionEntity properly reports paymentMethodDisplay and items', () {
      final now = DateTime.now();
      final txn = TransactionEntity(
        id: 'txn_01',
        transactionCode: 'TRX-2026-001',
        subtotal: 50000,
        totalAmount: 50000,
        payments: [
          PaymentDetail(
            type: PaymentType.cash,
            amount: 50000,
            timestamp: now,
          ),
        ],
        paymentStatus: PaymentStatus.paid,
        status: TransactionStatus.completed,
        amountPaid: 50000,
        changeAmount: 0,
        createdAt: now,
        items: const [
          TransactionItem(
            id: 'item_1',
            productId: 'prod_1',
            productName: 'Kopi Susu Gula Aren',
            quantity: 2,
            price: 25000,
            costPrice: 12000,
            subtotal: 50000,
          ),
        ],
        createdBy: 'user_owner',
      );

      expect(txn.paymentMethodDisplay, 'Cash');
      expect(txn.items.length, 1);
      expect(txn.items.first.quantity, 2);
      expect(txn.totalAmount, 50000);
      expect(txn.status, TransactionStatus.completed);
    });

    test('Filter logic properly handles single selected date and range', () {
      final targetDate = DateTime(2026, 9, 14, 10, 30);
      final otherDate = DateTime(2026, 9, 12, 14, 0);

      final txnTarget = TransactionEntity(
        id: 'txn_target',
        transactionCode: 'TRX-TARGET',
        subtotal: 30000,
        totalAmount: 30000,
        payments: const [],
        createdAt: targetDate,
        items: const [],
        createdBy: 'user_1',
      );

      final txnOther = TransactionEntity(
        id: 'txn_other',
        transactionCode: 'TRX-OTHER',
        subtotal: 45000,
        totalAmount: 45000,
        payments: const [],
        createdAt: otherDate,
        items: const [],
        createdBy: 'user_1',
      );

      final allTxns = [txnTarget, txnOther];

      // Test Single Date Filter (14 Sep 2026)
      final singleDayStart = DateTime(2026, 9, 14);
      final singleDayEnd = DateTime(2026, 9, 14, 23, 59, 59);

      final filteredSingle = allTxns.where((txn) {
        return txn.createdAt.isAfter(singleDayStart.subtract(const Duration(seconds: 1))) &&
            txn.createdAt.isBefore(singleDayEnd.add(const Duration(seconds: 1)));
      }).toList();

      expect(filteredSingle.length, 1);
      expect(filteredSingle.first.id, 'txn_target');

      // Test Range Filter (12 Sep - 14 Sep 2026)
      final rangeStart = DateTime(2026, 9, 12);
      final rangeEnd = DateTime(2026, 9, 14, 23, 59, 59);

      final filteredRange = allTxns.where((txn) {
        return txn.createdAt.isAfter(rangeStart.subtract(const Duration(seconds: 1))) &&
            txn.createdAt.isBefore(rangeEnd.add(const Duration(seconds: 1)));
      }).toList();

      expect(filteredRange.length, 2);
    });
  });
}
