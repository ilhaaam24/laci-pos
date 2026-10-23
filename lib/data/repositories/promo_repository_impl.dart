import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/promo_entity.dart';
import '../../domain/repositories/promo_repository.dart';
import '../datasources/firebase/promo_firebase_datasource.dart';
import '../datasources/local/local_database.dart';
import '../datasources/local/promo_local_datasource.dart';
import '../models/promo_model.dart';

class PromoRepositoryImpl implements PromoRepository {
  final PromoFirebaseDataSource remoteDataSource;
  final PromoLocalDataSource localDataSource;
  final LocalDatabase localDatabase;
  final SessionService sessionService;

  PromoRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.localDatabase,
    required this.sessionService,
  });

  String get _businessId => sessionService.businessId ?? '';

  @override
  Stream<Either<String, List<PromoEntity>>> getPromos() {
    try {
      return localDataSource
          .watchPromos(_businessId)
          .map(
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
      final promoId = promo.id.isEmpty ? const Uuid().v4() : promo.id;
      final model = PromoModel.fromEntity(
        promo,
      ).copyWith(id: promoId, businessId: _businessId);

      // 1. Save to local
      await localDataSource.upsertPromo(model, syncStatus: 'pendingUpload');

      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        businessId: _businessId,
        syncEntityName: 'promos',
        documentId: model.id,
        operation: 'create',
        data: jsonEncode(model.toJson()),
      );

      return Right(model.id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updatePromo(PromoEntity promo) async {
    try {
      final model = PromoModel.fromEntity(
        promo,
      ).copyWith(businessId: _businessId);

      // 1. Update local
      await localDataSource.upsertPromo(model, syncStatus: 'pendingUpload');

      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        businessId: _businessId,
        syncEntityName: 'promos',
        documentId: model.id,
        operation: 'update',
        data: jsonEncode(model.toJson()),
      );

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deletePromo(String id) async {
    try {
      // 1. Mark as deleted locally
      await localDataSource.markAsDeleted(id);

      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        businessId: _businessId,
        syncEntityName: 'promos',
        documentId: id,
        operation: 'delete',
      );

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
