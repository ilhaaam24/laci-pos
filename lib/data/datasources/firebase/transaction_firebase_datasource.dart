import 'package:cloud_firestore/cloud_firestore.dart' as f_store;
import '../../../core/constants/firebase_collections.dart';
import '../../models/transaction_model.dart';

abstract class TransactionFirebaseDataSource {
  Future<String> createTransaction(TransactionModel transaction);
  Stream<List<TransactionModel>> getTransactions();
  Future<TransactionModel> getTransactionById(String id);
  Stream<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
}

class TransactionFirebaseDataSourceImpl
    implements TransactionFirebaseDataSource {
  final f_store.FirebaseFirestore firestore;

  TransactionFirebaseDataSourceImpl({required this.firestore});

  f_store.CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.transactions);

  @override
  Future<String> createTransaction(TransactionModel transaction) async {
    try {
      // Start a batch write
      final batch = firestore.batch();

      // Create transaction document
      final transactionRef = _collection.doc(transaction.id);
      batch.set(transactionRef, transaction.toFirestore());

      // Create transaction items as subcollection
      for (var item in transaction.items) {
        final itemRef = transactionRef
            .collection(FirebaseCollections.transactionItems)
            .doc();

        // Convert TransactionItem to TransactionItemModel to get toMap()
        final itemModel = TransactionItemModel.fromEntity(item);
        batch.set(itemRef, itemModel.toMap());

        // Update product stock
        final productRef = firestore
            .collection(FirebaseCollections.products)
            .doc(item.productId);
        batch.update(productRef, {
          'stock': f_store.FieldValue.increment(-item.quantity),
          'updatedAt': f_store.FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return transactionRef.id;
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  @override
  Stream<List<TransactionModel>> getTransactions() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<TransactionModel> transactions = [];

          for (var doc in snapshot.docs) {
            final items = await _getTransactionItems(doc.id);
            transactions.add(TransactionModel.fromFirestore(doc, items));
          }

          return transactions;
        });
  }

  @override
  Future<TransactionModel> getTransactionById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Transaction not found');
      }
      final items = await _getTransactionItems(id);
      return TransactionModel.fromFirestore(doc, items);
    } catch (e) {
      throw Exception('Failed to fetch transaction: $e');
    }
  }

  @override
  Stream<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _collection
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: f_store.Timestamp.fromDate(startDate),
        )
        .where('createdAt', isLessThan: f_store.Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<TransactionModel> transactions = [];

          for (var doc in snapshot.docs) {
            final items = await _getTransactionItems(doc.id);
            transactions.add(TransactionModel.fromFirestore(doc, items));
          }

          return transactions;
        });
  }

  Future<List<TransactionItemModel>> _getTransactionItems(
    String transactionId,
  ) async {
    final itemsSnapshot = await _collection
        .doc(transactionId)
        .collection(FirebaseCollections.transactionItems)
        .get();

    return itemsSnapshot.docs
        .map((doc) => TransactionItemModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
