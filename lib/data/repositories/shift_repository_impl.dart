import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/shift_repository.dart';
import '../datasources/local/local_database.dart';
import '../datasources/local/shift_local_datasource.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../models/shift_model.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final ShiftLocalDataSource localDataSource;
  final TransactionLocalDataSource transactionLocalDataSource;
  final LocalDatabase localDatabase;
  final SessionService sessionService;

  ShiftRepositoryImpl({
    required this.localDataSource,
    required this.transactionLocalDataSource,
    required this.localDatabase,
    required this.sessionService,
  });

  String get _businessId => sessionService.businessId ?? '';

  @override
  Future<ShiftEntity?> getActiveShift() async {
    final businessId = _businessId;
    if (businessId.isEmpty) return null;
    final model = await localDataSource.getActiveShift(businessId);
    return model?.toEntity();
  }

  @override
  Stream<ShiftEntity?> watchActiveShift() {
    final businessId = _businessId;
    if (businessId.isEmpty) return Stream.value(null);
    return localDataSource.watchActiveShift(businessId).map((m) => m?.toEntity());
  }

  @override
  Future<ShiftEntity?> getShiftById(String id) async {
    final model = await localDataSource.getShiftById(id);
    return model?.toEntity();
  }

  @override
  Future<List<ShiftEntity>> getAllShifts() async {
    final businessId = _businessId;
    if (businessId.isEmpty) return [];
    final models = await localDataSource.getAllShifts(businessId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<ShiftEntity>> watchAllShifts() {
    final businessId = _businessId;
    if (businessId.isEmpty) return Stream.value([]);
    return localDataSource
        .watchAllShifts(businessId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<ShiftEntity> openShift({
    required double startCash,
    String? notes,
  }) async {
    final businessId = _businessId;
    if (businessId.isEmpty) {
      throw Exception('Business ID tidak ditemukan. Silakan login kembali.');
    }

    // Check if there is already an active open shift
    final existing = await localDataSource.getActiveShift(businessId);
    if (existing != null) {
      return existing.toEntity();
    }

    final user = sessionService.currentUser;
    final now = DateTime.now();
    final shiftId = const Uuid().v4();

    final shiftModel = ShiftModel(
      id: shiftId,
      userId: user?.id ?? '',
      userName: user?.name?.isNotEmpty == true
          ? user!.name!
          : (user?.email ?? 'Kasir'),
      userEmail: user?.email,
      businessId: businessId,
      startTime: now,
      startCash: startCash,
      status: ShiftStatus.open,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await localDataSource.insertShift(shiftModel, syncStatus: 'pendingUpload');

    // Add to sync queue for cloud sync
    await localDatabase.addToSyncQueue(
      syncEntityName: 'shifts',
      documentId: shiftId,
      operation: 'create',
      businessId: businessId,
      data: jsonEncode(shiftModel.toJson()),
    );

    return shiftModel.toEntity();
  }

  @override
  Future<ShiftSummary> getShiftSummary(String shiftId) async {
    final shiftModel = await localDataSource.getShiftById(shiftId);
    if (shiftModel == null) {
      throw Exception('Shift dengan ID $shiftId tidak ditemukan.');
    }

    // 1. Get transactions for this shift
    List<TransactionEntity> transactions =
        await transactionLocalDataSource.getTransactionsByShift(shiftId);

    // Fallback: If no transactions have shiftId yet, also match by time interval
    if (transactions.isEmpty) {
      final endFilter = shiftModel.endTime ?? DateTime.now();
      final allTxns = await transactionLocalDataSource
          .watchTransactionsByDateRange(_businessId, shiftModel.startTime, endFilter)
          .first;
      transactions = allTxns;
    }

    double totalCashSales = 0;
    double totalQrisSales = 0;
    double totalDebitSales = 0;
    double totalTransferSales = 0;
    double totalSales = 0;

    for (final txn in transactions) {
      totalSales += txn.totalAmount;
      for (final payment in txn.payments) {
        switch (payment.type) {
          case PaymentType.cash:
            totalCashSales += payment.amount;
            break;
          case PaymentType.qris:
            totalQrisSales += payment.amount;
            break;
          case PaymentType.debit:
            totalDebitSales += payment.amount;
            break;
          case PaymentType.transfer:
            totalTransferSales += payment.amount;
            break;
        }
      }
    }

    // 2. Get cash movements
    final movements = await localDataSource.getCashMovementsByShift(shiftId);
    double totalCashIn = 0;
    double totalCashOut = 0;

    for (final m in movements) {
      if (m.type == CashMovementType.cashIn) {
        totalCashIn += m.amount;
      } else if (m.type == CashMovementType.cashOut) {
        totalCashOut += m.amount;
      }
    }

    return ShiftSummary(
      shift: shiftModel.toEntity(),
      startCash: shiftModel.startCash,
      totalCashSales: totalCashSales,
      totalQrisSales: totalQrisSales,
      totalDebitSales: totalDebitSales,
      totalTransferSales: totalTransferSales,
      totalSales: totalSales,
      totalTransactions: transactions.length,
      totalCashIn: totalCashIn,
      totalCashOut: totalCashOut,
      cashMovements: movements.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<CashMovementEntity> addCashMovement({
    required String shiftId,
    required CashMovementType type,
    required double amount,
    required String reason,
  }) async {
    final businessId = _businessId;
    final user = sessionService.currentUser;
    final now = DateTime.now();
    final movementId = const Uuid().v4();

    final movementModel = CashMovementModel(
      id: movementId,
      shiftId: shiftId,
      businessId: businessId,
      userId: user?.id ?? '',
      userName: user?.name?.isNotEmpty == true
          ? user!.name!
          : (user?.email ?? 'Kasir'),
      type: type,
      amount: amount,
      reason: reason,
      createdAt: now,
    );

    await localDataSource.insertCashMovement(
      movementModel,
      syncStatus: 'pendingUpload',
    );

    // Add to sync queue
    await localDatabase.addToSyncQueue(
      syncEntityName: 'cash_movements',
      documentId: movementId,
      operation: 'create',
      businessId: businessId,
      data: jsonEncode(movementModel.toJson()),
    );

    return movementModel.toEntity();
  }

  @override
  Future<ShiftEntity> closeShift({
    required String shiftId,
    required double actualCash,
    String? notes,
  }) async {
    final summary = await getShiftSummary(shiftId);
    final expectedCash = summary.expectedCashInDrawer;
    final difference = summary.calculateDifference(actualCash);
    final now = DateTime.now();

    final shiftModel = ShiftModel.fromEntity(summary.shift).copyWith(
      endTime: now,
      endCashExpected: expectedCash,
      endCashActual: actualCash,
      cashDifference: difference,
      totalCashSales: summary.totalCashSales,
      totalNonCashSales:
          summary.totalQrisSales + summary.totalDebitSales + summary.totalTransferSales,
      totalSales: summary.totalSales,
      totalTransactions: summary.totalTransactions,
      status: ShiftStatus.closed,
      notes: notes ?? summary.shift.notes,
      updatedAt: now,
    );

    await localDataSource.updateShift(shiftModel, syncStatus: 'pendingUpload');

    // Add update to sync queue
    await localDatabase.addToSyncQueue(
      syncEntityName: 'shifts',
      documentId: shiftId,
      operation: 'update',
      businessId: _businessId,
      data: jsonEncode(shiftModel.toJson()),
    );

    return shiftModel.toEntity();
  }

  @override
  Future<List<CashMovementEntity>> getCashMovements(String shiftId) async {
    final models = await localDataSource.getCashMovementsByShift(shiftId);
    return models.map((m) => m.toEntity()).toList();
  }
}
