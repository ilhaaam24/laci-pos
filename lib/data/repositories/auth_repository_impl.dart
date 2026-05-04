import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../datasources/firebase/auth_firebase_datasource.dart';
import '../datasources/firebase/user_firebase_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthFirebaseDataSource dataSource;
  final UserFirebaseDataSource userDataSource;

  AuthRepositoryImpl({required this.dataSource, required this.userDataSource});

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
        final userEntity = await _getOrUpdateProfile(credential.user!);
        return Right(userEntity);
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
        final userEntity = await _getOrUpdateProfile(credential.user!);
        return Right(userEntity);
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
  Future<Either<String, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await dataSource.signUpWithEmail(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        final userEntity = await _getOrUpdateProfile(credential.user!);
        return Right(userEntity);
      } else {
        return const Left('Gagal mendaftarkan user');
      }
    } on FirebaseAuthException catch (e) {
      return Left(e.message ?? 'Terjadi kesalahan saat pendaftaran');
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
        final userEntity = await _getOrUpdateProfile(user);
        return Right(userEntity);
      }
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return dataSource.authStateChanges.asyncMap((user) async {
      if (user != null) {
        return await _getOrUpdateProfile(user);
      }
      return null;
    });
  }

  Future<UserEntity> _getOrUpdateProfile(User firebaseUser) async {
    // 1. Cek berdasarkan UID (User yang sudah pernah login)
    final profileByUid = await userDataSource.getUserProfile(firebaseUser.uid);
    if (profileByUid != null) {
      return profileByUid;
    }

    // 2. Cek berdasarkan Email (Staff yang didaftarkan oleh Admin tapi belum pernah login)
    final profileByEmail = await userDataSource.getUserByEmail(
      firebaseUser.email ?? '',
    );

    if (profileByEmail != null) {
      // Jika ditemukan berdasarkan email, update UID-nya dengan UID asli dari Firebase Auth
      final updatedUser = UserModel(
        id: firebaseUser.uid, // Gunakan UID baru
        email: profileByEmail.email,
        name: firebaseUser.displayName ?? profileByEmail.name,
        photoUrl: firebaseUser.photoURL ?? profileByEmail.photoUrl,
        role: profileByEmail.role,
        businessId: profileByEmail.businessId,
      );

      // Simpan profile baru dengan UID asli
      await userDataSource.createUserProfile(updatedUser);

      // Hapus dokumen lama (undangan) agar tidak duplikat
      if (profileByEmail.id != updatedUser.id) {
        await userDataSource.deleteUser(profileByEmail.id);
      }

      return updatedUser;
    }

    // 3. Jika benar-benar user baru, buat Bisnis Baru (Owner)
    final businessId = 'bis_${firebaseUser.uid}';

    final newUser = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      role: UserRole.admin,
      businessId: businessId,
    );

    await userDataSource.createUserProfile(newUser);
    return newUser;
  }
}
