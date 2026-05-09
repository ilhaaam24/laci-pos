import 'package:dartz/dartz.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/firebase/user_firebase_datasource.dart';

import '../../../core/services/session_service.dart';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserFirebaseDataSource dataSource;
  final SessionService sessionService;

  UserRepositoryImpl({required this.dataSource, required this.sessionService});

  @override
  Future<Either<String, List<UserEntity>>> getUsers() async {
    try {
      final users = await dataSource.getUsers();
      return Right(users);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateUserRole(String uid, UserRole role) async {
    try {
      final user = await dataSource.getUserProfile(uid);
      if (user != null) {
        // Security check: must be in same business
        if (user.businessId != sessionService.businessId) {
          return const Left('Anda tidak memiliki izin untuk mengubah user ini');
        }

        final updatedUser = user.copyWith(role: role);
        await dataSource.updateUserProfile(updatedUser);
        return const Right(null);
      }
      return const Left('User tidak ditemukan');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> addUser(
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      final businessId = sessionService.businessId;
      if (businessId == null) return const Left('Business ID tidak ditemukan');

      // 1. Create User in Firebase Auth using a secondary app
      // This is to avoid logging out the current admin user
      final appName = 'staff_creator_${DateTime.now().millisecondsSinceEpoch}';
      final secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );

      try {
        final authInstance = auth.FirebaseAuth.instanceFor(app: secondaryApp);
        final userCredential = await authInstance
            .createUserWithEmailAndPassword(email: email, password: password);

        final uid = userCredential.user?.uid;
        if (uid == null) {
          throw Exception('Gagal mendapatkan UID untuk user baru');
        }

        // 2. Create User Profile in Firestore
        final newUser = UserModel(
          id: uid,
          email: email,
          name: null,
          photoUrl: null,
          role: role,
          businessId: businessId,
        );

        await dataSource.createUserProfile(newUser);

        // 3. Clean up secondary app
        await secondaryApp.delete();

        return const Right(null);
      } catch (e) {
        // Ensure app is deleted even on error
        await secondaryApp.delete();
        rethrow;
      }
    } catch (e) {
      return Left(e.toString());
    }
  }
}
