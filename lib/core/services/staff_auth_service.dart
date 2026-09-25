import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import 'session_service.dart';

class StaffAuthService {
  final SessionService _sessionService;
  final SharedPreferences? _prefs;

  UserEntity? _activeStaff;
  final ValueNotifier<UserEntity?> activeStaffNotifier = ValueNotifier<UserEntity?>(null);
  final ValueNotifier<bool> isLockedNotifier = ValueNotifier<bool>(false);

  static const String _prefKeyStaffPrefix = 'cached_staff_list_';
  static const String _prefKeyActiveStaff = 'active_staff_session';

  StaffAuthService({
    required SessionService sessionService,
    SharedPreferences? prefs,
  })  : _sessionService = sessionService,
        _prefs = prefs;

  UserEntity? get activeStaff => _activeStaff;
  UserEntity? get effectiveUser => _activeStaff ?? _sessionService.storeUser;
  bool get hasActiveStaff => _activeStaff != null;
  bool get isLocked => isLockedNotifier.value;

  /// Initialize service and restore active staff if present in SharedPreferences
  Future<void> init() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final activeJson = prefs.getString(_prefKeyActiveStaff);
      if (activeJson != null && activeJson.isNotEmpty) {
        final decoded = jsonDecode(activeJson) as Map<String, dynamic>;
        final staff = UserModel.fromJson(decoded);
        _activeStaff = staff;
        activeStaffNotifier.value = staff;
        _sessionService.setActiveStaff(staff);
      }
    } catch (e) {
      debugPrint('StaffAuthService init error: $e');
    }
  }

  /// Caches staff list locally in SharedPreferences for 100% offline PIN authentication.
  Future<void> cacheStaffList(List<UserEntity> staffList, {String? businessId}) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final bId = businessId ?? _sessionService.businessId ?? 'default';
      final encodedList = staffList
          .map((u) => UserModel.fromEntity(u).toJson())
          .toList();
      await prefs.setString('$_prefKeyStaffPrefix$bId', jsonEncode(encodedList));
    } catch (e) {
      debugPrint('Error caching staff list: $e');
    }
  }

  /// Retrieves cached staff list for the current business.
  Future<List<UserEntity>> getCachedStaffList({String? businessId}) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final bId = businessId ?? _sessionService.businessId ?? 'default';
      final raw = prefs.getString('$_prefKeyStaffPrefix$bId');
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error reading cached staff list: $e');
      return [];
    }
  }

  /// Verifies a 4-digit PIN against the staff directory.
  /// If [targetStaffId] is provided, verifies that specific user's PIN.
  /// Otherwise, searches any active staff with that PIN.
  Future<UserEntity?> verifyPin(String pin, {String? targetStaffId}) async {
    final staffList = await getCachedStaffList();
    if (staffList.isEmpty) {
      // Fallback: check session currentUser if cached list is not ready yet
      final curr = _sessionService.currentUser;
      if (curr != null && curr.pin == pin) {
        return curr;
      }
      return null;
    }

    if (targetStaffId != null) {
      try {
        final target = staffList.firstWhere((s) => s.id == targetStaffId);
        if (target.pin == pin) return target;
      } catch (_) {
        return null;
      }
      return null;
    }

    for (final staff in staffList) {
      if (staff.pin != null && staff.pin == pin) {
        return staff;
      }
    }
    return null;
  }

  /// Verifies if the entered PIN belongs to a supervisor (Manager, Admin, or Owner).
  Future<UserEntity?> verifySupervisorPin(String pin) async {
    final staffList = await getCachedStaffList();
    final supervisors = staffList.where(
      (s) => s.role.isManager || s.role.isAdmin || s.role.isOwner,
    );

    for (final sup in supervisors) {
      if (sup.pin != null && sup.pin == pin) {
        return sup;
      }
    }

    // Also check current store owner in session service
    final storeUser = _sessionService.storeUser;
    if (storeUser != null && storeUser.pin == pin) {
      return storeUser;
    }

    return null;
  }

  /// Unlocks screen and sets the current active staff on duty.
  Future<void> unlockScreen(UserEntity staff) async {
    _activeStaff = staff;
    activeStaffNotifier.value = staff;
    isLockedNotifier.value = false;
    _sessionService.setActiveStaff(staff);

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKeyActiveStaff,
        jsonEncode(UserModel.fromEntity(staff).toJson()),
      );
    } catch (_) {}
  }

  /// Locks screen so that a PIN is required before accessing POS functions.
  void lockScreen() {
    isLockedNotifier.value = true;
  }

  /// Clears active staff session and returns to locked state.
  Future<void> clearSession() async {
    _activeStaff = null;
    activeStaffNotifier.value = null;
    isLockedNotifier.value = true;
    _sessionService.setActiveStaff(null);

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyActiveStaff);
    } catch (_) {}
  }
}
