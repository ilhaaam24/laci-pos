import 'package:dartz/dartz.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<String, String>> createTransaction(
    TransactionEntity transaction,
  );
  Stream<Either<String, List<TransactionEntity>>> getTransactions();
  Future<Either<String, TransactionEntity>> getTransactionById(String id);
  Stream<Either<String, List<TransactionEntity>>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
}
