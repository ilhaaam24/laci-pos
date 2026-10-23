import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laci/core/constants/firebase_collections.dart';
import 'package:laci/data/models/category_model.dart';
import '../../../core/constants/default_categories.dart';
import '../../../core/services/session_service.dart';

abstract class CategoryFirebaseDataSource {
  Stream<List<CategoryModel>> getCategories();
  Future<CategoryModel> getCategoryById(String id);
  Future<String> createCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
  Future<List<CategoryModel>> seedDefaultCategories(String businessId);
}

class CategoryFirebaseDataSourceImpl implements CategoryFirebaseDataSource {
  final FirebaseFirestore firestore;
  final SessionService sessionService;

  CategoryFirebaseDataSourceImpl({
    required this.firestore,
    required this.sessionService,
  });

  CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.categories);

  String get _businessId => sessionService.businessId ?? '';

  @override
  Stream<List<CategoryModel>> getCategories() {
    return _collection
        .where('businessId', isEqualTo: _businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) {
      throw Exception('Category not found');
    }
    final category = CategoryModel.fromFirestore(doc);
    if (category.businessId != _businessId) {
      throw Exception('Unauthorized access to category');
    }
    return category;
  }

  @override
  Future<String> createCategory(CategoryModel category) async {
    if (_businessId.isEmpty) {
      throw Exception('Business ID is missing. Please re-login.');
    }
    try {
      final data = category.toFirestore();
      data['businessId'] = _businessId;
      await _collection.doc(category.id).set(data);
      return category.id;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    if (_businessId.isEmpty) {
      throw Exception('Business ID is missing. Please re-login.');
    }
    try {
      final data = category.toFirestore();
      data['businessId'] = _businessId;
      await _collection.doc(category.id).update(data);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      // Check if category has products
      final products = await firestore
          .collection(FirebaseCollections.products)
          .where('categoryId', isEqualTo: id)
          .get();

      if (products.docs.isNotEmpty) {
        throw Exception('Cannot delete category with existing products');
      }

      await _collection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  @override
  Future<List<CategoryModel>> seedDefaultCategories(String businessId) async {
    if (businessId.isEmpty) return [];

    try {
      // Check if categories already exist for this business
      final existing = await _collection
          .where('businessId', isEqualTo: businessId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        log(
          'CategoryFirebaseDataSource: Categories already exist for business "$businessId", skipping seeding.',
        );
        return [];
      }

      log(
        'CategoryFirebaseDataSource: Seeding default categories for business "$businessId"...',
      );
      final defaults = DefaultCategories.getDefaults(businessId);
      final batch = firestore.batch();

      for (final cat in defaults) {
        final docRef = _collection.doc(cat.id);
        batch.set(docRef, cat.toFirestore());
      }

      await batch.commit();
      log(
        'CategoryFirebaseDataSource: Successfully seeded ${defaults.length} default categories.',
      );
      return defaults;
    } catch (e) {
      log('CategoryFirebaseDataSource: Failed to seed default categories: $e');
      return [];
    }
  }
}
