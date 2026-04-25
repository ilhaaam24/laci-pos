import 'package:equatable/equatable.dart';

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
  });

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
  ];
}
