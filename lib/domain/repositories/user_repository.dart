import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<Either<String, List<UserEntity>>> getUsers();
  Future<Either<String, void>> updateUserRole(String uid, UserRole role);
  Future<Either<String, void>> addUser(
    String email,
    String password,
    UserRole role,
  );
  Future<Either<String, void>> addStaffWithPin({
    required String name,
    required UserRole role,
    required String pin,
    String? email,
  });
  Future<Either<String, void>> updateStaffPin(String uid, String newPin);
}
