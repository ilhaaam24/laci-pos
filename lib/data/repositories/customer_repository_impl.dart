import 'package:dartz/dartz.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/firebase/customer_firebase_datasource.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerFirebaseDataSource dataSource;

  CustomerRepositoryImpl({required this.dataSource});

  @override
  Stream<Either<String, List<Customer>>> getCustomers() {
    try {
      return dataSource.getCustomers().map(
        (models) => Right<String, List<Customer>>(
          models
              .map(
                (model) => Customer(
                  id: model.id,
                  name: model.name,
                  phone: model.phone,
                  address: model.address,
                  createdAt: model.createdAt,
                  updatedAt: model.updatedAt,
                ),
              )
              .toList(),
        ),
      );
    } catch (e) {
      return Stream.value(Left(e.toString()));
    }
  }

  @override
  Future<Either<String, Customer>> getCustomerById(String id) async {
    try {
      final model = await dataSource.getCustomerById(id);
      return Right(
        Customer(
          id: model.id,
          name: model.name,
          phone: model.phone,
          address: model.address,
          createdAt: model.createdAt,
          updatedAt: model.updatedAt,
        ),
      );
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, String>> createCustomer(Customer customer) async {
    try {
      final model = CustomerModel(
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        address: customer.address,
        createdAt: customer.createdAt,
        updatedAt: customer.updatedAt,
      );
      final id = await dataSource.createCustomer(model);
      return Right(id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateCustomer(Customer customer) async {
    try {
      final model = CustomerModel(
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        address: customer.address,
        createdAt: customer.createdAt,
        updatedAt: customer.updatedAt,
      );
      await dataSource.updateCustomer(model);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteCustomer(String id) async {
    try {
      await dataSource.deleteCustomer(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
