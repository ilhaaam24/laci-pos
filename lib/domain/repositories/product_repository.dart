import 'package:dartz/dartz.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Stream<Either<String, List<Product>>> getProducts();
  Future<Either<String, Product>> getProductById(String id);
  Future<Either<String, String>> createProduct(Product product);
  Future<Either<String, void>> updateProduct(Product product);
  Future<Either<String, void>> deleteProduct(String id);
  Stream<Either<String, List<Product>>> getProductsByCategory(
    String categoryId,
  );
}
