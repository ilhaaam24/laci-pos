import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_collections.dart';
import '../../models/category_model.dart';

abstract class CategoryFirebaseDataSource {
  Stream<List<CategoryModel>> getCategories();
  Future<CategoryModel> getCategoryById(String id);
  Future<String> createCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
}

class CategoryFirebaseDataSourceImpl implements CategoryFirebaseDataSource {
  final FirebaseFirestore firestore;

  CategoryFirebaseDataSourceImpl({required this.firestore});

  CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.categories);

  @override
  Stream<List<CategoryModel>> getCategories() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Category not found');
      }
      return CategoryModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  @override
  Future<String> createCategory(CategoryModel category) async {
    try {
      final docRef = await _collection.add(category.toFirestore());
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
