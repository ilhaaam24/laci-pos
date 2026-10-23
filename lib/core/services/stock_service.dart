import 'dart:convert';
import 'package:laci/data/datasources/local/local_database.dart';
import 'package:laci/data/datasources/local/product_local_datasource.dart';
import 'package:laci/data/datasources/local/stock_log_local_datasource.dart';
import '../../data/models/stock_log_model.dart';
import '../../domain/entities/stock_log_entity.dart';
import './notification_service.dart';
import './session_service.dart';

class StockService {
  final LocalDatabase localDatabase;
  final ProductLocalDataSource productLocal;
  final StockLogLocalDataSource stockLogLocal;
  final NotificationService notificationService;
  final SessionService sessionService;

  StockService(
    this.localDatabase,
    this.productLocal,
    this.stockLogLocal,
    this.notificationService,
    this.sessionService,
  );

  String get _businessId => sessionService.businessId ?? '';

  /// Records a stock movement and updates the product stock locally
  Future<void> updateStock({
    required String productId,
    required String productName,
    required int quantityChange,
    required StockLogType type,
    String? reason,
  }) async {
    final product = await productLocal.getProductById(productId);
    if (product == null) throw Exception('Produk tidak ditemukan');

    final currentStock = product.stock;
    final newStock = currentStock + quantityChange;

    await localDatabase.transaction(() async {
      // 1. Update Product Stock locally
      await productLocal.updateStock(productId, newStock);

      // 2. Create Local Stock Log
      final log = StockLogModel(
        id: DateTime.now().millisecondsSinceEpoch.toString() + productId,
        productId: productId,
        productName: productName,
        type: type,
        quantity: quantityChange,
        previousStock: currentStock,
        newStock: newStock,
        reason: reason,
        createdAt: DateTime.now(),
        businessId: _businessId,
      );
      await stockLogLocal.insertStockLog(log, syncStatus: 'pendingUpload');

      // 3. Add to sync queue
      await localDatabase.addToSyncQueue(
        businessId: _businessId,
        syncEntityName: 'stock_logs',
        documentId: log.id,
        operation: 'create',
        data: jsonEncode(log.toJson()),
      );

      await localDatabase.addToSyncQueue(
        businessId: _businessId,
        syncEntityName: 'products',
        documentId: productId,
        operation: 'update',
        data: jsonEncode(product.copyWith(stock: newStock).toJson()),
      );
    });

    // 4. Check for low stock alert
    if (newStock <= product.stockThreshold) {
      notificationService.showStockAlert(
        productName: productName,
        currentStock: newStock,
      );
    }
  }

  /// Get logs for a specific product locally
  Stream<List<StockLog>> getStockLogs(String productId) {
    return stockLogLocal.watchStockLogs(_businessId, productId: productId);
  }

  /// Get all logs locally
  Stream<List<StockLog>> getAllStockLogs() {
    return stockLogLocal.watchStockLogs(_businessId);
  }
}
