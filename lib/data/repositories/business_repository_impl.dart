import 'package:dartz/dartz.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/repositories/business_repository.dart';
import '../datasources/firebase/business_firebase_datasource.dart';
import '../models/business_model.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessFirebaseDataSource dataSource;

  BusinessRepositoryImpl({required this.dataSource});

  @override
  Future<Either<String, BusinessInfo>> getBusinessInfo() async {
    try {
      final model = await dataSource.getBusinessInfo();
      return Right(
        BusinessInfo(
          id: model.id,
          businessName: model.businessName,
          address: model.address,
          phone: model.phone,
          email: model.email,
          logoUrl: model.logoUrl,
          createdAt: model.createdAt,
          updatedAt: model.updatedAt,
        ),
      );
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateBusinessInfo(
    BusinessInfo businessInfo,
  ) async {
    try {
      final model = BusinessInfoModel(
        id: businessInfo.id,
        businessName: businessInfo.businessName,
        address: businessInfo.address,
        phone: businessInfo.phone,
        email: businessInfo.email,
        logoUrl: businessInfo.logoUrl,
        createdAt: businessInfo.createdAt,
        updatedAt: businessInfo.updatedAt,
      );
      await dataSource.updateBusinessInfo(model);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
