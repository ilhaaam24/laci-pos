import 'package:flutter_bloc/flutter_bloc.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc() : super(const PaymentState()) {
    on<CalculatePayment>(_onCalculatePayment);
    on<SetAmountPaid>(_onSetAmountPaid);
    on<SetPaymentMethod>(_onSetPaymentMethod);
    on<ApplyDiscount>(_onApplyDiscount);
    on<ResetPayment>(_onResetPayment);
  }

  void _onCalculatePayment(CalculatePayment event, Emitter<PaymentState> emit) {
    final taxAmount = event.subtotal * (event.taxPercent / 100);
    final totalAmount = event.subtotal + taxAmount - event.discountAmount;

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
    final changeAmount = event.amount - state.totalAmount;
    final isValid = event.amount >= state.totalAmount;

    emit(
      state.copyWith(
        amountPaid: event.amount,
        changeAmount: changeAmount,
        isValid: isValid,
        errorMessage: isValid ? null : 'Jumlah pembayaran kurang',
      ),
    );
  }

  void _onSetPaymentMethod(SetPaymentMethod event, Emitter<PaymentState> emit) {
    emit(state.copyWith(paymentMethod: event.method));

    // Auto-validate for non-cash payments
    if (event.method != 'Cash') {
      emit(
        state.copyWith(
          amountPaid: state.totalAmount,
          changeAmount: 0,
          isValid: true,
        ),
      );
    }
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
