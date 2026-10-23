import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laci/core/constants/firebase_collections.dart';
import 'package:laci/data/models/user_model.dart';

import '../../../core/services/session_service.dart';

abstract class UserFirebaseDataSource {
  Future<UserModel?> getUserProfile(String uid);
  Future<UserModel?> getUserByEmail(String email);
  Future<void> createUserProfile(UserModel user);
  Future<void> updateUserProfile(UserModel user);
  Future<void> deleteUser(String uid);
  Future<List<UserModel>> getUsers();
}

class UserFirebaseDataSourceImpl implements UserFirebaseDataSource {
  final FirebaseFirestore firestore;
  final SessionService sessionService;

  UserFirebaseDataSourceImpl({
    required this.firestore,
    required this.sessionService,
  });

  CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.users);

  String get _businessId => sessionService.businessId ?? '';

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final snapshot = await _collection.where('email', isEqualTo: email).get();
    if (snapshot.docs.isNotEmpty) {
      return UserModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  @override
  Future<void> createUserProfile(UserModel user) async {
    await _collection.doc(user.id).set(user.toFirestore());
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    await _collection.doc(user.id).update(user.toFirestore());
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _collection.doc(uid).delete();
  }

  @override
  Future<List<UserModel>> getUsers() async {
    final snapshot = await _collection
        .where('businessId', isEqualTo: _businessId)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }
}
