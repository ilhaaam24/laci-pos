import 'package:dartz/dartz.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/firebase/transaction_firebase_datasource.dart';
import 'package:laci/data/models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionFirebaseDataSource dataSource;

  TransactionRepositoryImpl({required this.dataSource});

  @override
  Future<Either<String, String>> createTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      final id = await dataSource.createTransaction(model);
      return Right(id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Stream<Either<String, List<TransactionEntity>>> getTransactions() {
    try {
      return dataSource.getTransactions().map(
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
      final result = await dataSource.getTransactionById(id);
      return Right(result.toEntity());
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
      return dataSource
          .getTransactionsByDateRange(startDate, endDate)
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
