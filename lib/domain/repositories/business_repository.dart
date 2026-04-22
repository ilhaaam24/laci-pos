import 'package:dartz/dartz.dart';
import '../entities/business_entity.dart';

abstract class BusinessRepository {
  Future<Either<String, BusinessInfo>> getBusinessInfo();
  Future<Either<String, void>> updateBusinessInfo(BusinessInfo businessInfo);
}
