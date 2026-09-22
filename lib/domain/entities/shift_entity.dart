import 'package:equatable/equatable.dart';

enum ShiftStatus {
  open,
  closed;

  static ShiftStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'closed':
        return ShiftStatus.closed;
      case 'open':
      default:
        return ShiftStatus.open;
    }
  }

  String get name => toString().split('.').last;
}

enum CashMovementType {
  cashIn,
  cashOut;

  static CashMovementType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'cashout':
      case 'cash_out':
        return CashMovementType.cashOut;
      case 'cashin':
      case 'cash_in':
      default:
        return CashMovementType.cashIn;
    }
  }

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case CashMovementType.cashIn:
        return 'Kas Masuk';
      case CashMovementType.cashOut:
        return 'Kas Keluar';
    }
  }
}

class CashMovementEntity extends Equatable {
  final String id;
  final String shiftId;
  final String? businessId;
  final String userId;
  final String userName;
  final CashMovementType type;
  final double amount;
  final String reason;
  final DateTime createdAt;

  const CashMovementEntity({
    required this.id,
    required this.shiftId,
    this.businessId,
    required this.userId,
    required this.userName,
    required this.type,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        shiftId,
        businessId,
        userId,
        userName,
        type,
        amount,
        reason,
        createdAt,
      ];
}

class ShiftEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userEmail;
  final String? businessId;
  final DateTime startTime;
  final DateTime? endTime;
  final double startCash;
  final double? endCashExpected;
  final double? endCashActual;
  final double? cashDifference;
  final double totalCashSales;
  final double totalNonCashSales;
  final double totalSales;
  final int totalTransactions;
  final ShiftStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShiftEntity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail,
    this.businessId,
    required this.startTime,
    this.endTime,
    required this.startCash,
    this.endCashExpected,
    this.endCashActual,
    this.cashDifference,
    this.totalCashSales = 0,
    this.totalNonCashSales = 0,
    this.totalSales = 0,
    this.totalTransactions = 0,
    this.status = ShiftStatus.open,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => status == ShiftStatus.open;
  bool get isClosed => status == ShiftStatus.closed;

  ShiftEntity copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? businessId,
    DateTime? startTime,
    DateTime? endTime,
    double? startCash,
    double? endCashExpected,
    double? endCashActual,
    double? cashDifference,
    double? totalCashSales,
    double? totalNonCashSales,
    double? totalSales,
    int? totalTransactions,
    ShiftStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShiftEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      businessId: businessId ?? this.businessId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startCash: startCash ?? this.startCash,
      endCashExpected: endCashExpected ?? this.endCashExpected,
      endCashActual: endCashActual ?? this.endCashActual,
      cashDifference: cashDifference ?? this.cashDifference,
      totalCashSales: totalCashSales ?? this.totalCashSales,
      totalNonCashSales: totalNonCashSales ?? this.totalNonCashSales,
      totalSales: totalSales ?? this.totalSales,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userEmail,
        businessId,
        startTime,
        endTime,
        startCash,
        endCashExpected,
        endCashActual,
        cashDifference,
        totalCashSales,
        totalNonCashSales,
        totalSales,
        totalTransactions,
        status,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Detailed live metrics summary for a shift
class ShiftSummary extends Equatable {
  final ShiftEntity shift;
  final double startCash;
  final double totalCashSales;
  final double totalQrisSales;
  final double totalDebitSales;
  final double totalTransferSales;
  final double totalSales;
  final int totalTransactions;
  final double totalCashIn;
  final double totalCashOut;
  final List<CashMovementEntity> cashMovements;

  const ShiftSummary({
    required this.shift,
    required this.startCash,
    required this.totalCashSales,
    required this.totalQrisSales,
    required this.totalDebitSales,
    required this.totalTransferSales,
    required this.totalSales,
    required this.totalTransactions,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.cashMovements,
  });

  /// Expected cash currently in the drawer:
  /// Modal Awal + Penjualan Tunai + Kas Masuk - Kas Keluar
  double get expectedCashInDrawer =>
      startCash + totalCashSales + totalCashIn - totalCashOut;

  /// Calculate difference if actual cash is provided
  double calculateDifference(double actualCash) =>
      actualCash - expectedCashInDrawer;

  @override
  List<Object?> get props => [
        shift,
        startCash,
        totalCashSales,
        totalQrisSales,
        totalDebitSales,
        totalTransferSales,
        totalSales,
        totalTransactions,
        totalCashIn,
        totalCashOut,
        cashMovements,
      ];
}
