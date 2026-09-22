import 'package:drift/drift.dart';
import 'package:laci/domain/entities/shift_entity.dart';
import 'package:laci/data/models/shift_model.dart';
import 'local_database.dart';

class ShiftLocalDataSource {
  final LocalDatabase _db;

  ShiftLocalDataSource(this._db);

  /// Get the currently open shift for a business
  Future<ShiftModel?> getActiveShift(String businessId) async {
    final query = _db.select(_db.localShifts)
      ..where((s) => s.businessId.equals(businessId) & s.status.equals('open'))
      ..orderBy([(s) => OrderingTerm.desc(s.startTime)])
      ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _shiftRowToModel(row);
  }

  /// Watch the currently open shift
  Stream<ShiftModel?> watchActiveShift(String businessId) {
    final query = _db.select(_db.localShifts)
      ..where((s) => s.businessId.equals(businessId) & s.status.equals('open'))
      ..orderBy([(s) => OrderingTerm.desc(s.startTime)])
      ..limit(1);

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      return _shiftRowToModel(row);
    });
  }

  /// Get a single shift by ID
  Future<ShiftModel?> getShiftById(String id) async {
    final query = _db.select(_db.localShifts)..where((s) => s.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _shiftRowToModel(row);
  }

  /// Get all past shifts for a business
  Future<List<ShiftModel>> getAllShifts(String businessId) async {
    final query = _db.select(_db.localShifts)
      ..where((s) => s.businessId.equals(businessId))
      ..orderBy([(s) => OrderingTerm.desc(s.startTime)]);

    final rows = await query.get();
    return rows.map(_shiftRowToModel).toList();
  }

  /// Watch all shifts for a business
  Stream<List<ShiftModel>> watchAllShifts(String businessId) {
    final query = _db.select(_db.localShifts)
      ..where((s) => s.businessId.equals(businessId))
      ..orderBy([(s) => OrderingTerm.desc(s.startTime)]);

    return query.watch().map((rows) => rows.map(_shiftRowToModel).toList());
  }

  /// Insert a new shift
  Future<void> insertShift(
    ShiftModel shift, {
    String syncStatus = 'pendingUpload',
  }) async {
    await _db.into(_db.localShifts).insert(
          LocalShiftsCompanion.insert(
            id: shift.id,
            userId: shift.userId,
            userName: shift.userName,
            userEmail: Value(shift.userEmail),
            businessId: Value(shift.businessId),
            startTime: shift.startTime,
            endTime: Value(shift.endTime),
            startCash: shift.startCash,
            endCashExpected: Value(shift.endCashExpected),
            endCashActual: Value(shift.endCashActual),
            cashDifference: Value(shift.cashDifference),
            totalCashSales: Value(shift.totalCashSales),
            totalNonCashSales: Value(shift.totalNonCashSales),
            totalSales: Value(shift.totalSales),
            totalTransactions: Value(shift.totalTransactions),
            status: Value(shift.status.name),
            notes: Value(shift.notes),
            createdAt: shift.createdAt,
            updatedAt: shift.updatedAt,
            syncStatus: Value(syncStatus),
            lastSyncAt: Value(syncStatus == 'synced' ? DateTime.now() : null),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// Update an existing shift
  Future<void> updateShift(
    ShiftModel shift, {
    String syncStatus = 'pendingUpload',
  }) async {
    await (_db.update(_db.localShifts)..where((s) => s.id.equals(shift.id))).write(
      LocalShiftsCompanion(
        endTime: Value(shift.endTime),
        endCashExpected: Value(shift.endCashExpected),
        endCashActual: Value(shift.endCashActual),
        cashDifference: Value(shift.cashDifference),
        totalCashSales: Value(shift.totalCashSales),
        totalNonCashSales: Value(shift.totalNonCashSales),
        totalSales: Value(shift.totalSales),
        totalTransactions: Value(shift.totalTransactions),
        status: Value(shift.status.name),
        notes: Value(shift.notes),
        updatedAt: Value(DateTime.now()),
        syncStatus: Value(syncStatus),
        lastSyncAt: Value(syncStatus == 'synced' ? DateTime.now() : null),
      ),
    );
  }

  /// Insert a cash movement (Kas Masuk / Kas Keluar)
  Future<void> insertCashMovement(
    CashMovementModel movement, {
    String syncStatus = 'pendingUpload',
  }) async {
    await _db.into(_db.localCashMovements).insert(
          LocalCashMovementsCompanion.insert(
            id: movement.id,
            shiftId: movement.shiftId,
            businessId: Value(movement.businessId),
            userId: movement.userId,
            userName: movement.userName,
            type: movement.type.name,
            amount: movement.amount,
            reason: movement.reason,
            createdAt: movement.createdAt,
            syncStatus: Value(syncStatus),
            lastSyncAt: Value(syncStatus == 'synced' ? DateTime.now() : null),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// Get all cash movements for a specific shift
  Future<List<CashMovementModel>> getCashMovementsByShift(String shiftId) async {
    final query = _db.select(_db.localCashMovements)
      ..where((m) => m.shiftId.equals(shiftId))
      ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]);

    final rows = await query.get();
    return rows.map(_cashMovementRowToModel).toList();
  }

  /// Watch all cash movements for a specific shift
  Stream<List<CashMovementModel>> watchCashMovementsByShift(String shiftId) {
    final query = _db.select(_db.localCashMovements)
      ..where((m) => m.shiftId.equals(shiftId))
      ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]);

    return query.watch().map((rows) => rows.map(_cashMovementRowToModel).toList());
  }

  ShiftModel _shiftRowToModel(LocalShift row) {
    return ShiftModel(
      id: row.id,
      userId: row.userId,
      userName: row.userName,
      userEmail: row.userEmail,
      businessId: row.businessId,
      startTime: row.startTime,
      endTime: row.endTime,
      startCash: row.startCash,
      endCashExpected: row.endCashExpected,
      endCashActual: row.endCashActual,
      cashDifference: row.cashDifference,
      totalCashSales: row.totalCashSales,
      totalNonCashSales: row.totalNonCashSales,
      totalSales: row.totalSales,
      totalTransactions: row.totalTransactions,
      status: ShiftStatus.fromString(row.status),
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  CashMovementModel _cashMovementRowToModel(LocalCashMovement row) {
    return CashMovementModel(
      id: row.id,
      shiftId: row.shiftId,
      businessId: row.businessId,
      userId: row.userId,
      userName: row.userName,
      type: CashMovementType.fromString(row.type),
      amount: row.amount,
      reason: row.reason,
      createdAt: row.createdAt,
    );
  }
}
