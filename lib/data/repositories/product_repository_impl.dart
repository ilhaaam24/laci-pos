import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/firebase/product_firebase_datasource.dart';
import '../datasources/local/local_database.dart';
import '../datasources/local/product_local_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductFirebaseDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final LocalDatabase localDatabase;
  final SessionService sessionService;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.localDatabase,
    required this.sessionService,
  });

  String get _businessId => sessionService.businessId ?? '';

  @override
  Stream<Either<String, List<Product>>> getProducts() {
    try {
      return localDataSource
          .watchProducts(_businessId)
          .map(
            (products) => Right<String, List<Product>>(
              products.map((model) => model.toEntity()).toList(),
            ),
          );
    } catch (e) {
      return Stream.value(Left(e.toString()));
    }
  }

  @override
  Future<Either<String, Product>> getProductById(String id) async {
    try {
      final result = await localDataSource.getProductById(id);
      if (result != null) {
        return Right(result.toEntity());
      }
      return const Left('Produk tidak ditemukan di lokal');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, String>> createProduct(Product product) async {
    try {
      final productId = product.id.isEmpty ? const Uuid().v4() : product.id;
      final model = ProductModel.fromEntity(
        product,
      ).copyWith(id: productId, businessId: _businessId);

      // 1. Save to local DB
      await localDataSource.upsertProduct(model, syncStatus: 'pendingUpload');

      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        syncEntityName: 'products',
        documentId: model.id,
        operation: 'create',
        businessId: _businessId,
        data: jsonEncode(model.toJson()),
      );

      return Right(model.id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateProduct(Product product) async {
    try {
      final model = ProductModel.fromEntity(product);

      // 1. Update local DB
      await localDataSource.upsertProduct(model, syncStatus: 'pendingUpload');

      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        syncEntityName: 'products',
        documentId: model.id,
        operation: 'update',
        businessId: _businessId,
        data: jsonEncode(model.toJson()),
      );

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteProduct(String id) async {
    try {
      // 1. Mark as deleted in local DB
      await localDataSource.markAsDeleted(id);

      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        syncEntityName: 'products',
        documentId: id,
        operation: 'delete',
        businessId: _businessId,
      );

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Stream<Either<String, List<Product>>> getProductsByCategory(
    String categoryId,
  ) {
    try {
      // We could add a more specific query in localDataSource if needed
      return localDataSource
          .watchProducts(_businessId)
          .map(
            (products) => Right<String, List<Product>>(
              products
                  .where((p) => p.categoryId == categoryId)
                  .map((model) => model.toEntity())
                  .toList(),
            ),
          );
    } catch (e) {
      return Stream.value(Left(e.toString()));
    }
  }
}
