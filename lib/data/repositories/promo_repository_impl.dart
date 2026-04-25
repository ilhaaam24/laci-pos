import 'package:dartz/dartz.dart';
import '../../domain/entities/promo_entity.dart';
import '../../domain/repositories/promo_repository.dart';
import '../datasources/firebase/promo_firebase_datasource.dart';
import '../models/promo_model.dart';

class PromoRepositoryImpl implements PromoRepository {
  final PromoFirebaseDataSource dataSource;

  PromoRepositoryImpl({required this.dataSource});

  @override
  Stream<Either<String, List<PromoEntity>>> getPromos() {
    try {
      return dataSource.getPromos().map(
        (promos) => Right<String, List<PromoEntity>>(
          promos.map((model) => model).toList(),
        ),
      );
    } catch (e) {
      return Stream.value(Left(e.toString()));
    }
  }

  @override
  Future<Either<String, String>> createPromo(PromoEntity promo) async {
    try {
      final model = PromoModel.fromEntity(promo);
      final id = await dataSource.createPromo(model);
      return Right(id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updatePromo(PromoEntity promo) async {
    try {
      final model = PromoModel.fromEntity(promo);
      await dataSource.updatePromo(model);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deletePromo(String id) async {
    try {
      await dataSource.deletePromo(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
