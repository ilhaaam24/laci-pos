import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laci/core/constants/firebase_collections.dart';
import 'package:laci/data/models/business_model.dart';

import '../../../core/services/session_service.dart';
import 'category_firebase_datasource.dart';

abstract class BusinessFirebaseDataSource {
  Future<BusinessInfoModel> getBusinessInfo();
  Future<void> updateBusinessInfo(BusinessInfoModel businessInfo);
}

class BusinessFirebaseDataSourceImpl implements BusinessFirebaseDataSource {
  final FirebaseFirestore firestore;
  final SessionService sessionService;
  final CategoryFirebaseDataSource categoryDataSource;

  BusinessFirebaseDataSourceImpl({
    required this.firestore,
    required this.sessionService,
    required this.categoryDataSource,
  });

  CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.businessInfo);

  String get _businessId => sessionService.businessId ?? '';

  @override
  Future<BusinessInfoModel> getBusinessInfo() async {
    log(
      'BusinessFirebaseDataSource: Fetching business info for ID: "$_businessId"',
    );
    if (_businessId.isEmpty) {
      log('BusinessFirebaseDataSource: businessId is empty, returning default');
      // If no businessId yet, return default and potentially wait for setup
      return BusinessInfoModel(
        id: '',
        businessName: 'Toko Baru',
        address: '-',
        phone: '-',
        email: '-',
        qrisUrl: '',
        logoUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    log(
      'BusinessFirebaseDataSource: Querying Firestore collection "${FirebaseCollections.businessInfo}" for document "$_businessId"',
    );
    final doc = await _collection.doc(_businessId).get();
    if (!doc.exists) {
      final defaultInfo = BusinessInfoModel(
        id: _businessId,
        businessName: 'Toko Saya',
        address: '-',
        phone: '-',
        email: '-',
        qrisUrl: '',
        logoUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _collection.doc(_businessId).set(defaultInfo.toFirestore());

      // Auto seed default categories for new business
      try {
        await categoryDataSource.seedDefaultCategories(_businessId);
      } catch (e) {
        log('BusinessFirebaseDataSource: Error seeding default categories: $e');
      }

      return defaultInfo;
    }
    return BusinessInfoModel.fromFirestore(doc);
  }

  @override
  Future<void> updateBusinessInfo(BusinessInfoModel businessInfo) async {
    await _collection
        .doc(businessInfo.id)
        .set(businessInfo.toFirestore(), SetOptions(merge: true));
  }
}
