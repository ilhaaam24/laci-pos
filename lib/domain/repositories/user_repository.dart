import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<Either<String, List<UserEntity>>> getUsers();
  Future<Either<String, void>> updateUserRole(String uid, UserRole role);
  Future<Either<String, void>> addUser(String email, UserRole role);
}
