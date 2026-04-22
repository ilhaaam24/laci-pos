import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<String, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<String, UserEntity>> signInWithGoogle();

  Future<Either<String, void>> signOut();

  Future<Either<String, UserEntity?>> getCurrentUser();

  Stream<UserEntity?> get authStateChanges;
}
