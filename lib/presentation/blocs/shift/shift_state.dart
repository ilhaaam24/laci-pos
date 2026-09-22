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

  const ShiftState({
    this.activeShift,
    this.currentSummary,
    this.historyShifts = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastClosedShift,
    this.lastClosedSummary,
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
  }) {
    return ShiftState(
      activeShift: clearActiveShift ? null : (activeShift ?? this.activeShift),
      currentSummary:
          clearCurrentSummary ? null : (currentSummary ?? this.currentSummary),
      historyShifts: historyShifts ?? this.historyShifts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastClosedShift: lastClosedShift ?? this.lastClosedShift,
      lastClosedSummary: lastClosedSummary ?? this.lastClosedSummary,
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
      ];
}
