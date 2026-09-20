import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_variant.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.categoryId,
    required super.name,
    super.description,
    required super.price,
    required super.costPrice,
    required super.stock,
    super.stockThreshold,
    super.imageUrl,
    super.sku,
    required super.createdAt,
    required super.updatedAt,
    super.businessId,
    super.variants = const [],
    super.modifierGroups = const [],
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      price: (data['price'] ?? 0).toDouble(),
      costPrice: (data['costPrice'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      stockThreshold: data['stockThreshold'] ?? 5,
      imageUrl: data['imageUrl'],
      sku: data['sku'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      businessId: data['businessId'],
      variants: (data['variants'] as List<dynamic>?)
              ?.map(
                (v) => ProductVariant.fromJson(
                  Map<String, dynamic>.from(v as Map),
                ),
              )
              .toList() ??
          const [],
      modifierGroups: (data['modifierGroups'] as List<dynamic>?)
              ?.map(
                (g) => ModifierGroup.fromJson(
                  Map<String, dynamic>.from(g as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'stockThreshold': stockThreshold,
      'imageUrl': imageUrl,
      'sku': sku,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'businessId': businessId,
      'variants': variants.map((v) => v.toJson()).toList(),
      'modifierGroups': modifierGroups.map((g) => g.toJson()).toList(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'stockThreshold': stockThreshold,
      'imageUrl': imageUrl,
      'sku': sku,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'businessId': businessId,
      'variants': variants.map((v) => v.toJson()).toList(),
      'modifierGroups': modifierGroups.map((g) => g.toJson()).toList(),
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      stockThreshold: json['stockThreshold'] ?? 5,
      imageUrl: json['imageUrl'],
      sku: json['sku'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      businessId: json['businessId'],
      variants: (json['variants'] as List<dynamic>?)
              ?.map(
                (v) => ProductVariant.fromJson(
                  Map<String, dynamic>.from(v as Map),
                ),
              )
              .toList() ??
          const [],
      modifierGroups: (json['modifierGroups'] as List<dynamic>?)
              ?.map(
                (g) => ModifierGroup.fromJson(
                  Map<String, dynamic>.from(g as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      categoryId: categoryId,
      name: name,
      description: description,
      price: price,
      costPrice: costPrice,
      stock: stock,
      stockThreshold: stockThreshold,
      imageUrl: imageUrl,
      sku: sku,
      createdAt: createdAt,
      updatedAt: updatedAt,
      businessId: businessId,
      variants: variants,
      modifierGroups: modifierGroups,
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      categoryId: product.categoryId,
      name: product.name,
      description: product.description,
      price: product.price,
      costPrice: product.costPrice,
      stock: product.stock,
      stockThreshold: product.stockThreshold,
      imageUrl: product.imageUrl,
      sku: product.sku,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      businessId: product.businessId,
      variants: product.variants,
      modifierGroups: product.modifierGroups,
    );
  }

  ProductModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    double? costPrice,
    int? stock,
    int? stockThreshold,
    String? imageUrl,
    String? sku,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? businessId,
    List<ProductVariant>? variants,
    List<ModifierGroup>? modifierGroups,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      stockThreshold: stockThreshold ?? this.stockThreshold,
      imageUrl: imageUrl ?? this.imageUrl,
      sku: sku ?? this.sku,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      businessId: businessId ?? this.businessId,
      variants: variants ?? this.variants,
      modifierGroups: modifierGroups ?? this.modifierGroups,
    );
  }
}
