import '../../domain/entities/shift_entity.dart';

abstract class ShiftRepository {
  /// Get the current open shift for the authenticated business
  Future<ShiftEntity?> getActiveShift();

  /// Watch current open shift in real time
  Stream<ShiftEntity?> watchActiveShift();

  /// Get shift by ID
  Future<ShiftEntity?> getShiftById(String id);

  /// Get all past and active shifts
  Future<List<ShiftEntity>> getAllShifts();

  /// Watch all shifts in real time
  Stream<List<ShiftEntity>> watchAllShifts();

  /// Open a new shift with starting cash
  Future<ShiftEntity> openShift({
    required double startCash,
    String? notes,
  });

  /// Calculate live summary for a shift
  Future<ShiftSummary> getShiftSummary(String shiftId);

  /// Record cash movement (Kas Masuk / Kas Keluar)
  Future<CashMovementEntity> addCashMovement({
    required String shiftId,
    required CashMovementType type,
    required double amount,
    required String reason,
  });

  /// Close an active shift with counted actual cash
  Future<ShiftEntity> closeShift({
    required String shiftId,
    required double actualCash,
    String? notes,
  });

  /// Get cash movements for a shift
  Future<List<CashMovementEntity>> getCashMovements(String shiftId);
}
