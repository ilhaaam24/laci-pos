import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart' as f_store;
import '../../../core/constants/firebase_collections.dart';
import '../../models/transaction_model.dart';
import '../../models/stock_log_model.dart';
import '../../../domain/entities/stock_log_entity.dart';
import '../../../core/services/notification_service.dart';

import '../../../core/services/session_service.dart';

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
  final NotificationService notificationService;
  final SessionService sessionService;

  TransactionFirebaseDataSourceImpl({
    required this.firestore,
    required this.notificationService,
    required this.sessionService,
  });

  f_store.CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.transactions);

  String get _businessId => sessionService.businessId ?? '';

  @override
  Future<String> createTransaction(TransactionModel transaction) async {
    if (_businessId.isEmpty) {
      throw Exception('Business ID is missing. Please re-login.');
    }
    try {
      // Start a batch write
      final batch = firestore.batch();

      // Create transaction document
      final transactionRef = _collection.doc(transaction.id);
      final data = transaction.toFirestore();
      data['businessId'] = _businessId;
      batch.set(transactionRef, data);

      // Create transaction items as subcollection
      for (var item in transaction.items) {
        final itemRef = transactionRef
            .collection(FirebaseCollections.transactionItems)
            .doc();

        // Convert TransactionItem to TransactionItemModel to get toMap()
        final itemModel = TransactionItemModel.fromEntity(
          item,
        ).copyWith(businessId: _businessId);
        batch.set(itemRef, itemModel.toMap());
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
        .where('businessId', isEqualTo: _businessId)
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
    final doc = await _collection.doc(id).get();
    if (!doc.exists) {
      throw Exception('Transaction not found');
    }
    final items = await _getTransactionItems(id);
    final transaction = TransactionModel.fromFirestore(doc, items);
    if (transaction.businessId != _businessId) {
      throw Exception('Unauthorized access to transaction');
    }
    return transaction;
  }

  @override
  Stream<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _collection
        .where('businessId', isEqualTo: _businessId)
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
