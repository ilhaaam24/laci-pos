import 'package:dartz/dartz.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/firebase/transaction_firebase_datasource.dart';
import '../datasources/local/transaction_local_datasource.dart';
import 'package:laci/data/models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionFirebaseDataSource remoteDataSource;
  final TransactionLocalDataSource localDataSource;
  final SessionService sessionService;

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.sessionService,
  });

  String get _businessId => sessionService.businessId ?? '';

  @override
  Future<Either<String, String>> createTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final model = TransactionModel.fromEntity(
        transaction,
      ).copyWith(businessId: _businessId);
      // Transactions are typically created via TransactionService which handles
      // stock and sync queue. This repository method can be a fallback or
      // used for direct local creation.
      final id = await localDataSource.createTransaction(
        model,
        syncStatus: 'pendingUpload',
      );
      return Right(id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Stream<Either<String, List<TransactionEntity>>> getTransactions() {
    try {
      return localDataSource
          .watchTransactions(_businessId)
          .map(
            (transactions) => Right<String, List<TransactionEntity>>(
              transactions.map((model) => model.toEntity()).toList(),
            ),
          );
    } catch (e) {
      return Stream.value(Left(e.toString()));
    }
  }

  @override
  Future<Either<String, TransactionEntity>> getTransactionById(
    String id,
  ) async {
    try {
      final result = await localDataSource.getTransactionById(id);
      if (result != null) {
        return Right(result.toEntity());
      }
      return const Left('Transaksi tidak ditemukan di lokal');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Stream<Either<String, List<TransactionEntity>>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      return localDataSource
          .watchTransactionsByDateRange(_businessId, startDate, endDate)
          .map(
            (transactions) => Right<String, List<TransactionEntity>>(
              transactions.map((model) => model.toEntity()).toList(),
            ),
          );
    } catch (e) {
      return Stream.value(Left(e.toString()));
    }
  }

  @override
  Stream<Either<String, List<TransactionEntity>>> getTransactionsByCustomerId(
    String customerId,
  ) {
    try {
      return localDataSource
          .watchTransactionsByCustomer(_businessId, customerId)
          .map(
            (transactions) => Right<String, List<TransactionEntity>>(
              transactions.map((model) => model.toEntity()).toList(),
            ),
          );
    } catch (e) {
      return Stream.value(Left(e.toString()));
    }
  }
}
