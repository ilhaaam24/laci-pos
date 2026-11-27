import 'package:sentry_flutter/sentry_flutter.dart';
import '../../domain/entities/user_entity.dart';
import 'analytics_service.dart';

class SessionService {
  static const String demoUserId = 'demo_user';
  static const String demoBusinessId = 'demo_business';

  UserEntity? _storeUser;
  UserEntity? _activeStaff;

  void setUser(UserEntity? user) {
    _storeUser = user;
    if (user == null) {
      _activeStaff = null;
    } else {
      // If no specific staff is selected, default to the authenticated store user
      _activeStaff ??= user;
    }
    _syncSentryUser(user);
    AnalyticsService.setUser(
      userId: user?.id,
      role: user?.role.name,
      businessId: user?.businessId,
      isDemo: isDemoMode,
    );
  }

  void setActiveStaff(UserEntity? staff) {
    _activeStaff = staff;
    if (Sentry.isEnabled) {
      try {
        Sentry.configureScope((scope) {
          if (staff != null) {
            scope.setTag('active_staff_role', staff.role.name);
          } else {
            scope.removeTag('active_staff_role');
          }
        });
      } catch (_) {}
    }
  }

  void _syncSentryUser(UserEntity? user) {
    if (!Sentry.isEnabled) return;
    try {
      Sentry.configureScope((scope) {
        if (user == null) {
          scope.setUser(null);
          scope.removeTag('business_id');
          scope.removeTag('user_role');
        } else {
          scope.setUser(
            SentryUser(
              id: user.id,
              email: user.email,
              data: {
                if (user.businessId != null) 'businessId': user.businessId,
                'role': user.role.name,
              },
            ),
          );
          if (user.businessId != null && user.businessId!.isNotEmpty) {
            scope.setTag('business_id', user.businessId!);
          }
          scope.setTag('user_role', user.role.name);
        }
      });
    } catch (_) {}
  }

  UserEntity? get storeUser => _storeUser;
  UserEntity? get activeStaff => _activeStaff;

  /// Returns the current active staff on duty, or falls back to the store user.
  UserEntity? get currentUser => _activeStaff ?? _storeUser;

  String? get businessId => _storeUser?.businessId ?? _activeStaff?.businessId;

  bool get isAuthenticated => _storeUser != null;

  bool get isDemoMode => _storeUser?.id == demoUserId;
}
