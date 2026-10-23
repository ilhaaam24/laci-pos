import 'package:equatable/equatable.dart';
import 'product_variant.dart';

class Product extends Equatable {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final double costPrice;
  final int stock;
  final int stockThreshold;
  final String? imageUrl;
  final String? sku;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? businessId;
  final List<ProductVariant> variants;
  final List<ModifierGroup> modifierGroups;
  final bool trackStock;

  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.costPrice,
    required this.stock,
    this.stockThreshold = 5,
    this.imageUrl,
    this.sku,
    required this.createdAt,
    required this.updatedAt,
    this.businessId,
    this.variants = const [],
    this.modifierGroups = const [],
    this.trackStock = true,
  });

  bool get hasVariants => variants.isNotEmpty;
  bool get hasModifiers => modifierGroups.isNotEmpty;

  Product copyWith({
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
    bool? trackStock,
  }) {
    return Product(
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
      trackStock: trackStock ?? this.trackStock,
    );
  }

  @override
  List<Object?> get props => [
    id,
    categoryId,
    name,
    description,
    price,
    costPrice,
    stock,
    stockThreshold,
    imageUrl,
    sku,
    createdAt,
    updatedAt,
    businessId,
    variants,
    modifierGroups,
    trackStock,
  ];
}
