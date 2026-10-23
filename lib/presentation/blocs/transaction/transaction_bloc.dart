import 'dart:async';
import 'package:dartz/dartz.dart';
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

class ResetTransactions extends TransactionEvent {}

class _TransactionsUpdated extends TransactionEvent {
  final Either<String, List<TransactionEntity>> result;
  _TransactionsUpdated(this.result);
  @override
  List<Object?> get props => [result];
}

class LoadTransactionsByDateRange extends TransactionEvent {
  final DateTime startDate;
  final DateTime endDate;

  LoadTransactionsByDateRange(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}

class LoadTransactionsByCustomerId extends TransactionEvent {
  final String customerId;

  LoadTransactionsByCustomerId(this.customerId);

  @override
  List<Object?> get props => [customerId];
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
  StreamSubscription<Either<String, List<TransactionEntity>>>? _transactionsSubscription;

  TransactionBloc({required this.repository}) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<_TransactionsUpdated>(_onTransactionsUpdated);
    on<ResetTransactions>(_onResetTransactions);
    on<LoadTransactionsByDateRange>(_onLoadTransactionsByDateRange);
    on<LoadTransactionsByCustomerId>(_onLoadTransactionsByCustomerId);
    on<CreateTransaction>(_onCreateTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    await _transactionsSubscription?.cancel();
    _transactionsSubscription = repository.getTransactions().listen((result) {
      add(_TransactionsUpdated(result));
    });
  }

  void _onTransactionsUpdated(
    _TransactionsUpdated event,
    Emitter<TransactionState> emit,
  ) {
    event.result.fold(
      (error) => emit(TransactionError(error)),
      (transactions) => emit(TransactionLoaded(transactions)),
    );
  }

  Future<void> _onResetTransactions(
    ResetTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    await _transactionsSubscription?.cancel();
    _transactionsSubscription = null;
    emit(TransactionInitial());
  }

  Future<void> _onLoadTransactionsByDateRange(
    LoadTransactionsByDateRange event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    await _transactionsSubscription?.cancel();
    _transactionsSubscription = repository
        .getTransactionsByDateRange(event.startDate, event.endDate)
        .listen((result) {
      add(_TransactionsUpdated(result));
    });
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

  Future<void> _onLoadTransactionsByCustomerId(
    LoadTransactionsByCustomerId event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    await _transactionsSubscription?.cancel();
    _transactionsSubscription = repository
        .getTransactionsByCustomerId(event.customerId)
        .listen((result) {
      add(_TransactionsUpdated(result));
    });
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}
