import 'package:equatable/equatable.dart';
import '../../../domain/entities/shift_entity.dart';

abstract class ShiftEvent extends Equatable {
  const ShiftEvent();

  @override
  List<Object?> get props => [];
}

class CheckActiveShift extends ShiftEvent {}

class OpenShift extends ShiftEvent {
  final double startCash;
  final String? notes;

  const OpenShift({
    required this.startCash,
    this.notes,
  });

  @override
  List<Object?> get props => [startCash, notes];
}

class AddCashMovement extends ShiftEvent {
  final CashMovementType type;
  final double amount;
  final String reason;

  const AddCashMovement({
    required this.type,
    required this.amount,
    required this.reason,
  });

  @override
  List<Object?> get props => [type, amount, reason];
}

class LoadShiftSummary extends ShiftEvent {
  final String? shiftId;

  const LoadShiftSummary([this.shiftId]);

  @override
  List<Object?> get props => [shiftId];
}

class CloseShift extends ShiftEvent {
  final String shiftId;
  final double actualCash;
  final String? notes;

  const CloseShift({
    required this.shiftId,
    required this.actualCash,
    this.notes,
  });

  @override
  List<Object?> get props => [shiftId, actualCash, notes];
}

class LoadShiftHistory extends ShiftEvent {}
