import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../datasources/firebase/auth_firebase_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthFirebaseDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<Either<String, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await dataSource.signInWithEmail(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        return Right(_mapFirebaseUserToEntity(credential.user!));
      } else {
        return const Left('User tidak ditemukan');
      }
    } on FirebaseAuthException catch (e) {
      return Left(e.message ?? 'Terjadi kesalahan saat login');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> signInWithGoogle() async {
    try {
      final credential = await dataSource.signInWithGoogle();
      if (credential.user != null) {
        return Right(_mapFirebaseUserToEntity(credential.user!));
      } else {
        return const Left('Gagal login dengan Google');
      }
    } on FirebaseAuthException catch (e) {
      return Left(e.message ?? 'Terjadi kesalahan saat login Google');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> signOut() async {
    try {
      await dataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity?>> getCurrentUser() async {
    try {
      final user = dataSource.getCurrentUser();
      if (user != null) {
        return Right(_mapFirebaseUserToEntity(user));
      }
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return dataSource.authStateChanges.map((user) {
      if (user != null) {
        return _mapFirebaseUserToEntity(user);
      }
      return null;
    });
  }

  UserEntity _mapFirebaseUserToEntity(User user) {
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
