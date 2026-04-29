import 'package:dartz/dartz.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/firebase/user_firebase_datasource.dart';

import '../../../core/services/session_service.dart';

import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserFirebaseDataSource dataSource;
  final SessionService sessionService;

  UserRepositoryImpl({
    required this.dataSource,
    required this.sessionService,
  });

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
  Future<Either<String, void>> addUser(String email, UserRole role) async {
    try {
      final businessId = sessionService.businessId;
      if (businessId == null) return const Left('Business ID tidak ditemukan');

      // Create a placeholder user with email as ID initially
      // Or just a random ID. Let's use a random ID.
      final newUser = UserModel(
        id: 'invited_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: null,
        photoUrl: null,
        role: role,
        businessId: businessId,
      );

      await dataSource.createUserProfile(newUser);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
