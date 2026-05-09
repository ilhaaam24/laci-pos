import 'dart:convert';
import 'dart:developer';
import 'package:dartz/dartz.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/repositories/business_repository.dart';
import '../datasources/firebase/business_firebase_datasource.dart';
import '../datasources/local/business_local_datasource.dart';
import '../datasources/local/local_database.dart';
import '../models/business_model.dart';
import '../../core/services/session_service.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessFirebaseDataSource remoteDataSource;
  final BusinessLocalDataSource localDataSource;
  final LocalDatabase localDatabase;
  final SessionService sessionService;

  BusinessRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.localDatabase,
    required this.sessionService,
  });

  @override
  Future<Either<String, BusinessInfo>> getBusinessInfo() async {
    try {
      final currentBusinessId = sessionService.businessId;
      log(
        'BusinessRepository: currentBusinessId from session: $currentBusinessId',
      );

      // Always try local first, but ONLY if it matches the current session businessId
      final localModel = await localDataSource.getBusinessInfo();
      log(
        'BusinessRepository: localModel: ${localModel?.id} (${localModel?.businessName})',
      );

      if (localModel != null &&
          (currentBusinessId == null || localModel.id == currentBusinessId)) {
        log('BusinessRepository: Returning local model');
        return Right<String, BusinessInfo>(localModel);
      }

      // If not in local or mismatch, try remote and cache it
      log('BusinessRepository: Fetching from remote...');
      final remoteModel = await remoteDataSource.getBusinessInfo();
      log(
        'BusinessRepository: remoteModel: ${remoteModel.id} (${remoteModel.businessName})',
      );

      await localDataSource.upsertBusinessInfo(remoteModel);
      log('BusinessRepository: Cached remote model to local');

      return Right<String, BusinessInfo>(remoteModel);
    } catch (e) {
      log('BusinessRepository: Error: $e');
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
        businessId: model.id, // Business info ID IS the businessId
        data: jsonEncode(model.toJson()),
      );

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
