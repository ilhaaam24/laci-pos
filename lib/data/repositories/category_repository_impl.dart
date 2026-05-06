import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/firebase/category_firebase_datasource.dart';
import '../datasources/local/category_local_datasource.dart';
import '../datasources/local/local_database.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryFirebaseDataSource remoteDataSource;
  final CategoryLocalDataSource localDataSource;
  final LocalDatabase localDatabase;
  final SessionService sessionService;

  CategoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.localDatabase,
    required this.sessionService,
  });

  String get _businessId => sessionService.businessId ?? '';

  @override
  Stream<Either<String, List<Category>>> getCategories() {
    try {
      return localDataSource
          .watchCategories(_businessId)
          .map(
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
      final result = await localDataSource.getCategoryById(id);
      if (result != null) {
        return Right(result.toEntity());
      }
      return const Left('Kategori tidak ditemukan di lokal');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, String>> createCategory(Category category) async {
    try {
      final categoryId = category.id.isEmpty ? const Uuid().v4() : category.id;
      final model = CategoryModel.fromEntity(
        category,
      ).copyWith(id: categoryId, businessId: _businessId);

      // 1. Save to local DB
      await localDataSource.upsertCategory(model, syncStatus: 'pendingUpload');

      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        syncEntityName: 'categories',
        documentId: model.id,
        operation: 'create',
      );

      return Right(model.id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateCategory(Category category) async {
    try {
      final model = CategoryModel.fromEntity(category);

      // 1. Update local DB
      await localDataSource.upsertCategory(model, syncStatus: 'pendingUpload');

      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        syncEntityName: 'categories',
        documentId: model.id,
        operation: 'update',
      );

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteCategory(String id) async {
    try {
      // 1. Mark as deleted locally
      await localDataSource.markAsDeleted(id);

      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        syncEntityName: 'categories',
        documentId: id,
        operation: 'delete',
      );

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
