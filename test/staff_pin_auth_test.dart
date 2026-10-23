import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laci/core/services/session_service.dart';
import 'package:laci/core/services/staff_auth_service.dart';
import 'package:laci/data/models/user_model.dart';
import 'package:laci/domain/entities/shift_entity.dart';
import 'package:laci/domain/entities/user_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laci/core/di/injection.dart';
import 'package:laci/domain/repositories/shift_repository.dart';
import 'package:laci/presentation/blocs/shift/shift_bloc.dart';
import 'package:laci/presentation/pages/kasir/widgets/close_shift_dialog.dart';
import 'package:laci/presentation/pages/kasir/widgets/open_shift_dialog.dart';
import 'package:laci/presentation/pages/kasir/widgets/shift_handover_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionService sessionService;
  late StaffAuthService staffAuthService;

  final ownerUser = UserModel(
    id: 'owner_1',
    email: 'owner@warungkopi.com',
    name: 'Pak Hendra (Owner)',
    role: UserRole.owner,
    businessId: 'biz_001',
    pin: '9999',
  );

  final managerUser = UserModel(
    id: 'manager_1',
    email: 'manager@warungkopi.com',
    name: 'Siti (Manager)',
    role: UserRole.manager,
    businessId: 'biz_001',
    pin: '8888',
  );

  final cashierUser = UserModel(
    id: 'cashier_1',
    email: 'budi@warungkopi.com',
    name: 'Budi (Kasir)',
    role: UserRole.kasir,
    businessId: 'biz_001',
    pin: '1234',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    sessionService = SessionService();
    sessionService.setUser(ownerUser);

    staffAuthService = StaffAuthService(
      sessionService: sessionService,
      prefs: prefs,
    );

    if (getIt.isRegistered<SessionService>()) {
      getIt.unregister<SessionService>();
    }
    getIt.registerSingleton<SessionService>(sessionService);

    if (getIt.isRegistered<StaffAuthService>()) {
      getIt.unregister<StaffAuthService>();
    }
    getIt.registerSingleton<StaffAuthService>(staffAuthService);
  });

  group('UserModel & UserEntity PIN tests', () {
    test('serializes and deserializes UserModel with PIN correctly', () {
      final user = UserModel(
        id: 'user_test',
        email: 'test@pos.local',
        name: 'Rian Staf',
        role: UserRole.kasir,
        businessId: 'biz_123',
        pin: '5678',
      );

      final json = user.toJson();
      expect(json['pin'], '5678');
      expect(json['name'], 'Rian Staf');

      final deserialized = UserModel.fromJson(json);
      expect(deserialized.id, 'user_test');
      expect(deserialized.pin, '5678');
      expect(deserialized.role, UserRole.kasir);
    });

    test('UserEntity copyWith preserves or updates PIN', () {
      final user = UserEntity(
        id: 'u1',
        email: 'u1@pos.local',
        role: UserRole.kasir,
        pin: '1111',
      );

      final updated = user.copyWith(pin: '2222');
      expect(updated.pin, '2222');
      expect(updated.email, 'u1@pos.local');
    });
  });

  group('StaffAuthService PIN & Offline Caching Tests', () {
    test('cacheStaffList saves staff and getCachedStaffList retrieves them offline', () async {
      await staffAuthService.cacheStaffList([ownerUser, managerUser, cashierUser]);

      final cached = await staffAuthService.getCachedStaffList();
      expect(cached.length, 3);
      expect(cached.any((s) => s.id == 'cashier_1' && s.pin == '1234'), isTrue);
      expect(cached.any((s) => s.id == 'manager_1' && s.pin == '8888'), isTrue);
    });

    test('verifyPin succeeds with correct 4-digit PIN and fails with wrong PIN', () async {
      await staffAuthService.cacheStaffList([ownerUser, managerUser, cashierUser]);

      // Correct PIN for Budi (Kasir)
      final matchedBudi = await staffAuthService.verifyPin('1234');
      expect(matchedBudi, isNotNull);
      expect(matchedBudi?.id, 'cashier_1');
      expect(matchedBudi?.name, 'Budi (Kasir)');

      // Wrong PIN
      final wrongPin = await staffAuthService.verifyPin('0000');
      expect(wrongPin, isNull);

      // Targeted PIN verification for specific staff
      final targetedValid = await staffAuthService.verifyPin('1234', targetStaffId: 'cashier_1');
      expect(targetedValid, isNotNull);

      final targetedWrong = await staffAuthService.verifyPin('8888', targetStaffId: 'cashier_1');
      expect(targetedWrong, isNull);
    });

    test('verifySupervisorPin only authorizes Manager, Admin, or Owner', () async {
      await staffAuthService.cacheStaffList([ownerUser, managerUser, cashierUser]);

      // Manager PIN (8888) is supervisor
      final supManager = await staffAuthService.verifySupervisorPin('8888');
      expect(supManager, isNotNull);
      expect(supManager?.role, UserRole.manager);

      // Owner PIN (9999) is supervisor
      final supOwner = await staffAuthService.verifySupervisorPin('9999');
      expect(supOwner, isNotNull);
      expect(supOwner?.role, UserRole.owner);

      // Cashier PIN (1234) is NOT a supervisor
      final supCashier = await staffAuthService.verifySupervisorPin('1234');
      expect(supCashier, isNull);
    });

    test('unlockScreen sets activeStaff, updates SessionService and unlocks', () async {
      await staffAuthService.cacheStaffList([cashierUser]);

      staffAuthService.lockScreen();
      expect(staffAuthService.isLocked, isTrue);

      await staffAuthService.unlockScreen(cashierUser);
      expect(staffAuthService.isLocked, isFalse);
      expect(staffAuthService.activeStaff?.id, 'cashier_1');
      expect(sessionService.currentUser?.name, 'Budi (Kasir)');
    });

    test('clearSession locks screen and resets activeStaff', () async {
      await staffAuthService.unlockScreen(cashierUser);
      expect(staffAuthService.activeStaff, isNotNull);

      await staffAuthService.clearSession();
      expect(staffAuthService.activeStaff, isNull);
      expect(staffAuthService.isLocked, isTrue);
    });
  });

  group('SessionService Staff Integration', () {
    test('currentUser defaults to activeStaff when set, otherwise falls back to storeUser', () {
      expect(sessionService.currentUser?.id, 'owner_1');

      sessionService.setActiveStaff(cashierUser);
      expect(sessionService.currentUser?.id, 'cashier_1');
      expect(sessionService.storeUser?.id, 'owner_1');

      sessionService.setActiveStaff(null);
      expect(sessionService.currentUser?.id, 'owner_1');
    });
  });

  group('ShiftHandoverDialog Widget Tests', () {
    testWidgets('renders handover info and returns closeAndOpenNew on tap', (tester) async {
      final now = DateTime(2026, 9, 21, 8, 30);
      final activeShift = ShiftEntity(
        id: 'shift_budi',
        userId: 'cashier_1',
        userName: 'Budi (Kasir)',
        businessId: 'biz_001',
        startTime: now,
        startCash: 150000,
        status: ShiftStatus.open,
        createdAt: now,
        updatedAt: now,
      );

      ShiftHandoverAction? actionResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  actionResult = await ShiftHandoverDialog.show(
                    context,
                    activeShift: activeShift,
                    incomingStaff: managerUser,
                  );
                },
                child: const Text('Show Handover'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Handover'));
      await tester.pumpAndSettle();

      expect(find.text('Pergantian Kasir Terdeteksi'), findsOneWidget);
      expect(find.text('Budi (Kasir)'), findsOneWidget);
      expect(find.text('Tutup Shift & Buka Shift Baru'), findsOneWidget);
      expect(find.text('Lanjutkan Shift Budi (Kasir)'), findsOneWidget);

      await tester.tap(find.text('Tutup Shift & Buka Shift Baru'));
      await tester.pumpAndSettle();

      expect(actionResult, ShiftHandoverAction.closeAndOpenNew);
    });

    testWidgets('returns continueShift when continue action is tapped', (tester) async {
      final now = DateTime(2026, 9, 21, 8, 30);
      final activeShift = ShiftEntity(
        id: 'shift_budi',
        userId: 'cashier_1',
        userName: 'Budi (Kasir)',
        businessId: 'biz_001',
        startTime: now,
        startCash: 150000,
        status: ShiftStatus.open,
        createdAt: now,
        updatedAt: now,
      );

      ShiftHandoverAction? actionResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  actionResult = await ShiftHandoverDialog.show(
                    context,
                    activeShift: activeShift,
                    incomingStaff: managerUser,
                  );
                },
                child: const Text('Show Handover'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Handover'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lanjutkan Shift Budi (Kasir)'));
      await tester.pumpAndSettle();

      expect(actionResult, ShiftHandoverAction.continueShift);
    });
  });

  group('Cash Handover & Shift Close Tests', () {
    test('CloseShiftResult accurately encapsulates handover options and amounts', () {
      const result1 = CloseShiftResult(
        isClosed: true,
        remainingCashInDrawer: 200000,
        depositedCash: 1300000,
        handoverOption: DrawerCashHandoverOption.leaveFloatOnly,
        handoverNote:
            'Setor omset penjualan (Rp 1.300.000), modal awal ditinggal di laci (Rp 200.000)',
      );

      expect(result1.isClosed, isTrue);
      expect(result1.remainingCashInDrawer, 200000);
      expect(result1.depositedCash, 1300000);
      expect(result1.handoverOption, DrawerCashHandoverOption.leaveFloatOnly);
      expect(result1.handoverNote, contains('Setor omset penjualan'));

      const resultRolling = CloseShiftResult(
        isClosed: true,
        remainingCashInDrawer: 1500000,
        depositedCash: 0,
        handoverOption: DrawerCashHandoverOption.keepAllInDrawer,
        handoverNote:
            'Laci bergulir: seluruh uang diteruskan ke kasir berikutnya',
      );

      expect(resultRolling.remainingCashInDrawer, 1500000);
      expect(resultRolling.depositedCash, 0);
      expect(
        resultRolling.handoverOption,
        DrawerCashHandoverOption.keepAllInDrawer,
      );

      const resultEmpty = CloseShiftResult(
        isClosed: true,
        remainingCashInDrawer: 0,
        depositedCash: 1500000,
        handoverOption: DrawerCashHandoverOption.emptyDrawer,
        handoverNote: 'Tutup toko: seluruh uang disetor, laci dikosongkan',
      );

      expect(resultEmpty.remainingCashInDrawer, 0);
      expect(resultEmpty.depositedCash, 1500000);
      expect(resultEmpty.handoverOption, DrawerCashHandoverOption.emptyDrawer);
    });

    test('ShiftState copyWith preserves and updates lastClosedRemainingCash and handoverNote', () {
      const state = ShiftState();
      expect(state.lastClosedRemainingCash, isNull);
      expect(state.lastClosedDepositedCash, isNull);
      expect(state.lastClosedHandoverNote, isNull);

      final updated = state.copyWith(
        lastClosedRemainingCash: 250000,
        lastClosedDepositedCash: 1250000,
        lastClosedHandoverNote: 'Serah terima Budi: sisa Rp 250.000',
      );

      expect(updated.lastClosedRemainingCash, 250000);
      expect(updated.lastClosedDepositedCash, 1250000);
      expect(
        updated.lastClosedHandoverNote,
        'Serah terima Budi: sisa Rp 250.000',
      );
    });

    testWidgets(
      'OpenShiftDialog renders handover banner and pre-fills float when initialAmount provided',
      (tester) async {
        await tester.pumpWidget(
          BlocProvider<ShiftBloc>(
            create: (_) => ShiftBloc(repository: _MockShiftRepoForTest()),
            child: const MaterialApp(
              home: Scaffold(
                body: OpenShiftDialog(
                  initialAmount: 200000,
                  handoverNote:
                      'Ditinggalkan Rp 200.000 di laci (Setor Rp 1.300.000)',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Buka Shift Kasir Baru'), findsOneWidget);
        expect(find.text('Serah Terima Kas Laci'), findsOneWidget);
        expect(
          find.text('Ditinggalkan Rp 200.000 di laci (Setor Rp 1.300.000)'),
          findsOneWidget,
        );
        expect(find.text('200000'), findsOneWidget);
      },
    );
  });
}

class _MockShiftRepoForTest implements ShiftRepository {
  @override
  Future<ShiftEntity?> getActiveShift() async => null;
  @override
  Stream<ShiftEntity?> watchActiveShift() => const Stream.empty();
  @override
  Future<ShiftEntity?> getShiftById(String id) async => null;
  @override
  Future<List<ShiftEntity>> getAllShifts() async => [];
  @override
  Stream<List<ShiftEntity>> watchAllShifts() => const Stream.empty();
  @override
  Future<ShiftEntity> openShift({
    required double startCash,
    String? notes,
  }) async {
    final now = DateTime.now();
    return ShiftEntity(
      id: 's1',
      userId: 'u1',
      userName: 'Kasir',
      startTime: now,
      startCash: startCash,
      status: ShiftStatus.open,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<ShiftSummary> getShiftSummary(String shiftId) async => ShiftSummary(
    shift: ShiftEntity(
      id: shiftId,
      userId: 'u1',
      userName: 'Kasir',
      startTime: DateTime.now(),
      startCash: 100000,
      status: ShiftStatus.open,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    startCash: 100000,
    totalCashSales: 0,
    totalQrisSales: 0,
    totalDebitSales: 0,
    totalTransferSales: 0,
    totalSales: 0,
    totalTransactions: 0,
    totalCashIn: 0,
    totalCashOut: 0,
    cashMovements: const [],
  );

  @override
  Future<CashMovementEntity> addCashMovement({
    required String shiftId,
    required CashMovementType type,
    required double amount,
    required String reason,
  }) async => throw UnimplementedError();

  @override
  Future<ShiftEntity> closeShift({
    required String shiftId,
    required double actualCash,
    String? notes,
  }) async => throw UnimplementedError();

  @override
  Future<List<CashMovementEntity>> getCashMovements(String shiftId) async => [];
}

