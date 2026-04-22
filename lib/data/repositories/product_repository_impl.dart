import 'package:dartz/dartz.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/firebase/product_firebase_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductFirebaseDataSource dataSource;

  ProductRepositoryImpl({required this.dataSource});

  @override
  Stream<Either<String, List<Product>>> getProducts() {
    try {
      return dataSource.getProducts().map(
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
      final result = await dataSource.getProductById(id);
      return Right(result.toEntity());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, String>> createProduct(Product product) async {
    try {
      final model = ProductModel.fromEntity(product);
      final id = await dataSource.createProduct(model);
      return Right(id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateProduct(Product product) async {
    try {
      final model = ProductModel.fromEntity(product);
      await dataSource.updateProduct(model);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteProduct(String id) async {
    try {
      await dataSource.deleteProduct(id);
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
      return dataSource
          .getProductsByCategory(categoryId)
          .map(
            (products) => Right<String, List<Product>>(
              products.map((model) => model.toEntity()).toList(),
            ),
          );
    } catch (e) {
      return Stream.value(Left(e.toString()));
    }
  }
}
