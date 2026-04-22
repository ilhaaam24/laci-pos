import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/repositories/transaction_repository.dart';

// Events
abstract class TransactionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {}

class LoadTransactionsByDateRange extends TransactionEvent {
  final DateTime startDate;
  final DateTime endDate;

  LoadTransactionsByDateRange(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}

class CreateTransaction extends TransactionEvent {
  final TransactionEntity transaction;

  CreateTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

// States
abstract class TransactionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionEntity> transactions;

  TransactionLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class TransactionError extends TransactionState {
  final String message;

  TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}

class TransactionSuccess extends TransactionState {
  final String message;
  final String transactionId;

  TransactionSuccess(this.message, this.transactionId);

  @override
  List<Object?> get props => [message, transactionId];
}

// BLoC
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;

  TransactionBloc({required this.repository}) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<LoadTransactionsByDateRange>(_onLoadTransactionsByDateRange);
    on<CreateTransaction>(_onCreateTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    await emit.forEach(
      repository.getTransactions(),
      onData: (result) {
        return result.fold(
          (error) => TransactionError(error),
          (transactions) => TransactionLoaded(transactions),
        );
      },
    );
  }

  Future<void> _onLoadTransactionsByDateRange(
    LoadTransactionsByDateRange event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    await emit.forEach(
      repository.getTransactionsByDateRange(event.startDate, event.endDate),
      onData: (result) {
        return result.fold(
          (error) => TransactionError(error),
          (transactions) => TransactionLoaded(transactions),
        );
      },
    );
  }

  Future<void> _onCreateTransaction(
    CreateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    final result = await repository.createTransaction(event.transaction);

    result.fold(
      (error) => emit(TransactionError(error)),
      (id) =>
          emit(TransactionSuccess('Transaction completed successfully', id)),
    );
  }
}
