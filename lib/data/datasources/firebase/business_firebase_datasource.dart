import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laci/data/models/business_model.dart';
import '../../../core/constants/firebase_collections.dart';

abstract class BusinessFirebaseDataSource {
  Future<BusinessInfoModel> getBusinessInfo();
  Future<void> updateBusinessInfo(BusinessInfoModel businessInfo);
}

class BusinessFirebaseDataSourceImpl implements BusinessFirebaseDataSource {
  final FirebaseFirestore firestore;

  BusinessFirebaseDataSourceImpl({required this.firestore});

  CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.businessInfo);

  @override
  Future<BusinessInfoModel> getBusinessInfo() async {
    final snapshot = await _collection.limit(1).get();
    if (snapshot.docs.isEmpty) {
      // Create default business info
      final defaultInfo = BusinessInfoModel(
        id: '',
        businessName: 'Toko Saya',
        address: '-',
        phone: '-',
        email: '-',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final docRef = await _collection.add(defaultInfo.toFirestore());
      return BusinessInfoModel(
        id: docRef.id,
        businessName: defaultInfo.businessName,
        address: defaultInfo.address,
        phone: defaultInfo.phone,
        email: defaultInfo.email,
        createdAt: defaultInfo.createdAt,
        updatedAt: defaultInfo.updatedAt,
      );
    }
    return BusinessInfoModel.fromFirestore(snapshot.docs.first);
  }

  @override
  Future<void> updateBusinessInfo(BusinessInfoModel businessInfo) async {
    await _collection.doc(businessInfo.id).update(businessInfo.toFirestore());
  }
}
