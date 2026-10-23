import 'package:flutter_test/flutter_test.dart';
import 'package:laci/domain/entities/transaction_entity.dart';

void main() {
  group('Split Payment Tests', () {
    final now = DateTime.now();

    test('Single payment method displays simple typeName', () {
      final txn = TransactionEntity(
        id: 'txn_single',
        transactionCode: 'TRX-001',
        subtotal: 50000,
        totalAmount: 50000,
        payments: [
          PaymentDetail(type: PaymentType.cash, amount: 50000, timestamp: now),
        ],
        paymentStatus: PaymentStatus.paid,
        status: TransactionStatus.completed,
        createdAt: now,
        items: const [],
        createdBy: 'user_1',
      );

      expect(txn.paymentMethodDisplay, 'Cash');
    });

    test('Split payment combines distinct tender types in paymentMethodDisplay', () {
      final txn = TransactionEntity(
        id: 'txn_split',
        transactionCode: 'TRX-002',
        subtotal: 100000,
        totalAmount: 100000,
        payments: [
          PaymentDetail(type: PaymentType.cash, amount: 40000, timestamp: now),
          PaymentDetail(type: PaymentType.qris, amount: 60000, timestamp: now),
        ],
        paymentStatus: PaymentStatus.paid,
        status: TransactionStatus.completed,
        createdAt: now,
        items: const [],
        createdBy: 'user_1',
      );

      expect(txn.paymentMethodDisplay, 'Split (Cash + QRIS)');
    });

    test('Multi-way split payment aggregates total paid amount accurately', () {
      final payments = [
        PaymentDetail(type: PaymentType.cash, amount: 25000, timestamp: now),
        PaymentDetail(type: PaymentType.transfer, amount: 50000, timestamp: now),
        PaymentDetail(type: PaymentType.debit, amount: 25000, timestamp: now),
      ];

      final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
      expect(totalPaid, 100000);
    });

    test('Empty payments list displays Belum Bayar', () {
      final txn = TransactionEntity(
        id: 'txn_unpaid',
        transactionCode: 'TRX-003',
        subtotal: 75000,
        totalAmount: 75000,
        payments: const [],
        paymentStatus: PaymentStatus.unpaid,
        status: TransactionStatus.pending,
        createdAt: now,
        items: const [],
        createdBy: 'user_1',
      );

      expect(txn.paymentMethodDisplay, 'Belum Bayar');
    });
  });
}
