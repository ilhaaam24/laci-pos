import 'package:dartz/dartz.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/repositories/business_repository.dart';
import '../datasources/firebase/business_firebase_datasource.dart';
import '../datasources/local/business_local_datasource.dart';
import '../datasources/local/local_database.dart';
import '../models/business_model.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessFirebaseDataSource remoteDataSource;
  final BusinessLocalDataSource localDataSource;
  final LocalDatabase localDatabase;

  BusinessRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.localDatabase,
  });

  @override
  Future<Either<String, BusinessInfo>> getBusinessInfo() async {
    try {
      // Always try local first
      final localModel = await localDataSource.getBusinessInfo();
      if (localModel != null) {
        return Right<String, BusinessInfo>(localModel);
      }

      // If not in local, try remote and cache it
      final remoteModel = await remoteDataSource.getBusinessInfo();
      await localDataSource.upsertBusinessInfo(remoteModel);
      return Right<String, BusinessInfo>(remoteModel);
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
        qrisUrl: businessInfo.qrisUrl,
        createdAt: businessInfo.createdAt,
        updatedAt: businessInfo.updatedAt,
      );
      
      // 1. Update local
      await localDataSource.upsertBusinessInfo(model);
      
      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        syncEntityName: 'business_info',
        documentId: model.id,
        operation: 'update',
      );
      
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
