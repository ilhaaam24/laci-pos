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
  });

  bool get hasVariants => variants.isNotEmpty;
  bool get hasModifiers => modifierGroups.isNotEmpty;

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
  ];
}
