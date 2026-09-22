import 'package:flutter_test/flutter_test.dart';
import 'package:laci/data/models/shift_model.dart';
import 'package:laci/domain/entities/shift_entity.dart';

void main() {
  group('Shift & Cash Movement Entities & Models Tests', () {
    test('ShiftModel serialization and deserialization roundtrip', () {
      final now = DateTime(2026, 9, 21, 8, 30);
      final model = ShiftModel(
        id: 'shift-123',
        userId: 'user-1',
        userName: 'Budi Kasir',
        userEmail: 'budi@tokosaya.com',
        businessId: 'biz-1',
        startTime: now,
        startCash: 150000,
        status: ShiftStatus.open,
        createdAt: now,
        updatedAt: now,
      );

      final json = model.toJson();
      expect(json['id'], 'shift-123');
      expect(json['startCash'], 150000);
      expect(json['status'], 'open');

      final fromJson = ShiftModel.fromJson(json);
      expect(fromJson.id, model.id);
      expect(fromJson.userName, 'Budi Kasir');
      expect(fromJson.startCash, 150000);
      expect(fromJson.isOpen, true);
      expect(fromJson.isClosed, false);
    });

    test('CashMovementModel serialization and deserialization', () {
      final now = DateTime(2026, 9, 21, 10, 15);
      final movement = CashMovementModel(
        id: 'cm-1',
        shiftId: 'shift-123',
        businessId: 'biz-1',
        userId: 'user-1',
        userName: 'Budi Kasir',
        type: CashMovementType.cashOut,
        amount: 25000,
        reason: 'Beli Es Batu',
        createdAt: now,
      );

      final json = movement.toJson();
      expect(json['type'], 'cashOut');
      expect(json['amount'], 25000);
      expect(json['reason'], 'Beli Es Batu');

      final fromJson = CashMovementModel.fromJson(json);
      expect(fromJson.type, CashMovementType.cashOut);
      expect(fromJson.type.displayName, 'Kas Keluar');
      expect(fromJson.amount, 25000);
    });

    test('CashMovementType displayName and parsing', () {
      expect(CashMovementType.fromString('cashIn'), CashMovementType.cashIn);
      expect(CashMovementType.fromString('cash_out'), CashMovementType.cashOut);
      expect(CashMovementType.cashIn.displayName, 'Kas Masuk');
      expect(CashMovementType.cashOut.displayName, 'Kas Keluar');
    });

    test('ShiftSummary correctly calculates expectedCashInDrawer', () {
      final now = DateTime.now();
      final shift = ShiftEntity(
        id: 'shift-1',
        userId: 'user-1',
        userName: 'Andi',
        startTime: now,
        startCash: 200000,
        createdAt: now,
        updatedAt: now,
      );

      final movements = [
        CashMovementEntity(
          id: 'cm-1',
          shiftId: 'shift-1',
          userId: 'user-1',
          userName: 'Andi',
          type: CashMovementType.cashIn,
          amount: 50000, // Tambah kembalian
          reason: 'Tambah Pecahan',
          createdAt: now,
        ),
        CashMovementEntity(
          id: 'cm-2',
          shiftId: 'shift-1',
          userId: 'user-1',
          userName: 'Andi',
          type: CashMovementType.cashOut,
          amount: 20000, // Beli galon
          reason: 'Beli Galon',
          createdAt: now,
        ),
      ];

      final summary = ShiftSummary(
        shift: shift,
        startCash: shift.startCash, // 200,000
        totalCashSales: 350000,     // 350,000
        totalQrisSales: 150000,     // 150,000 (non-cash)
        totalDebitSales: 100000,    // 100,000 (non-cash)
        totalTransferSales: 0,
        totalSales: 600000,
        totalTransactions: 12,
        totalCashIn: 50000,         // +50,000
        totalCashOut: 20000,        // -20,000
        cashMovements: movements,
      );

      // Expected Cash = Modal (200k) + Cash Sales (350k) + CashIn (50k) - CashOut (20k) = 580,000
      expect(summary.expectedCashInDrawer, 580000);

      // Skenario 1: Uang fisik pas
      expect(summary.calculateDifference(580000), 0);

      // Skenario 2: Uang fisik kurang (minus)
      expect(summary.calculateDifference(575000), -5000);

      // Skenario 3: Uang fisik lebih (surplus)
      expect(summary.calculateDifference(590000), 10000);
    });

    test('Closing shift updates state and calculates discrepancy accurately', () {
      final now = DateTime.now();
      final shift = ShiftEntity(
        id: 'shift-99',
        userId: 'user-1',
        userName: 'Siti',
        startTime: now.subtract(const Duration(hours: 8)),
        startCash: 100000,
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(hours: 8)),
      );

      final summary = ShiftSummary(
        shift: shift,
        startCash: 100000,
        totalCashSales: 200000,
        totalQrisSales: 100000,
        totalDebitSales: 0,
        totalTransferSales: 0,
        totalSales: 300000,
        totalTransactions: 5,
        totalCashIn: 0,
        totalCashOut: 15000,
        cashMovements: [],
      );

      // Expected Cash = 100,000 + 200,000 - 15,000 = 285,000
      expect(summary.expectedCashInDrawer, 285000);

      // Actual cash counted by cashier: 280,000 (Selisih minus 5,000)
      final actualCash = 280000.0;
      final diff = summary.calculateDifference(actualCash);

      final closedShift = shift.copyWith(
        endTime: now,
        endCashExpected: summary.expectedCashInDrawer,
        endCashActual: actualCash,
        cashDifference: diff,
        totalCashSales: summary.totalCashSales,
        totalNonCashSales: summary.totalQrisSales,
        totalSales: summary.totalSales,
        totalTransactions: summary.totalTransactions,
        status: ShiftStatus.closed,
      );

      expect(closedShift.isClosed, true);
      expect(closedShift.isOpen, false);
      expect(closedShift.endCashExpected, 285000);
      expect(closedShift.endCashActual, 280000);
      expect(closedShift.cashDifference, -5000);
    });
  });
}
