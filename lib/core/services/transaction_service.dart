import 'dart:convert';
import 'package:laci/data/datasources/local/local_database.dart';
import 'package:laci/data/datasources/local/product_local_datasource.dart';
import 'package:laci/data/datasources/local/transaction_local_datasource.dart';
import 'package:laci/data/datasources/local/stock_log_local_datasource.dart';
import 'package:laci/data/datasources/local/customer_local_datasource.dart';
import 'package:laci/data/models/transaction_model.dart';
import 'package:laci/data/models/stock_log_model.dart';
import 'package:laci/domain/entities/stock_log_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import './notification_service.dart';
import './session_service.dart';

class TransactionService {
  final LocalDatabase _localDb;
  final ProductLocalDataSource _productLocal;
  final TransactionLocalDataSource _transactionLocal;
  final StockLogLocalDataSource _stockLogLocal;
  final CustomerLocalDataSource _customerLocal;
  final NotificationService _notificationService;
  final SessionService _sessionService;

  TransactionService(
    this._localDb,
    this._productLocal,
    this._transactionLocal,
    this._stockLogLocal,
    this._customerLocal,
    this._notificationService,
    this._sessionService,
  );

  String get _businessId => _sessionService.businessId ?? '';

  /// Process transaction with local stock update and sync queueing
  Future<String> processTransaction(TransactionEntity transaction) async {
    if (_businessId.isEmpty) {
      throw Exception('Business ID is missing. Please re-login.');
    }
    
    try {
      final transactionModel = TransactionModel.fromEntity(transaction).copyWith(
        businessId: _businessId,
      );

      // We use a local DB transaction to ensure atomicity
      await _localDb.transaction(() async {
        // 1. Validate and update stock for each item
        for (final item in transaction.items) {
          final product = await _productLocal.getProductById(item.productId);
          if (product == null) {
            throw Exception('Produk ${item.productName} tidak ditemukan');
          }

          final currentStock = product.stock;
          final newStock = currentStock - item.quantity;

          if (newStock < 0) {
            throw Exception(
              'Stok tidak cukup untuk ${item.productName}. Tersedia: $currentStock',
            );
          }

          // Update local stock
          await _productLocal.updateStock(item.productId, newStock);

          // Create local stock log
          final logModel = StockLogModel(
            id: DateTime.now().millisecondsSinceEpoch.toString() + item.productId,
            productId: item.productId,
            productName: item.productName,
            type: StockLogType.sale,
            quantity: -item.quantity,
            previousStock: currentStock,
            newStock: newStock,
            reason: 'Transaksi ${transaction.transactionCode}',
            createdAt: DateTime.now(),
            businessId: _businessId,
          );
          await _stockLogLocal.insertStockLog(logModel, syncStatus: 'pendingUpload');

          // Check for low stock alert
          if (newStock <= product.stockThreshold) {
            _notificationService.showStockAlert(
              productName: item.productName,
              currentStock: newStock,
            );
          }

          // Add to sync queue for product update (Stock changed!)
          await _localDb.addToSyncQueue(
            syncEntityName: 'products',
            documentId: item.productId,
            operation: 'update',
            businessId: _businessId,
            data: jsonEncode(product.copyWith(stock: newStock).toJson()),
          );

          // Add to sync queue for stock log
          await _localDb.addToSyncQueue(
            syncEntityName: 'stock_logs',
            documentId: logModel.id,
            operation: 'create',
            businessId: _businessId,
            data: jsonEncode(logModel.toJson()),
          );
        }

        // 2. Save transaction locally
        await _transactionLocal.createTransaction(transactionModel, syncStatus: 'pendingUpload');

        // 3. Update Customer Statistics if customerId is present
        if (transaction.customerId != null &&
            transaction.customerId!.isNotEmpty) {
          final customer =
              await _customerLocal.getCustomerById(transaction.customerId!);
          if (customer != null) {
            // Logic: 1 point for every 10,000 IDR
            final newPoints = (transaction.totalAmount / 10000).floor();

            final updatedCustomer = customer.copyWith(
              totalSpent: customer.totalSpent + transaction.totalAmount,
              lastTransactionDate: transaction.createdAt,
              loyaltyPoints: customer.loyaltyPoints + newPoints,
              updatedAt: DateTime.now(),
            );

            await _customerLocal.upsertCustomer(updatedCustomer,
                syncStatus: 'pendingUpload');

            // Add customer update to sync queue
            await _localDb.addToSyncQueue(
              syncEntityName: 'customers',
              documentId: updatedCustomer.id,
              operation: 'update',
              businessId: _businessId,
              data: jsonEncode(updatedCustomer.toJson()),
            );
          }
        }

        // 4. Add to sync queue for transaction
        await _localDb.addToSyncQueue(
          syncEntityName: 'transactions',
          documentId: transaction.id,
          operation: 'create',
          businessId: _businessId,
          data: jsonEncode(transactionModel.toJson()),
        );
      });

      return transaction.id;
    } catch (e) {
      throw Exception('Gagal memproses transaksi secara offline: $e');
    }
  }

  /// Stock adjustment (for manual stock updates)
  Future<void> adjustStock(
    String productId,
    int adjustment,
    String reason,
  ) async {
    try {
      final product = await _productLocal.getProductById(productId);
      if (product == null) {
        throw Exception('Product not found');
      }

      final currentStock = product.stock;
      final newStock = currentStock + adjustment;

      if (newStock < 0) {
        throw Exception('Stock cannot be negative');
      }

      await _localDb.transaction(() async {
        // 1. Update local stock
        await _productLocal.updateStock(productId, newStock);

        // 2. Log stock adjustment
        final logModel = StockLogModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + productId,
          productId: productId,
          productName: product.name,
          type: adjustment > 0 ? StockLogType.stockIn : StockLogType.stockOut,
          quantity: adjustment,
          previousStock: currentStock,
          newStock: newStock,
          reason: reason,
          createdAt: DateTime.now(),
          businessId: _businessId,
        );
        await _stockLogLocal.insertStockLog(logModel, syncStatus: 'pendingUpload');

        // 3. Add to sync queue
        await _localDb.addToSyncQueue(
          syncEntityName: 'stock_logs',
          documentId: logModel.id,
          operation: 'create',
          businessId: _businessId,
          data: jsonEncode(logModel.toJson()),
        );
        
        // Note: Since we updated product stock, we also need to sync the product update
        await _localDb.addToSyncQueue(
          syncEntityName: 'products',
          documentId: productId,
          operation: 'update',
          businessId: _businessId,
          data: jsonEncode(product.copyWith(stock: newStock).toJson()),
        );
      });
    } catch (e) {
      throw Exception('Failed to adjust stock: $e');
    }
  }
}
