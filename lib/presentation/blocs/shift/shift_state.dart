import 'package:equatable/equatable.dart';
import '../../../domain/entities/shift_entity.dart';

class ShiftState extends Equatable {
  final ShiftEntity? activeShift;
  final ShiftSummary? currentSummary;
  final List<ShiftEntity> historyShifts;
  final bool isLoading;
  final String? errorMessage;
  final ShiftEntity? lastClosedShift;
  final ShiftSummary? lastClosedSummary;
  final double? lastClosedRemainingCash;
  final double? lastClosedDepositedCash;
  final String? lastClosedHandoverNote;

  const ShiftState({
    this.activeShift,
    this.currentSummary,
    this.historyShifts = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastClosedShift,
    this.lastClosedSummary,
    this.lastClosedRemainingCash,
    this.lastClosedDepositedCash,
    this.lastClosedHandoverNote,
  });

  bool get hasActiveShift => activeShift != null && activeShift!.isOpen;

  ShiftState copyWith({
    ShiftEntity? activeShift,
    bool clearActiveShift = false,
    ShiftSummary? currentSummary,
    bool clearCurrentSummary = false,
    List<ShiftEntity>? historyShifts,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    ShiftEntity? lastClosedShift,
    ShiftSummary? lastClosedSummary,
    double? lastClosedRemainingCash,
    double? lastClosedDepositedCash,
    String? lastClosedHandoverNote,
  }) {
    return ShiftState(
      activeShift: clearActiveShift ? null : (activeShift ?? this.activeShift),
      currentSummary: clearCurrentSummary
          ? null
          : (currentSummary ?? this.currentSummary),
      historyShifts: historyShifts ?? this.historyShifts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastClosedShift: lastClosedShift ?? this.lastClosedShift,
      lastClosedSummary: lastClosedSummary ?? this.lastClosedSummary,
      lastClosedRemainingCash:
          lastClosedRemainingCash ?? this.lastClosedRemainingCash,
      lastClosedDepositedCash:
          lastClosedDepositedCash ?? this.lastClosedDepositedCash,
      lastClosedHandoverNote:
          lastClosedHandoverNote ?? this.lastClosedHandoverNote,
    );
  }

  @override
  List<Object?> get props => [
    activeShift,
    currentSummary,
    historyShifts,
    isLoading,
    errorMessage,
    lastClosedShift,
    lastClosedSummary,
    lastClosedRemainingCash,
    lastClosedDepositedCash,
    lastClosedHandoverNote,
  ];
}
