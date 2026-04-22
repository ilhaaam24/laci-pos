import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/category_entity.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required String id,
    required String name,
    String? description,
    String? imageUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
         id: id,
         name: name,
         description: description,
         imageUrl: imageUrl,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      description: category.description,
      imageUrl: category.imageUrl,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }
}
