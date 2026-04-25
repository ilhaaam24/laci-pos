import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_collections.dart';
import '../../models/promo_model.dart';

abstract class PromoFirebaseDataSource {
  Stream<List<PromoModel>> getPromos();
  Future<String> createPromo(PromoModel promo);
  Future<void> updatePromo(PromoModel promo);
  Future<void> deletePromo(String id);
}

class PromoFirebaseDataSourceImpl implements PromoFirebaseDataSource {
  final FirebaseFirestore firestore;

  PromoFirebaseDataSourceImpl({required this.firestore});

  CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.promos);

  @override
  Stream<List<PromoModel>> getPromos() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PromoModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<String> createPromo(PromoModel promo) async {
    try {
      final docRef = await _collection.add(promo.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create promo: $e');
    }
  }

  @override
  Future<void> updatePromo(PromoModel promo) async {
    try {
      await _collection.doc(promo.id).update(promo.toFirestore());
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
