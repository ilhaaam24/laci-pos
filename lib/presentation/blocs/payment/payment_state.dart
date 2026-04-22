import 'package:equatable/equatable.dart';

class PaymentState extends Equatable {
  final double subtotal;
  final double taxPercent;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double amountPaid;
  final double changeAmount;
  final String paymentMethod;
  final bool isValid;
  final String? errorMessage;

  const PaymentState({
    this.subtotal = 0,
    this.taxPercent = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    this.amountPaid = 0,
    this.changeAmount = 0,
    this.paymentMethod = 'Cash',
    this.isValid = false,
    this.errorMessage,
  });

  PaymentState copyWith({
    double? subtotal,
    double? taxPercent,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    double? amountPaid,
    double? changeAmount,
    String? paymentMethod,
    bool? isValid,
    String? errorMessage,
  }) {
    return PaymentState(
      subtotal: subtotal ?? this.subtotal,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    subtotal,
    taxPercent,
    taxAmount,
    discountAmount,
    totalAmount,
    amountPaid,
    changeAmount,
    paymentMethod,
    isValid,
    errorMessage,
  ];
}
