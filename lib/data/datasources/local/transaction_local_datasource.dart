import 'package:drift/drift.dart';
import 'package:laci/data/models/transaction_model.dart';
import 'package:laci/domain/entities/transaction_entity.dart';
import 'local_database.dart';

/// Local data source for Transaction operations using Drift/SQLite.
/// This is the most critical datasource — it enables offline transactions.
class TransactionLocalDataSource {
  final LocalDatabase _db;

  TransactionLocalDataSource(this._db);

  /// Watch all transactions for the given business.
  Stream<List<TransactionModel>> watchTransactions(String businessId) {
    final query = _db.select(_db.localTransactions)
      ..where((t) => t.businessId.equals(businessId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().asyncMap((rows) async {
      final List<TransactionModel> transactions = [];
      for (final row in rows) {
        final items = await _getItemsForTransaction(row.id);
        final payments = await _getPaymentsForTransaction(row.id);
        transactions.add(_rowToModel(row, items, payments));
      }
      return transactions;
    });
  }

  /// Watch transactions within a date range.
  Stream<List<TransactionModel>> watchTransactionsByDateRange(
    String businessId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final query = _db.select(_db.localTransactions)
      ..where(
        (t) =>
            t.businessId.equals(businessId) &
            t.createdAt.isBiggerOrEqualValue(startDate) &
            t.createdAt.isSmallerThanValue(endDate),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().asyncMap((rows) async {
      final List<TransactionModel> transactions = [];
      for (final row in rows) {
        final items = await _getItemsForTransaction(row.id);
        final payments = await _getPaymentsForTransaction(row.id);
        transactions.add(_rowToModel(row, items, payments));
      }
      return transactions;
    });
  }

  /// Watch transactions for a specific customer.
  Stream<List<TransactionModel>> watchTransactionsByCustomer(
    String businessId,
    String customerId,
  ) {
    final query = _db.select(_db.localTransactions)
      ..where(
        (t) =>
            t.businessId.equals(businessId) & t.customerId.equals(customerId),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().asyncMap((rows) async {
      final List<TransactionModel> transactions = [];
      for (final row in rows) {
        final items = await _getItemsForTransaction(row.id);
        final payments = await _getPaymentsForTransaction(row.id);
        transactions.add(_rowToModel(row, items, payments));
      }
      return transactions;
    });
  }

  /// Get a single transaction by ID.
  Future<TransactionModel?> getTransactionById(String id) async {
    final query = _db.select(_db.localTransactions)
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    final items = await _getItemsForTransaction(id);
    final payments = await _getPaymentsForTransaction(id);
    return _rowToModel(row, items, payments);
  }

  /// Create a transaction locally with all items (atomic).
  /// This is the core offline transaction capability.
  Future<String> createTransaction(
    TransactionModel transaction, {
    String syncStatus = 'pendingUpload',
  }) async {
    await _db.transaction(() async {
      // 1. Insert transaction
      await _db
          .into(_db.localTransactions)
          .insert(
            LocalTransactionsCompanion.insert(
              id: transaction.id,
              transactionCode: transaction.transactionCode,
              customerId: Value(transaction.customerId),
              customerName: Value(transaction.customerName),
              subtotal: transaction.subtotal,
              taxAmount: Value(transaction.taxAmount),
              discountAmount: Value(transaction.discountAmount),
              totalAmount: transaction.totalAmount,
              paymentMethod: transaction.paymentMethodDisplay,
              paymentStatus: Value(transaction.paymentStatus.name),
              status: Value(transaction.status.name),
              amountPaid: Value(transaction.amountPaid),
              changeAmount: Value(transaction.changeAmount),
              notes: Value(transaction.notes),
              createdAt: transaction.createdAt,
              completedAt: Value(transaction.completedAt),
              createdBy: transaction.createdBy,
              businessId: Value(transaction.businessId),
              syncStatus: Value(syncStatus),
              lastSyncAt: Value(syncStatus == 'synced' ? DateTime.now() : null),
            ),
          );

      // 2. Insert transaction items
      for (final item in transaction.items) {
        await _db
            .into(_db.localTransactionItems)
            .insert(
              LocalTransactionItemsCompanion.insert(
                id: item.id,
                transactionId: transaction.id,
                productId: item.productId,
                productName: item.productName,
                quantity: item.quantity,
                price: item.price,
                costPrice: item.costPrice,
                discount: Value(item.discount),
                subtotal: item.subtotal,
                businessId: Value(item.businessId),
              ),
            );
      }

      // 3. Insert payment details
      for (final payment in transaction.payments) {
        await _db.into(_db.localTransactionPayments).insert(
              LocalTransactionPaymentsCompanion.insert(
                id: '${transaction.id}_${payment.type.name}_${payment.timestamp.millisecondsSinceEpoch}',
                transactionId: transaction.id,
                type: payment.type.name,
                amount: payment.amount,
                reference: Value(payment.reference),
                timestamp: payment.timestamp,
              ),
            );
      }
    });
    return transaction.id;
  }

  /// Get all transactions pending sync.
  Future<List<TransactionModel>> getPendingSync() async {
    final query = _db.select(_db.localTransactions)
      ..where((t) => t.syncStatus.equals('synced').not());
    final rows = await query.get();
    final List<TransactionModel> result = [];
    for (final row in rows) {
      final items = await _getItemsForTransaction(row.id);
      final payments = await _getPaymentsForTransaction(row.id);
      result.add(_rowToModel(row, items, payments));
    }
    return result;
  }

  /// Mark a transaction as synced.
  Future<void> markAsSynced(String id) async {
    await (_db.update(
      _db.localTransactions,
    )..where((t) => t.id.equals(id))).write(
      LocalTransactionsCompanion(
        syncStatus: const Value('synced'),
        lastSyncAt: Value(DateTime.now()),
      ),
    );
  }

  /// Bulk upsert transactions from Firebase (during sync pull).
  Future<void> upsertFromRemote(List<TransactionModel> transactions) async {
    for (final txn in transactions) {
      await _db.transaction(() async {
        // Upsert the transaction itself
        await _db
            .into(_db.localTransactions)
            .insertOnConflictUpdate(
              LocalTransactionsCompanion.insert(
                id: txn.id,
                transactionCode: txn.transactionCode,
                customerId: Value(txn.customerId),
                customerName: Value(txn.customerName),
                subtotal: txn.subtotal,
                taxAmount: Value(txn.taxAmount),
                discountAmount: Value(txn.discountAmount),
                totalAmount: txn.totalAmount,
                paymentMethod: txn.paymentMethodDisplay,
                paymentStatus: Value(txn.paymentStatus.name),
                status: Value(txn.status.name),
                amountPaid: Value(txn.amountPaid),
                changeAmount: Value(txn.changeAmount),
                notes: Value(txn.notes),
                createdAt: txn.createdAt,
                completedAt: Value(txn.completedAt),
                createdBy: txn.createdBy,
                businessId: Value(txn.businessId),
                syncStatus: const Value('synced'),
                lastSyncAt: Value(DateTime.now()),
              ),
            );

        // Delete old items and re-insert
        await (_db.delete(
          _db.localTransactionItems,
        )..where((t) => t.transactionId.equals(txn.id))).go();

        for (final item in txn.items) {
          await _db
              .into(_db.localTransactionItems)
              .insert(
                LocalTransactionItemsCompanion.insert(
                  id: item.id,
                  transactionId: txn.id,
                  productId: item.productId,
                  productName: item.productName,
                  quantity: item.quantity,
                  price: item.price,
                  costPrice: item.costPrice,
                  discount: Value(item.discount),
                  subtotal: item.subtotal,
                  businessId: Value(item.businessId),
                ),
              );
        }

        // Delete old payments and re-insert
        await (_db.delete(_db.localTransactionPayments)
              ..where((t) => t.transactionId.equals(txn.id)))
            .go();

        for (final payment in txn.payments) {
          await _db.into(_db.localTransactionPayments).insert(
                LocalTransactionPaymentsCompanion.insert(
                  id: '${txn.id}_${payment.type.name}_${payment.timestamp.millisecondsSinceEpoch}',
                  transactionId: txn.id,
                  type: payment.type.name,
                  amount: payment.amount,
                  reference: Value(payment.reference),
                  timestamp: payment.timestamp,
                ),
              );
        }
      });
    }
  }

  // --- Private Helpers ---

  Future<List<TransactionItemModel>> _getItemsForTransaction(
    String transactionId,
  ) async {
    final query = _db.select(_db.localTransactionItems)
      ..where((t) => t.transactionId.equals(transactionId));
    final rows = await query.get();
    return rows.map((row) => _itemRowToModel(row)).toList();
  }

  TransactionModel _rowToModel(
    LocalTransaction row,
    List<TransactionItemModel> items,
    List<PaymentDetailModel> payments,
  ) {
    return TransactionModel(
      id: row.id,
      transactionCode: row.transactionCode,
      customerId: row.customerId,
      customerName: row.customerName,
      subtotal: row.subtotal,
      taxAmount: row.taxAmount,
      discountAmount: row.discountAmount,
      totalAmount: row.totalAmount,
      payments: payments,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == row.paymentStatus,
        orElse: () => PaymentStatus.unpaid,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == row.status,
        orElse: () => TransactionStatus.pending,
      ),
      amountPaid: row.amountPaid,
      changeAmount: row.changeAmount,
      notes: row.notes,
      createdAt: row.createdAt,
      completedAt: row.completedAt,
      items: items.map((i) => i.toEntity()).toList(),
      createdBy: row.createdBy,
      businessId: row.businessId,
    );
  }

  TransactionItemModel _itemRowToModel(LocalTransactionItem row) {
    return TransactionItemModel(
      id: row.id,
      productId: row.productId,
      productName: row.productName,
      quantity: row.quantity,
      price: row.price,
      costPrice: row.costPrice,
      discount: row.discount,
      subtotal: row.subtotal,
      businessId: row.businessId,
    );
  }

  Future<List<PaymentDetailModel>> _getPaymentsForTransaction(
    String transactionId,
  ) async {
    final query = _db.select(_db.localTransactionPayments)
      ..where((t) => t.transactionId.equals(transactionId));
    final rows = await query.get();
    return rows.map((row) => _paymentRowToModel(row)).toList();
  }

  PaymentDetailModel _paymentRowToModel(LocalTransactionPayment row) {
    return PaymentDetailModel(
      type: PaymentType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => PaymentType.cash,
      ),
      amount: row.amount,
      reference: row.reference,
      timestamp: row.timestamp,
    );
  }
}
