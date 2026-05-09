import '../../domain/entities/user_entity.dart';

class SessionService {
  UserEntity? _currentUser;

  void setUser(UserEntity? user) {
    _currentUser = user;
  }

  UserEntity? get currentUser => _currentUser;
  String? get businessId => _currentUser?.businessId;

  bool get isAuthenticated => _currentUser != null;
}
