import 'package:dartz/dartz.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/firebase/category_firebase_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryFirebaseDataSource dataSource;

  CategoryRepositoryImpl({required this.dataSource});

  @override
  Stream<Either<String, List<Category>>> getCategories() {
    try {
      return dataSource.getCategories().map(
        (categories) => Right<String, List<Category>>(
          categories.map((model) => model.toEntity()).toList(),
        ),
      );
    } catch (e) {
      return Stream.value(Left(e.toString()));
    }
  }

  @override
  Future<Either<String, Category>> getCategoryById(String id) async {
    try {
      final result = await dataSource.getCategoryById(id);
      return Right(result.toEntity());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, String>> createCategory(Category category) async {
    try {
      final model = CategoryModel.fromEntity(category);
      final id = await dataSource.createCategory(model);
      return Right(id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateCategory(Category category) async {
    try {
      final model = CategoryModel.fromEntity(category);
      await dataSource.updateCategory(model);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteCategory(String id) async {
    try {
      await dataSource.deleteCategory(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
