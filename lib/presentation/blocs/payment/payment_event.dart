import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CalculatePayment extends PaymentEvent {
  final double subtotal;
  final double taxPercent;
  final double discountAmount;

  CalculatePayment({
    required this.subtotal,
    this.taxPercent = 0,
    this.discountAmount = 0,
  });

  @override
  List<Object?> get props => [subtotal, taxPercent, discountAmount];
}

class SetAmountPaid extends PaymentEvent {
  final double amount;

  SetAmountPaid(this.amount);

  @override
  List<Object?> get props => [amount];
}

class SetPaymentMethod extends PaymentEvent {
  final String method;

  SetPaymentMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class ApplyDiscount extends PaymentEvent {
  final double discount;

  ApplyDiscount(this.discount);

  @override
  List<Object?> get props => [discount];
}

class ResetPayment extends PaymentEvent {}
