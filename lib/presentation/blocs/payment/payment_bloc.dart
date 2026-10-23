import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laci/domain/entities/transaction_entity.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc() : super(const PaymentState()) {
    on<CalculatePayment>(_onCalculatePayment);
    on<SetAmountPaid>(_onSetAmountPaid);
    on<SetPaymentMethod>(_onSetPaymentMethod);
    on<AddPayment>(_onAddPayment);
    on<RemovePayment>(_onRemovePayment);
    on<ApplyDiscount>(_onApplyDiscount);
    on<ResetPayment>(_onResetPayment);
  }

  void _onCalculatePayment(CalculatePayment event, Emitter<PaymentState> emit) {
    final netSubtotal = event.subtotal - event.discountAmount > 0
        ? event.subtotal - event.discountAmount
        : 0.0;
    final taxAmount = netSubtotal * (event.taxPercent / 100);
    final serviceAmount = netSubtotal * (event.serviceChargePercent / 100);
    final totalAmount =
        event.subtotal - event.discountAmount + taxAmount + serviceAmount;

    emit(
      state.copyWith(
        subtotal: event.subtotal,
        taxPercent: event.taxPercent,
        taxAmount: taxAmount,
        discountAmount: event.discountAmount,
        totalAmount: totalAmount,
      ),
    );
  }

  void _onSetAmountPaid(SetAmountPaid event, Emitter<PaymentState> emit) {
    emit(state.copyWith(amountPaid: event.amount));
    _validate(emit);
  }

  void _onAddPayment(AddPayment event, Emitter<PaymentState> emit) {
    final updatedPayments = List<PaymentDetail>.from(state.payments)..add(event.payment);
    emit(state.copyWith(payments: updatedPayments, amountPaid: 0));
    _validate(emit);
  }

  void _onRemovePayment(RemovePayment event, Emitter<PaymentState> emit) {
    final updatedPayments = List<PaymentDetail>.from(state.payments)..removeAt(event.index);
    emit(state.copyWith(payments: updatedPayments));
    _validate(emit);
  }

  void _onSetPaymentMethod(SetPaymentMethod event, Emitter<PaymentState> emit) {
    // This could set the currently selected method in UI state if we had a field for it
    // For now, we'll just use it to maybe pre-fill the amount
  }

  void _validate(Emitter<PaymentState> emit) {
    final totalPaid = state.totalPaid;
    final totalAmount = state.totalAmount;
    final changeAmount = totalPaid > totalAmount ? totalPaid - totalAmount : 0.0;
    
    // It's valid if totalPaid is enough to cover totalAmount
    // OR if there's only one payment and it's Cash (where they might pay more)
    final isValid = totalPaid >= totalAmount;

    emit(
      state.copyWith(
        changeAmount: changeAmount,
        isValid: isValid,
        errorMessage: isValid ? null : 'Pembayaran belum mencukupi',
      ),
    );
  }

  void _onApplyDiscount(ApplyDiscount event, Emitter<PaymentState> emit) {
    final totalAmount = state.subtotal + state.taxAmount - event.discount;

    emit(
      state.copyWith(discountAmount: event.discount, totalAmount: totalAmount),
    );
  }

  void _onResetPayment(ResetPayment event, Emitter<PaymentState> emit) {
    emit(const PaymentState());
  }
}
