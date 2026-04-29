import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:laci/presentation/blocs/business/business_bloc.dart';
import 'package:laci/presentation/blocs/payment/payment_bloc.dart';
import 'package:laci/presentation/blocs/payment/payment_event.dart';
import 'package:laci/presentation/blocs/payment/payment_state.dart';
import '../../../../core/style/app_colors.dart';

class PaymentDialog extends StatefulWidget {
  final double subtotal;
  final double taxPercent;
  final double discountAmount;
  final Function(String paymentMethod, double amountPaid, double changeAmount)
  onConfirm;

  const PaymentDialog({
    super.key,
    required this.subtotal,
    this.taxPercent = 0,
    this.discountAmount = 0,
    required this.onConfirm,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _amountController = TextEditingController();
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<String> _paymentMethods = [
    'Cash',
    'Debit Card',
    'Credit Card',
    'E-Wallet',
    'Transfer Bank',
    'QRIS',
  ];

  final List<double> _quickAmounts = [
    10000,
    20000,
    50000,
    100000,
    200000,
    500000,
  ];

  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(
      CalculatePayment(
        subtotal: widget.subtotal,
        taxPercent: widget.taxPercent,
        discountAmount: widget.discountAmount,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    context.read<PaymentBloc>().add(SetAmountPaid(amount));
  }

  void _onAmountChanged(String value) {
    final amount = double.tryParse(value) ?? 0;
    context.read<PaymentBloc>().add(SetAmountPaid(amount));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pembayaran',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Payment Summary
                  _buildSummaryRow('Subtotal', state.subtotal),
                  if (state.taxPercent > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Pajak (${state.taxPercent}%)',
                      state.taxAmount,
                    ),
                  ],
                  if (state.discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Diskon',
                      -state.discountAmount,
                      color: AppColors.success,
                    ),
                  ],
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'TOTAL',
                    state.totalAmount,
                    isBold: true,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),

                  const SizedBox(height: 24),

                  // Payment Method
                  DropdownButtonFormField<String>(
                    initialValue: state.paymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Metode Pembayaran',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.payment),
                    ),
                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<PaymentBloc>().add(
                          SetPaymentMethod(value),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Amount Input (only for cash)
                  if (state.paymentMethod == 'Cash') ...[
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Uang',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixText: 'Rp ',
                        errorText: state.errorMessage,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _amountController.clear();
                            context.read<PaymentBloc>().add(SetAmountPaid(0));
                          },
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _onAmountChanged,
                      autofocus: true,
                    ),

                    const SizedBox(height: 16),

                    // Quick Amount Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickAmounts.map((amount) {
                        return TextButton(
                          onPressed: () => _setQuickAmount(amount),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            backgroundColor: AppColors.background,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: Text(
                            _currencyFormatter.format(amount),
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Change Amount
                    if (state.changeAmount >= 0 && state.amountPaid > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kembalian',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currencyFormatter.format(state.changeAmount),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],

                  // QRIS Display
                  if (state.paymentMethod == 'QRIS') ...[
                    const SizedBox(height: 16),
                    BlocBuilder<BusinessBloc, BusinessState>(
                      builder: (context, businessState) {
                        final qrisUrl = businessState.businessInfo?.qrisUrl;
                        if (qrisUrl == null) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'QRIS belum diatur di pengaturan.',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Column(
                          children: [
                            const Text(
                              'Silakan pindai kode QR di bawah ini:',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.divider),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: qrisUrl,
                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Confirm Button
                  TextButton(
                    onPressed: state.isValid
                        ? () {
                            widget.onConfirm(
                              state.paymentMethod,
                              state.amountPaid,
                              state.changeAmount,
                            );
                          }
                        : null,
                    child: const Text('Konfirmasi Pembayaran'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          _currencyFormatter.format(amount),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}
