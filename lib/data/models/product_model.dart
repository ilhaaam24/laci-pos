import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product_entity.dart';

class ProductModel extends Product {
  const ProductModel({
    required String id,
    required String categoryId,
    required String name,
    String? description,
    required double price,
    required int stock,
    String? imageUrl,
    String? sku,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
         id: id,
         categoryId: categoryId,
         name: name,
         description: description,
         price: price,
         stock: stock,
         imageUrl: imageUrl,
         sku: sku,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      price: (data['price'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      imageUrl: data['imageUrl'],
      sku: data['sku'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'sku': sku,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Product toEntity() {
    return Product(
      id: id,
      categoryId: categoryId,
      name: name,
      description: description,
      price: price,
      stock: stock,
      imageUrl: imageUrl,
      sku: sku,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      categoryId: product.categoryId,
      name: product.name,
      description: product.description,
      price: product.price,
      stock: product.stock,
      imageUrl: product.imageUrl,
      sku: product.sku,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }
}
