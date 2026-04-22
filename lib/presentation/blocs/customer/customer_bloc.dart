import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/repositories/customer_repository.dart';

// Events
abstract class CustomerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {}

class CreateCustomer extends CustomerEvent {
  final Customer customer;
  CreateCustomer(this.customer);
  @override
  List<Object?> get props => [customer];
}

class UpdateCustomer extends CustomerEvent {
  final Customer customer;
  UpdateCustomer(this.customer);
  @override
  List<Object?> get props => [customer];
}

class DeleteCustomer extends CustomerEvent {
  final String id;
  DeleteCustomer(this.id);
  @override
  List<Object?> get props => [id];
}

// States
class CustomerState extends Equatable {
  final List<Customer> customers;
  final String? message;
  final bool isLoading;
  final bool isSuccess;

  const CustomerState({
    this.customers = const [],
    this.message,
    this.isLoading = false,
    this.isSuccess = false,
  });

  CustomerState copyWith({
    List<Customer>? customers,
    String? message,
    bool? isLoading,
    bool? isSuccess,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      message: message,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [customers, message, isLoading, isSuccess];
}

class CustomerActionSuccess extends CustomerState {
  const CustomerActionSuccess(String message, List<Customer> customers)
    : super(message: message, customers: customers, isSuccess: true);
}

class CustomerError extends CustomerState {
  const CustomerError(String message, List<Customer> customers)
    : super(message: message, customers: customers, isLoading: false);
}

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository repository;

  CustomerBloc({required this.repository}) : super(const CustomerState()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<CreateCustomer>(_onCreateCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await emit.forEach(
      repository.getCustomers(),
      onData: (result) {
        return result.fold(
          (error) => CustomerError(error, state.customers),
          (customers) => CustomerState(
            customers: customers,
            isLoading: false,
            isSuccess: true,
          ),
        );
      },
    );
  }

  Future<void> _onCreateCustomer(
    CreateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    final result = await repository.createCustomer(event.customer);
    result.fold(
      (error) => emit(CustomerError(error, state.customers)),
      (_) => emit(
        CustomerActionSuccess(
          'Pelanggan berhasil ditambahkan',
          state.customers,
        ),
      ),
    );
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    final result = await repository.updateCustomer(event.customer);
    result.fold(
      (error) => emit(CustomerError(error, state.customers)),
      (_) => emit(
        CustomerActionSuccess('Pelanggan berhasil diperbarui', state.customers),
      ),
    );
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    final result = await repository.deleteCustomer(event.id);
    result.fold(
      (error) => emit(CustomerError(error, state.customers)),
      (_) => emit(
        CustomerActionSuccess('Pelanggan berhasil dihapus', state.customers),
      ),
    );
  }
}
