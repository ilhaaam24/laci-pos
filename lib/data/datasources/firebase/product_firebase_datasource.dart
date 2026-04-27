import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_collections.dart';
import '../../models/product_model.dart';
import '../../models/stock_log_model.dart';
import '../../../domain/entities/stock_log_entity.dart';

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
      final batch = firestore.batch();
      final docRef = _collection.doc(product.id);

      batch.set(docRef, product.toFirestore());

      // Initial Stock Log
      if (product.stock > 0) {
        final logRef = firestore
            .collection(FirebaseCollections.stockLogs)
            .doc();
        final log = StockLogModel(
          id: logRef.id,
          productId: product.id,
          productName: product.name,
          type: StockLogType.stockIn,
          quantity: product.stock,
          previousStock: 0,
          newStock: product.stock,
          reason: 'Stok awal produk',
          createdAt: DateTime.now(),
        );
        batch.set(logRef, log.toFirestore());
      }

      await batch.commit();
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    try {
      final batch = firestore.batch();
      final docRef = _collection.doc(product.id);

      // Get old product to check stock change
      final oldDoc = await docRef.get();
      if (oldDoc.exists) {
        final oldData = oldDoc.data() as Map<String, dynamic>;
        final oldStock = oldData['stock'] ?? 0;

        if (oldStock != product.stock) {
          final diff = product.stock - oldStock;
          final logRef = firestore
              .collection(FirebaseCollections.stockLogs)
              .doc();
          final log = StockLogModel(
            id: logRef.id,
            productId: product.id,
            productName: product.name,
            type: diff > 0 ? StockLogType.stockIn : StockLogType.stockOut,
            quantity: diff.toInt(),
            previousStock: oldStock,
            newStock: product.stock,
            reason: 'Perubahan manual melalui edit produk',
            createdAt: DateTime.now(),
          );
          batch.set(logRef, log.toFirestore());
        }
      }

      batch.update(docRef, product.toFirestore());
      await batch.commit();
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
