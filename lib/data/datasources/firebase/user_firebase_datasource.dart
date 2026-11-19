import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laci/core/constants/firebase_collections.dart';
import 'package:laci/data/models/user_model.dart';

import '../../../core/services/session_service.dart';

abstract class UserFirebaseDataSource {
  Future<UserModel?> getUserProfile(String uid);
  Future<UserModel?> getUserByEmail(String email);
  Future<List<UserModel>> getAllUsersByEmail(String email);
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
    final users = await getAllUsersByEmail(email);
    if (users.isNotEmpty) {
      return users.first;
    }
    return null;
  }

  @override
  Future<List<UserModel>> getAllUsersByEmail(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return [];

    try {
      final snapshot =
          await _collection.where('email', isEqualTo: cleanEmail).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();
      }
      // Fallback in case existing record was saved with raw casing
      if (cleanEmail != email.trim()) {
        final rawSnapshot =
            await _collection.where('email', isEqualTo: email.trim()).get();
        if (rawSnapshot.docs.isNotEmpty) {
          return rawSnapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
        }
      }
    } catch (e) {
      log('UserFirebaseDataSource: Error in getAllUsersByEmail: $e');
    }
    return [];
  }

  @override
  Future<void> createUserProfile(UserModel user) async {
    final data = user.toFirestore();
    if (user.email.isNotEmpty) {
      data['email'] = user.email.toLowerCase().trim();
    }
    await _collection.doc(user.id).set(data, SetOptions(merge: true));
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
