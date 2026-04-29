import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? businessId;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.businessId,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    imageUrl,
    createdAt,
    updatedAt,
    businessId,
  ];
}
