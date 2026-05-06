import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/firebase/customer_firebase_datasource.dart';
import '../datasources/local/customer_local_datasource.dart';
import '../datasources/local/local_database.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerFirebaseDataSource remoteDataSource;
  final CustomerLocalDataSource localDataSource;
  final LocalDatabase localDatabase;
  final SessionService sessionService;

  CustomerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.localDatabase,
    required this.sessionService,
  });

  String get _businessId => sessionService.businessId ?? '';

  @override
  Stream<Either<String, List<Customer>>> getCustomers() {
    try {
      return localDataSource
          .watchCustomers(_businessId)
          .map((models) => Right<String, List<Customer>>(models));
    } catch (e) {
      return Stream.value(Left(e.toString()));
    }
  }

  @override
  Future<Either<String, Customer>> getCustomerById(String id) async {
    try {
      final model = await localDataSource.getCustomerById(id);
      if (model != null) {
        return Right(model);
      }
      return const Left('Customer tidak ditemukan di lokal');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, String>> createCustomer(Customer customer) async {
    try {
      final customerId = customer.id.isEmpty ? const Uuid().v4() : customer.id;
      final model = CustomerModel.fromEntity(
        customer,
      ).copyWith(id: customerId, businessId: _businessId);

      // 1. Save to local
      await localDataSource.upsertCustomer(model, syncStatus: 'pendingUpload');

      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        syncEntityName: 'customers',
        documentId: model.id,
        operation: 'create',
      );

      return Right(model.id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateCustomer(Customer customer) async {
    try {
      final model = CustomerModel.fromEntity(customer);

      // 1. Update local
      await localDataSource.upsertCustomer(model, syncStatus: 'pendingUpload');

      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        syncEntityName: 'customers',
        documentId: model.id,
        operation: 'update',
      );

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteCustomer(String id) async {
    try {
      // 1. Mark as deleted locally
      await localDataSource.markAsDeleted(id);

      // 2. Add to sync queue
      await localDatabase.addToSyncQueue(
        syncEntityName: 'customers',
        documentId: id,
        operation: 'delete',
      );

      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
