import 'package:dartz/dartz.dart';
import '../entities/category_entity.dart';

abstract class CategoryRepository {
  Stream<Either<String, List<Category>>> getCategories();
  Future<Either<String, Category>> getCategoryById(String id);
  Future<Either<String, String>> createCategory(Category category);
  Future<Either<String, void>> updateCategory(Category category);
  Future<Either<String, void>> deleteCategory(String id);
}
