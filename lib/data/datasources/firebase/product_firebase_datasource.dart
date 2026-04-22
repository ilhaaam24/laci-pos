import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_collections.dart';
import '../../models/product_model.dart';

abstract class ProductFirebaseDataSource {
  Stream<List<ProductModel>> getProducts();
  Future<ProductModel> getProductById(String id);
  Future<String> createProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Stream<List<ProductModel>> getProductsByCategory(String categoryId);
  Future<void> updateStock(String productId, int newStock);
}

class ProductFirebaseDataSourceImpl implements ProductFirebaseDataSource {
  final FirebaseFirestore firestore;

  ProductFirebaseDataSourceImpl({required this.firestore});

  CollectionReference get _collection =>
      firestore.collection(FirebaseCollections.products);

  @override
  Stream<List<ProductModel>> getProducts() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Product not found');
      }
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  @override
  Future<String> createProduct(ProductModel product) async {
    try {
      final docRef = await _collection.add(product.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _collection.doc(product.id).update(product.toFirestore());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  @override
  Stream<List<ProductModel>> getProductsByCategory(String categoryId) {
    return _collection
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _collection.doc(productId).update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }
}
