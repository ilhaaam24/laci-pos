import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laci/core/constants/firebase_collections.dart';
import 'package:laci/data/models/stock_log_model.dart';
import '../../../core/services/session_service.dart';

abstract class StockLogFirebaseDataSource {
  Stream<List<StockLogModel>> getStockLogs({String? productId});
  Future<void> createStockLog(StockLogModel log);
}

class StockLogFirebaseDataSourceImpl implements StockLogFirebaseDataSource {
  final FirebaseFirestore firestore;
  final SessionService sessionService;

  StockLogFirebaseDataSourceImpl({
    required this.firestore,
    required this.sessionService,
  });

  CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.stockLogs);

  String get _businessId => sessionService.businessId ?? '';

  @override
  Stream<List<StockLogModel>> getStockLogs({String? productId}) {
    var query = _collection.where('businessId', isEqualTo: _businessId);

    if (productId != null) {
      query = query.where('productId', isEqualTo: productId);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => StockLogModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> createStockLog(StockLogModel log) async {
    if (_businessId.isEmpty) {
      throw Exception('Business ID is missing. Please re-login.');
    }
    final data = log.toFirestore();
    data['businessId'] = _businessId;
    await _collection.doc(log.id).set(data);
  }
}
