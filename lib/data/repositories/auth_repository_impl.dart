import 'dart:developer';
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
      log('FirebaseAuthException during signInWithEmail: [${e.code}] ${e.message}');
      return Left(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      log('Exception during signInWithEmail: $e');
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
      log('FirebaseAuthException during signInWithGoogle: [${e.code}] ${e.message}');
      return Left(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      log('Exception during signInWithGoogle: $e');
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
        try {
          await dataSource.sendEmailVerification();
        } catch (e) {
          log('Error sending verification email: $e');
        }
        final userEntity = await _getOrUpdateProfile(credential.user!);
        return Right(userEntity);
      } else {
        return const Left('Gagal mendaftarkan user');
      }
    } on FirebaseAuthException catch (e) {
      log('FirebaseAuthException during signUpWithEmail: [${e.code}] ${e.message}');
      return Left(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      log('Exception during signUpWithEmail: $e');
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
  Future<Either<String, void>> sendEmailVerification() async {
    try {
      await dataSource.sendEmailVerification();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> checkEmailVerified() async {
    try {
      final isVerified = await dataSource.checkEmailVerified();
      return Right(isVerified);
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
        try {
          return await _getOrUpdateProfile(user);
        } catch (e) {
          log('Error in authStateChanges asyncMap: $e');
          return UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: user.displayName,
            photoUrl: user.photoURL,
            role: UserRole.owner,
            businessId: 'bis_${user.uid}',
            isEmailVerified: user.emailVerified,
          );
        }
      }
      return null;
    });
  }

  Future<UserEntity> _getOrUpdateProfile(User firebaseUser) async {
    try {
      // 1. Cek berdasarkan UID (User yang sudah pernah login)
      final profileByUid = await userDataSource.getUserProfile(firebaseUser.uid);
      if (profileByUid != null) {
        return profileByUid.copyWith(
          isEmailVerified: firebaseUser.emailVerified,
        );
      }
    } catch (e) {
      log('Error getting user profile by UID: $e');
    }

    try {
      // 2. Cek berdasarkan Email (Staff yang didaftarkan oleh Admin tapi belum pernah login)
      if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
        final profileByEmail = await userDataSource.getUserByEmail(
          firebaseUser.email!,
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
            isEmailVerified: firebaseUser.emailVerified,
          );

          // Simpan profile baru dengan UID asli
          try {
            await userDataSource.createUserProfile(updatedUser);
            if (profileByEmail.id != updatedUser.id) {
              await userDataSource.deleteUser(profileByEmail.id);
            }
          } catch (e) {
            log('Error saving updated user by email: $e');
          }

          return updatedUser;
        }
      }
    } catch (e) {
      log('Error getting user by email: $e');
    }

    // 3. Jika benar-benar user baru, buat Bisnis Baru (Owner)
    final businessId = 'bis_${firebaseUser.uid}';

    final newUser = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      role: UserRole.owner,
      businessId: businessId,
      isEmailVerified: firebaseUser.emailVerified,
    );

    try {
      await userDataSource.createUserProfile(newUser);
    } catch (e) {
      log('Error creating user profile in Firestore: $e');
    }

    return newUser;
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
        return 'Password yang Anda masukkan salah.';
      case 'invalid-credential':
        return 'Email atau password yang Anda masukkan salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Silakan coba lagi nanti.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan gunakan menu Masuk.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      default:
        return e.message ?? 'Terjadi kesalahan saat otentikasi.';
    }
  }
}
