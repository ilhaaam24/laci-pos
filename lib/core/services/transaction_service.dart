import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laci/core/constants/firebase_collections.dart';
import 'package:laci/data/models/transaction_model.dart';

import '../../domain/entities/transaction_entity.dart';
import './notification_service.dart';

class TransactionService {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  TransactionService(this._firestore, this._notificationService);

  /// Process transaction with atomic stock update
  Future<String> processTransaction(TransactionEntity transaction) async {
    try {
      // Validate stock availability first (outside transaction for quick check)
      await _validateStockAvailability(transaction.items);

      // Use Firestore transaction for atomic operations
      final transactionId = await _firestore.runTransaction<String>((
        firestoreTransaction,
      ) async {
        // --- STEP 1: READS (Must be performed before any writes) ---

        // Pre-fetch all product snapshots
        final Map<String, DocumentSnapshot> productSnapshots = {};
        for (final item in transaction.items) {
          final productRef = _firestore
              .collection(FirebaseCollections.products)
              .doc(item.productId);

          final snapshot = await firestoreTransaction.get(productRef);
          if (!snapshot.exists) {
            throw Exception('Produk ${item.productName} tidak ditemukan');
          }
          productSnapshots[item.productId] = snapshot;
        }

        // --- STEP 2: WRITES ---

        // 1. Create transaction document
        final transactionRef = _firestore
            .collection(FirebaseCollections.transactions)
            .doc(transaction.id);

        final transactionModel = TransactionModel.fromEntity(transaction);
        firestoreTransaction.set(
          transactionRef,
          transactionModel.toFirestore(),
        );

        // 2. Create transaction items as subcollection and update stock
        for (final item in transaction.items) {
          final itemRef = transactionRef
              .collection(FirebaseCollections.transactionItems)
              .doc();

          firestoreTransaction.set(
            itemRef,
            TransactionItemModel.fromEntity(item).toMap(),
          );

          // 3. Update product stock atomically
          final snapshot = productSnapshots[item.productId]!;
          final currentStock =
              (snapshot.data() as Map<String, dynamic>)['stock'] ?? 0;
          final newStock = (currentStock as num).toInt() - item.quantity;

          if (newStock < 0) {
            throw Exception(
              'Stok tidak cukup untuk ${item.productName}. Tersedia: $currentStock',
            );
          }

          final productRef = _firestore
              .collection(FirebaseCollections.products)
              .doc(item.productId);

          firestoreTransaction.update(productRef, {
            'stock': newStock,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Check for low stock alert
          final stockThreshold = (snapshot.data() as Map<String, dynamic>)['stockThreshold'] ?? 5;
          if (newStock <= stockThreshold) {
            _notificationService.showStockAlert(
              productName: item.productName,
              currentStock: newStock,
            );
          }
        }

        return transactionRef.id;
      }, timeout: const Duration(seconds: 30));

      return transactionId;
    } catch (e) {
      throw Exception('Gagal memproses transaksi: $e');
    }
  }

  /// Validate stock before processing
  Future<void> _validateStockAvailability(List<TransactionItem> items) async {
    for (final item in items) {
      final productDoc = await _firestore
          .collection(FirebaseCollections.products)
          .doc(item.productId)
          .get();

      if (!productDoc.exists) {
        throw Exception('Produk ${item.productName} tidak ditemukan');
      }

      final currentStock = (productDoc.data()!['stock'] as num).toInt();

      if (currentStock < item.quantity) {
        throw Exception(
          'Stok tidak cukup untuk ${item.productName}. Tersedia: $currentStock, Diminta: ${item.quantity}',
        );
      }
    }
  }

  /// Cancel transaction and restore stock
  Future<void> cancelTransaction(String transactionId) async {
    try {
      await _firestore.runTransaction((firestoreTransaction) async {
        final transactionRef = _firestore
            .collection(FirebaseCollections.transactions)
            .doc(transactionId);

        // Get transaction items
        final itemsSnapshot = await transactionRef
            .collection(FirebaseCollections.transactionItems)
            .get();

        // Restore stock for each item
        for (final itemDoc in itemsSnapshot.docs) {
          final data = itemDoc.data();
          final productId = data['productId'] as String;
          final quantity = data['quantity'] as int;

          final productRef = _firestore
              .collection(FirebaseCollections.products)
              .doc(productId);

          firestoreTransaction.update(productRef, {
            'stock': FieldValue.increment(quantity),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update transaction status
        firestoreTransaction.update(transactionRef, {
          'status': TransactionStatus.cancelled.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to cancel transaction: $e');
    }
  }

  /// Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts({
    int threshold = 10,
  }) async {
    final snapshot = await _firestore
        .collection(FirebaseCollections.products)
        .where('stock', isLessThanOrEqualTo: threshold)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc.data()['name'],
        'stock': doc.data()['stock'],
      };
    }).toList();
  }

  /// Stock adjustment (for manual stock updates)
  Future<void> adjustStock(
    String productId,
    int adjustment,
    String reason,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final productRef = _firestore
            .collection(FirebaseCollections.products)
            .doc(productId);

        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception('Product not found');
        }

        final currentStock = (productSnapshot.data()!['stock'] as num).toInt();
        final newStock = currentStock + adjustment;

        if (newStock < 0) {
          throw Exception('Stock cannot be negative');
        }

        transaction.update(productRef, {
          'stock': newStock,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Log stock adjustment
        final adjustmentRef = _firestore.collection('stock_adjustments').doc();

        transaction.set(adjustmentRef, {
          'productId': productId,
          'previousStock': currentStock,
          'adjustment': adjustment,
          'newStock': newStock,
          'reason': reason,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to adjust stock: $e');
    }
  }
}
