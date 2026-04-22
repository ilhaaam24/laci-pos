import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final int stock;
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
    required this.stock,
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
    stock,
    imageUrl,
    sku,
    createdAt,
    updatedAt,
  ];
}
