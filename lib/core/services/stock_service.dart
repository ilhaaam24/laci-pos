import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firebase_collections.dart';
import '../../data/models/stock_log_model.dart';
import '../../domain/entities/stock_log_entity.dart';
import './notification_service.dart';

class StockService {
  final FirebaseFirestore firestore;
  final NotificationService notificationService;

  StockService(this.firestore, this.notificationService);

  /// Records a stock movement and updates the product stock
  Future<void> updateStock({
    required String productId,
    required String productName,
    required int quantityChange,
    required StockLogType type,
    String? reason,
  }) async {
    final batch = firestore.batch();
    final productRef = firestore
        .collection(FirebaseCollections.products)
        .doc(productId);

    // Get current stock to calculate new stock for the log
    final productDoc = await productRef.get();
    if (!productDoc.exists) throw Exception('Produk tidak ditemukan');

    final productData = productDoc.data() as Map<String, dynamic>;
    final currentStock = productData['stock'] ?? 0;
    final stockThreshold = productData['stockThreshold'] ?? 5;
    final newStock = currentStock + quantityChange;

    // 1. Update Product Stock
    batch.update(productRef, {
      'stock': newStock,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Create Stock Log
    final logRef = firestore.collection(FirebaseCollections.stockLogs).doc();
    final log = StockLogModel(
      id: logRef.id,
      productId: productId,
      productName: productName,
      type: type,
      quantity: quantityChange,
      previousStock: currentStock,
      newStock: newStock,
      reason: reason,
      createdAt: DateTime.now(),
    );

    batch.set(logRef, log.toFirestore());

    await batch.commit();

    // 3. Check for low stock alert
    if (newStock <= stockThreshold) {
      notificationService.showStockAlert(
        productName: productName,
        currentStock: newStock,
      );
    }
  }

  /// Get logs for a specific product
  Stream<List<StockLog>> getStockLogs(String productId) {
    return firestore
        .collection(FirebaseCollections.stockLogs)
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StockLogModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get all logs with optional date range
  Stream<List<StockLog>> getAllStockLogs({DateTime? start, DateTime? end}) {
    Query query = firestore
        .collection(FirebaseCollections.stockLogs)
        .orderBy('createdAt', descending: true);

    if (start != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    }
    if (end != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(end),
      );
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => StockLogModel.fromFirestore(doc)).toList(),
    );
  }
}
