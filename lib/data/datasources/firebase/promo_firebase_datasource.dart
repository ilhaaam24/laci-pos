import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laci/core/constants/firebase_collections.dart';
import 'package:laci/data/models/promo_model.dart';

import '../../../core/services/session_service.dart';

abstract class PromoFirebaseDataSource {
  Stream<List<PromoModel>> getPromos();
  Future<String> createPromo(PromoModel promo);
  Future<void> updatePromo(PromoModel promo);
  Future<void> deletePromo(String id);
}

class PromoFirebaseDataSourceImpl implements PromoFirebaseDataSource {
  final FirebaseFirestore firestore;
  final SessionService sessionService;

  PromoFirebaseDataSourceImpl({
    required this.firestore,
    required this.sessionService,
  });

  CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.promos);

  String get _businessId => sessionService.businessId ?? '';

  @override
  Stream<List<PromoModel>> getPromos() {
    return _collection
        .where('businessId', isEqualTo: _businessId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PromoModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<String> createPromo(PromoModel promo) async {
    if (_businessId.isEmpty) {
      throw Exception('Business ID is missing. Please re-login.');
    }
    try {
      final data = promo.toFirestore();
      data['businessId'] = _businessId;
      await _collection.doc(promo.id).set(data);
      return promo.id;
    } catch (e) {
      throw Exception('Failed to create promo: $e');
    }
  }

  @override
  Future<void> updatePromo(PromoModel promo) async {
    if (_businessId.isEmpty) {
      throw Exception('Business ID is missing. Please re-login.');
    }
    try {
      final data = promo.toFirestore();
      data['businessId'] = _businessId;
      await _collection.doc(promo.id).update(data);
    } catch (e) {
      throw Exception('Failed to update promo: $e');
    }
  }

  @override
  Future<void> deletePromo(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete promo: $e');
    }
  }
}
