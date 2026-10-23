import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction_entity.dart';

abstract class PaymentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CalculatePayment extends PaymentEvent {
  final double subtotal;
  final double taxPercent;
  final double discountAmount;
  final double serviceChargePercent;

  CalculatePayment({
    required this.subtotal,
    this.taxPercent = 0,
    this.discountAmount = 0,
    this.serviceChargePercent = 0,
  });

  @override
  List<Object?> get props => [
    subtotal,
    taxPercent,
    discountAmount,
    serviceChargePercent,
  ];
}

class SetAmountPaid extends PaymentEvent {
  final double amount;

  SetAmountPaid(this.amount);

  @override
  List<Object?> get props => [amount];
}

class SetPaymentMethod extends PaymentEvent {
  final PaymentType method;

  SetPaymentMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class AddPayment extends PaymentEvent {
  final PaymentDetail payment;

  AddPayment(this.payment);

  @override
  List<Object?> get props => [payment];
}

class RemovePayment extends PaymentEvent {
  final int index;

  RemovePayment(this.index);

  @override
  List<Object?> get props => [index];
}

class ApplyDiscount extends PaymentEvent {
  final double discount;

  ApplyDiscount(this.discount);

  @override
  List<Object?> get props => [discount];
}

class ResetPayment extends PaymentEvent {}
