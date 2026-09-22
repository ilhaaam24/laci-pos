import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/shift_repository.dart';
import 'shift_event.dart';
import 'shift_state.dart';

export 'shift_event.dart';
export 'shift_state.dart';

class ShiftBloc extends Bloc<ShiftEvent, ShiftState> {
  final ShiftRepository repository;

  ShiftBloc({required this.repository}) : super(const ShiftState()) {
    on<CheckActiveShift>(_onCheckActiveShift);
    on<OpenShift>(_onOpenShift);
    on<AddCashMovement>(_onAddCashMovement);
    on<LoadShiftSummary>(_onLoadShiftSummary);
    on<CloseShift>(_onCloseShift);
    on<LoadShiftHistory>(_onLoadShiftHistory);
  }

  Future<void> _onCheckActiveShift(
    CheckActiveShift event,
    Emitter<ShiftState> emit,
  ) async {
    try {
      final active = await repository.getActiveShift();
      if (active != null) {
        final summary = await repository.getShiftSummary(active.id);
        emit(state.copyWith(
          activeShift: active,
          currentSummary: summary,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          clearActiveShift: true,
          clearCurrentSummary: true,
          clearError: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onOpenShift(
    OpenShift event,
    Emitter<ShiftState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final newShift = await repository.openShift(
        startCash: event.startCash,
        notes: event.notes,
      );
      final summary = await repository.getShiftSummary(newShift.id);
      emit(state.copyWith(
        activeShift: newShift,
        currentSummary: summary,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddCashMovement(
    AddCashMovement event,
    Emitter<ShiftState> emit,
  ) async {
    final activeShift = state.activeShift;
    if (activeShift == null) {
      emit(state.copyWith(errorMessage: 'Tidak ada shift aktif'));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await repository.addCashMovement(
        shiftId: activeShift.id,
        type: event.type,
        amount: event.amount,
        reason: event.reason,
      );
      final summary = await repository.getShiftSummary(activeShift.id);
      emit(state.copyWith(
        currentSummary: summary,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadShiftSummary(
    LoadShiftSummary event,
    Emitter<ShiftState> emit,
  ) async {
    final shiftId = event.shiftId ?? state.activeShift?.id;
    if (shiftId == null) return;

    try {
      final summary = await repository.getShiftSummary(shiftId);
      emit(state.copyWith(currentSummary: summary, clearError: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onCloseShift(
    CloseShift event,
    Emitter<ShiftState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final summaryBeforeClose = await repository.getShiftSummary(event.shiftId);
      final closedShift = await repository.closeShift(
        shiftId: event.shiftId,
        actualCash: event.actualCash,
        notes: event.notes,
      );

      final history = await repository.getAllShifts();

      emit(state.copyWith(
        clearActiveShift: true,
        clearCurrentSummary: true,
        lastClosedShift: closedShift,
        lastClosedSummary: summaryBeforeClose,
        historyShifts: history,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadShiftHistory(
    LoadShiftHistory event,
    Emitter<ShiftState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final history = await repository.getAllShifts();
      emit(state.copyWith(
        historyShifts: history,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
