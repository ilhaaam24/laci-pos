import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laci/core/constants/firebase_collections.dart';
import 'package:laci/data/models/category_model.dart';

import '../../../core/services/session_service.dart';

abstract class CategoryFirebaseDataSource {
  Stream<List<CategoryModel>> getCategories();
  Future<CategoryModel> getCategoryById(String id);
  Future<String> createCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
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
    try {
      final data = category.toFirestore();
      data['businessId'] = _businessId;
      final docRef = await _collection.add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _collection.doc(category.id).update(category.toFirestore());
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
}
