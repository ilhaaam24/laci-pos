import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:laci/domain/entities/transaction_entity.dart';
import 'package:laci/presentation/blocs/business/business_bloc.dart';
import 'package:laci/presentation/blocs/payment/payment_bloc.dart';
import 'package:laci/presentation/blocs/payment/payment_event.dart';
import 'package:laci/presentation/blocs/payment/payment_state.dart';
import '../../../../core/style/app_colors.dart';

class PaymentDialog extends StatefulWidget {
  final double subtotal;
  final double taxPercent;
  final double discountAmount;
  final Function(List<PaymentDetail> payments, double changeAmount) onConfirm;

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

  PaymentType _selectedType = PaymentType.cash;

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

  void _addPayment(double amount) {
    if (amount <= 0) return;

    final payment = PaymentDetail(
      type: _selectedType,
      amount: amount,
      timestamp: DateTime.now(),
    );

    context.read<PaymentBloc>().add(AddPayment(payment));
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
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
                        'Metode Pembayaran',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Summary & Remaining
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          'Total Tagihan',
                          state.totalAmount,
                          isBold: true,
                          fontSize: 16,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Total Dibayar',
                          state.totalPaid,
                          color: AppColors.success,
                        ),
                        const Divider(height: 24),
                        if (state.remainingAmount > 0)
                          _buildSummaryRow(
                            'Sisa Tagihan',
                            state.remainingAmount,
                            isBold: true,
                            fontSize: 18,
                            color: AppColors.error,
                          )
                        else
                          _buildSummaryRow(
                            'Kembalian',
                            state.changeAmount,
                            isBold: true,
                            fontSize: 18,
                            color: AppColors.success,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // List of Payments
                  if (state.payments.isNotEmpty) ...[
                    const Text(
                      'Rincian Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...state.payments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final payment = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getIconForType(payment.type),
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                payment.typeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              _currencyFormatter.format(payment.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              onPressed: () {
                                context
                                    .read<PaymentBloc>()
                                    .add(RemovePayment(index));
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],

                  // Add Payment Section
                  if (state.remainingAmount > 0) ...[
                    const Text(
                      'Tambah Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    // Payment Method Selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: PaymentType.values.map((type) {
                          final isSelected = _selectedType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_getTypeLabel(type)),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedType = type);
                                }
                              },
                              selectedColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'Jumlah',
                              hintText: state.remainingAmount.toStringAsFixed(0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixText: 'Rp ',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: _onAmountChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _addPayment(state.amountPaid),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Tambah'),
                        ),
                      ],
                    ),

                    if (_selectedType == PaymentType.cash) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._quickAmounts.map((amount) {
                            return ActionChip(
                              label: Text(_currencyFormatter.format(amount)),
                              onPressed: () => _setQuickAmount(amount),
                              backgroundColor: AppColors.background,
                            );
                          }),
                          ActionChip(
                            label: const Text('Uang Pas'),
                            onPressed: () =>
                                _setQuickAmount(state.remainingAmount),
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.05),
                          ),
                        ],
                      ),
                    ],

                    if (_selectedType == PaymentType.qris) ...[
                      const SizedBox(height: 16),
                      _buildQRIS(context),
                    ],
                  ],

                  const SizedBox(height: 32),

                  // Final Confirm Button
                  ElevatedButton(
                    onPressed: state.isValid
                        ? () {
                            widget.onConfirm(state.payments, state.changeAmount);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.divider,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Selesaikan Transaksi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQRIS(BuildContext context) {
    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, businessState) {
        final qrisUrl = businessState.businessInfo?.qrisUrl;
        if (qrisUrl == null) {
          return const Text(
            'QRIS belum diatur di pengaturan.',
            style: TextStyle(color: AppColors.error, fontSize: 12),
            textAlign: TextAlign.center,
          );
        }
        return Center(
          child: Column(
            children: [
              const Text(
                'Silakan pindai kode QR:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              CachedNetworkImage(
                imageUrl: qrisUrl,
                height: 200,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTypeLabel(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return 'Tunai';
      case PaymentType.qris:
        return 'QRIS';
      case PaymentType.debit:
        return 'Debit';
      case PaymentType.transfer:
        return 'Transfer';
    }
  }

  IconData _getIconForType(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return Icons.money;
      case PaymentType.qris:
        return Icons.qr_code_scanner;
      case PaymentType.debit:
        return Icons.credit_card;
      case PaymentType.transfer:
        return Icons.account_balance;
    }
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
