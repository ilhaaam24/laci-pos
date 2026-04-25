import 'package:dartz/dartz.dart';
import '../entities/promo_entity.dart';

abstract class PromoRepository {
  Stream<Either<String, List<PromoEntity>>> getPromos();
  Future<Either<String, String>> createPromo(PromoEntity promo);
  Future<Either<String, void>> updatePromo(PromoEntity promo);
  Future<Either<String, void>> deletePromo(String id);
}
