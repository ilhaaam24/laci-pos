import 'package:cloud_firestore/cloud_firestore.dart' as f_store;
import '../../domain/entities/shift_entity.dart';

class CashMovementModel extends CashMovementEntity {
  const CashMovementModel({
    required super.id,
    required super.shiftId,
    super.businessId,
    required super.userId,
    required super.userName,
    required super.type,
    required super.amount,
    required super.reason,
    required super.createdAt,
  });

  factory CashMovementModel.fromEntity(CashMovementEntity entity) {
    return CashMovementModel(
      id: entity.id,
      shiftId: entity.shiftId,
      businessId: entity.businessId,
      userId: entity.userId,
      userName: entity.userName,
      type: entity.type,
      amount: entity.amount,
      reason: entity.reason,
      createdAt: entity.createdAt,
    );
  }

  factory CashMovementModel.fromFirestore(
    f_store.DocumentSnapshot doc,
  ) {
    final map = doc.data() as Map<String, dynamic>;
    return CashMovementModel.fromMap(map, doc.id);
  }

  factory CashMovementModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is f_store.Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CashMovementModel(
      id: id,
      shiftId: map['shiftId'] ?? '',
      businessId: map['businessId'],
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      type: CashMovementType.fromString(map['type']),
      amount: (map['amount'] ?? 0).toDouble(),
      reason: map['reason'] ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory CashMovementModel.fromJson(Map<String, dynamic> json) {
    return CashMovementModel(
      id: json['id'] ?? '',
      shiftId: json['shiftId'] ?? '',
      businessId: json['businessId'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      type: CashMovementType.fromString(json['type']),
      amount: (json['amount'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shiftId': shiftId,
      'businessId': businessId,
      'userId': userId,
      'userName': userName,
      'type': type.name,
      'amount': amount,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shiftId': shiftId,
      'businessId': businessId,
      'userId': userId,
      'userName': userName,
      'type': type.name,
      'amount': amount,
      'reason': reason,
      'createdAt': f_store.Timestamp.fromDate(createdAt),
    };
  }

  CashMovementEntity toEntity() {
    return CashMovementEntity(
      id: id,
      shiftId: shiftId,
      businessId: businessId,
      userId: userId,
      userName: userName,
      type: type,
      amount: amount,
      reason: reason,
      createdAt: createdAt,
    );
  }
}

class ShiftModel extends ShiftEntity {
  const ShiftModel({
    required super.id,
    required super.userId,
    required super.userName,
    super.userEmail,
    super.businessId,
    required super.startTime,
    super.endTime,
    required super.startCash,
    super.endCashExpected,
    super.endCashActual,
    super.cashDifference,
    super.totalCashSales = 0,
    super.totalNonCashSales = 0,
    super.totalSales = 0,
    super.totalTransactions = 0,
    super.status = ShiftStatus.open,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ShiftModel.fromEntity(ShiftEntity entity) {
    return ShiftModel(
      id: entity.id,
      userId: entity.userId,
      userName: entity.userName,
      userEmail: entity.userEmail,
      businessId: entity.businessId,
      startTime: entity.startTime,
      endTime: entity.endTime,
      startCash: entity.startCash,
      endCashExpected: entity.endCashExpected,
      endCashActual: entity.endCashActual,
      cashDifference: entity.cashDifference,
      totalCashSales: entity.totalCashSales,
      totalNonCashSales: entity.totalNonCashSales,
      totalSales: entity.totalSales,
      totalTransactions: entity.totalTransactions,
      status: entity.status,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ShiftModel.fromFirestore(f_store.DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return ShiftModel.fromMap(map, doc.id);
  }

  factory ShiftModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val is f_store.Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? (fallback ?? DateTime.now());
      return fallback ?? DateTime.now();
    }

    return ShiftModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'],
      businessId: map['businessId'],
      startTime: parseDate(map['startTime']),
      endTime: map['endTime'] != null ? parseDate(map['endTime']) : null,
      startCash: (map['startCash'] ?? 0).toDouble(),
      endCashExpected: map['endCashExpected'] != null
          ? (map['endCashExpected']).toDouble()
          : null,
      endCashActual: map['endCashActual'] != null
          ? (map['endCashActual']).toDouble()
          : null,
      cashDifference: map['cashDifference'] != null
          ? (map['cashDifference']).toDouble()
          : null,
      totalCashSales: (map['totalCashSales'] ?? 0).toDouble(),
      totalNonCashSales: (map['totalNonCashSales'] ?? 0).toDouble(),
      totalSales: (map['totalSales'] ?? 0).toDouble(),
      totalTransactions: map['totalTransactions'] ?? 0,
      status: ShiftStatus.fromString(map['status']),
      notes: map['notes'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val is String) return DateTime.tryParse(val) ?? (fallback ?? DateTime.now());
      return fallback ?? DateTime.now();
    }

    return ShiftModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'],
      businessId: json['businessId'],
      startTime: parseDate(json['startTime']),
      endTime: json['endTime'] != null ? parseDate(json['endTime']) : null,
      startCash: (json['startCash'] ?? 0).toDouble(),
      endCashExpected: json['endCashExpected'] != null
          ? (json['endCashExpected']).toDouble()
          : null,
      endCashActual: json['endCashActual'] != null
          ? (json['endCashActual']).toDouble()
          : null,
      cashDifference: json['cashDifference'] != null
          ? (json['cashDifference']).toDouble()
          : null,
      totalCashSales: (json['totalCashSales'] ?? 0).toDouble(),
      totalNonCashSales: (json['totalNonCashSales'] ?? 0).toDouble(),
      totalSales: (json['totalSales'] ?? 0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
      status: ShiftStatus.fromString(json['status']),
      notes: json['notes'],
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'businessId': businessId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'startCash': startCash,
      'endCashExpected': endCashExpected,
      'endCashActual': endCashActual,
      'cashDifference': cashDifference,
      'totalCashSales': totalCashSales,
      'totalNonCashSales': totalNonCashSales,
      'totalSales': totalSales,
      'totalTransactions': totalTransactions,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'businessId': businessId,
      'startTime': f_store.Timestamp.fromDate(startTime),
      'endTime': endTime != null ? f_store.Timestamp.fromDate(endTime!) : null,
      'startCash': startCash,
      'endCashExpected': endCashExpected,
      'endCashActual': endCashActual,
      'cashDifference': cashDifference,
      'totalCashSales': totalCashSales,
      'totalNonCashSales': totalNonCashSales,
      'totalSales': totalSales,
      'totalTransactions': totalTransactions,
      'status': status.name,
      'notes': notes,
      'createdAt': f_store.Timestamp.fromDate(createdAt),
      'updatedAt': f_store.Timestamp.fromDate(updatedAt),
    };
  }

  @override
  ShiftModel copyWith({
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
    return ShiftModel(
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

  ShiftEntity toEntity() {
    return ShiftEntity(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      businessId: businessId,
      startTime: startTime,
      endTime: endTime,
      startCash: startCash,
      endCashExpected: endCashExpected,
      endCashActual: endCashActual,
      cashDifference: cashDifference,
      totalCashSales: totalCashSales,
      totalNonCashSales: totalNonCashSales,
      totalSales: totalSales,
      totalTransactions: totalTransactions,
      status: status,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
