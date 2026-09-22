import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:laci/core/style/app_colors.dart';
import 'package:laci/domain/entities/transaction_entity.dart';

Widget _buildTestRow(TransactionEntity txn) {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final totalItemsCount = txn.items.fold(0, (sum, i) => sum + i.quantity);
  final dateFormatted = DateFormat('HH:mm').format(txn.createdAt);
  final payText = txn.paymentMethodDisplay;

  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF1F5F9)),
    ),
    child: Row(
      children: [
        const Icon(Icons.receipt_rounded, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      txn.transactionCode,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (txn.customerName != null &&
                      txn.customerName!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '• ${txn.customerName}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 4,
                runSpacing: 3,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    dateFormatted,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const Text(
                    ' • ',
                    style: TextStyle(color: Color(0xFFCBD5E1)),
                  ),
                  Text(
                    '$totalItemsCount item',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      payText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                currencyFormatter.format(txn.totalAmount).trim(),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('Report transaction item row renders without overflow on 320dp width with multi-tender split', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final now = DateTime.now();
    final txn = TransactionEntity(
      id: 'txn_split_ovf',
      transactionCode: 'TRX-20260922-0099',
      subtotal: 1250000,
      totalAmount: 1250000,
      customerName: 'Customer Langganan VIP Cabang',
      payments: [
        PaymentDetail(type: PaymentType.cash, amount: 250000, timestamp: now),
        PaymentDetail(type: PaymentType.qris, amount: 500000, timestamp: now),
        PaymentDetail(type: PaymentType.debit, amount: 500000, timestamp: now),
      ],
      paymentStatus: PaymentStatus.paid,
      status: TransactionStatus.completed,
      createdAt: now,
      items: const [
        TransactionItem(
          id: 'item_1',
          productId: 'prod_1',
          productName: 'Kopi Susu Gula Aren Spesial',
          quantity: 15,
          price: 25000,
          costPrice: 10000,
          subtotal: 375000,
        ),
      ],
      createdBy: 'kasir_1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTestRow(txn),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('TRX-20260922'), findsOneWidget);
    expect(find.textContaining('Cash'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
