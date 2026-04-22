import 'package:dartz/dartz.dart';
import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Stream<Either<String, List<Customer>>> getCustomers();
  Future<Either<String, Customer>> getCustomerById(String id);
  Future<Either<String, String>> createCustomer(Customer customer);
  Future<Either<String, void>> updateCustomer(Customer customer);
  Future<Either<String, void>> deleteCustomer(String id);
}
