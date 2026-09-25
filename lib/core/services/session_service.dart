import '../../domain/entities/user_entity.dart';

class SessionService {
  UserEntity? _storeUser;
  UserEntity? _activeStaff;

  void setUser(UserEntity? user) {
    _storeUser = user;
    // If no specific staff is selected, default to the authenticated store user
    _activeStaff ??= user;
  }

  void setActiveStaff(UserEntity? staff) {
    _activeStaff = staff;
  }

  UserEntity? get storeUser => _storeUser;
  UserEntity? get activeStaff => _activeStaff;

  /// Returns the current active staff on duty, or falls back to the store user.
  UserEntity? get currentUser => _activeStaff ?? _storeUser;

  String? get businessId => _storeUser?.businessId ?? _activeStaff?.businessId;

  bool get isAuthenticated => _storeUser != null;
}
