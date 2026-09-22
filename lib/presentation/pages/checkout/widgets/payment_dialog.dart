import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/printer_service.dart';
import '../../../../core/style/app_colors.dart';
import '../../../../domain/entities/customer_entity.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../blocs/business/business_bloc.dart';
import '../../../blocs/payment/payment_bloc.dart';
import '../../../blocs/payment/payment_event.dart';
import '../../../blocs/payment/payment_state.dart';
import '../../settings/business_info_page.dart';

class PaymentDialog extends StatefulWidget {
  final String orderCode;
  final String orderType;
  final int itemCount;
  final double subtotal;
  final double taxPercent;
  final String taxName;
  final double serviceChargeRate;
  final double discountAmount;
  final Customer? customer;
  final VoidCallback? onHoldOrder;
  final VoidCallback? onAddDiscount;
  final Function(
    List<PaymentDetail> payments,
    double changeAmount,
    bool shouldPrint,
    bool shouldSendWA,
  )
  onConfirm;

  const PaymentDialog({
    super.key,
    this.orderCode = '#ORD-042',
    this.orderType = 'Dine In',
    this.itemCount = 1,
    required this.subtotal,
    this.taxPercent = 0,
    this.taxName = 'Pajak',
    this.serviceChargeRate = 0,
    this.discountAmount = 0,
    this.customer,
    this.onHoldOrder,
    this.onAddDiscount,
    required this.onConfirm,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  PaymentType _selectedType = PaymentType.cash;
  double _receivedAmount = 0.0;
  bool _autoPrint = true;
  bool _sendWa = false;

  // EDC & Transfer state
  String _selectedBank = 'BCA';
  final _refCodeController = TextEditingController();

  // Split payment state
  bool _isSplitMode = false;
  List<PaymentDetail> _splitPayments = [];
  PaymentType _splitCurrentType = PaymentType.cash;
  double _splitInputAmount = 0.0;
  String _splitSelectedBank = 'BCA';
  final _splitRefCodeController = TextEditingController();

  double get _totalSplitPaid =>
      _splitPayments.fold(0.0, (sum, p) => sum + p.amount);

  double _getSplitRemaining(double grandTotal) {
    final rem = grandTotal - _totalSplitPaid;
    return rem > 0 ? rem : 0.0;
  }

  double _getSplitChange(double grandTotal) {
    if (_totalSplitPaid > grandTotal) {
      return _totalSplitPaid - grandTotal;
    }
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _autoPrint = PrinterService().isConnected;
    _sendWa = widget.customer?.phone?.isNotEmpty == true;

    context.read<BusinessBloc>().add(LoadBusinessInfo());

    context.read<PaymentBloc>().add(
      CalculatePayment(
        subtotal: widget.subtotal,
        taxPercent: widget.taxPercent,
        discountAmount: widget.discountAmount,
        serviceChargePercent: widget.serviceChargeRate,
      ),
    );

    final total = _calculateGrandTotal();
    _receivedAmount = _getInitialReceivedAmount(total);
    _splitInputAmount = total;
  }

  @override
  void dispose() {
    _refCodeController.dispose();
    _splitRefCodeController.dispose();
    super.dispose();
  }

  double _calculateGrandTotal() {
    final net = (widget.subtotal - widget.discountAmount > 0)
        ? (widget.subtotal - widget.discountAmount)
        : 0.0;
    final tax = net * (widget.taxPercent / 100);
    final service = net * (widget.serviceChargeRate / 100);
    return widget.subtotal - widget.discountAmount + tax + service;
  }

  double _getInitialReceivedAmount(double total) {
    if (total <= 0) return 0;
    if (total < 50000) return 50000;
    if (total < 100000) return 100000;
    if (total < 200000) return 200000;
    return ((total / 50000).ceil() * 50000).toDouble();
  }

  List<Map<String, dynamic>> _generateQuickAmounts(double total) {
    if (total <= 0) return [];

    final exact = total;

    double next1;
    if (total % 5000 != 0) {
      next1 = ((total / 5000).ceil() * 5000).toDouble();
    } else {
      next1 = total + 5000;
    }

    double next2;
    if (next1 % 10000 != 0) {
      next2 = ((next1 / 10000).ceil() * 10000).toDouble();
    } else {
      next2 = next1 + 10000;
    }
    if (next2 <= next1) next2 = next1 + 10000;

    double next3;
    if (total < 50000) {
      next3 = 50000;
    } else if (total < 100000) {
      next3 = 100000;
    } else if (total < 200000) {
      next3 = 200000;
    } else {
      next3 = ((total / 100000).ceil() * 100000).toDouble();
    }
    if (next3 <= next2) next3 = next2 + 20000;

    String formatShort(double val) {
      if (val >= 1000) {
        final k = (val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1);
        return '${k}k';
      }
      return val.toStringAsFixed(0);
    }

    return [
      {'label': 'Uang Pas', 'sublabel': '', 'amount': exact, 'isExact': true},
      {
        'label': 'Pas ${formatShort(next1)}',
        'sublabel': '',
        'amount': next1,
        'isExact': false,
      },
      {
        'label': 'Pas ${formatShort(next2)}',
        'sublabel': '',
        'amount': next2,
        'isExact': false,
      },
      {
        'label': (next3 == 100000 || next3 == 50000) ? '1 Lembar' : 'Pecahan',
        'sublabel': '',
        'amount': next3,
        'isExact': false,
      },
    ];
  }

  void _onBackspaceAmount() {
    setState(() {
      final currentStr = _receivedAmount.toInt().toString();
      if (currentStr.length <= 1) {
        _receivedAmount = 0;
      } else {
        final newStr = currentStr.substring(0, currentStr.length - 1);
        _receivedAmount = double.tryParse(newStr) ?? 0;
      }
    });
  }

  void _showNumericKeypad({
    double? initialAmount,
    ValueChanged<double>? onAmountChanged,
    String title = 'Input Nominal Pembayaran',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentVal = initialAmount ?? _receivedAmount;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        String inputStr = currentVal > 0 ? currentVal.toInt().toString() : '';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updateValue(double val) {
              if (onAmountChanged != null) {
                onAmountChanged(val);
              } else {
                setState(() => _receivedAmount = val);
              }
            }

            void appendDigit(String digit) {
              setSheetState(() {
                if (inputStr == '0') inputStr = '';
                if (digit == '000') {
                  if (inputStr.isNotEmpty) inputStr += '000';
                } else {
                  inputStr += digit;
                }
              });
              updateValue(double.tryParse(inputStr) ?? 0);
            }

            void deleteDigit() {
              setSheetState(() {
                if (inputStr.isNotEmpty) {
                  inputStr = inputStr.substring(0, inputStr.length - 1);
                }
              });
              updateValue(double.tryParse(inputStr) ?? 0);
            }

            void clearAll() {
              setSheetState(() => inputStr = '');
              updateValue(0);
            }

            final displayVal = double.tryParse(inputStr) ?? 0;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        InkWell(
                          onTap: clearAll,
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Rp ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _currencyFormatter
                                  .format(displayVal)
                                  .replaceAll('Rp', '')
                                  .trim(),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.backspace_outlined,
                              size: 20,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569),
                            ),
                            onPressed: deleteDigit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Keypad Grid
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.1,
                      children: [
                        for (var digit in [
                          '1',
                          '2',
                          '3',
                          '4',
                          '5',
                          '6',
                          '7',
                          '8',
                          '9',
                          '000',
                          '0',
                        ])
                          InkWell(
                            onTap: () => appendDigit(digit),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  digit,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: () => Navigator.pop(sheetContext),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                'OK',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _submitTransaction(double total) {
    double changeAmount = 0.0;
    List<PaymentDetail> payments = [];

    if (_isSplitMode) {
      if (_totalSplitPaid < total) return;
      changeAmount = _getSplitChange(total);
      payments = List<PaymentDetail>.from(_splitPayments);
    } else if (_selectedType == PaymentType.cash) {
      if (_receivedAmount < total) return;
      changeAmount = _receivedAmount - total;
      payments = [
        PaymentDetail(
          type: PaymentType.cash,
          amount: _receivedAmount,
          timestamp: DateTime.now(),
        ),
      ];
    } else {
      changeAmount = 0.0;
      payments = [
        PaymentDetail(
          type: _selectedType,
          amount: total,
          reference: _refCodeController.text.trim().isNotEmpty
              ? _refCodeController.text.trim()
              : null,
          timestamp: DateTime.now(),
        ),
      ];
    }

    widget.onConfirm(payments, changeAmount, _autoPrint, _sendWa);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            final grandTotal = _calculateGrandTotal();
            final changeAmount = (_receivedAmount >= grandTotal)
                ? _receivedAmount - grandTotal
                : 0.0;

            return Column(
              children: [
                _buildTopAppBar(isDark),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      // 1. Order Info Card
                      _buildOrderInfoCard(isDark),
                      const SizedBox(height: 16),

                      // 2. Total Tagihan Section
                      _buildTotalTagihan(grandTotal, isDark),
                      const SizedBox(height: 18),

                      // 3. Payment Method Pills
                      _buildPaymentMethodSelector(isDark),
                      const SizedBox(height: 18),

                      // 4. Content based on selected payment method or Split Mode
                      if (_isSplitMode) ...[
                        _buildSplitPaymentSection(grandTotal, isDark),
                      ] else if (_selectedType == PaymentType.cash) ...[
                        _buildCashPaymentSection(
                          grandTotal,
                          changeAmount,
                          isDark,
                        ),
                      ] else if (_selectedType == PaymentType.qris) ...[
                        _buildQrisSection(grandTotal, isDark),
                      ] else if (_selectedType == PaymentType.debit) ...[
                        _buildDebitSection(grandTotal, isDark),
                      ] else if (_selectedType == PaymentType.transfer) ...[
                        _buildTransferSection(grandTotal, isDark),
                      ],

                      const SizedBox(height: 16),

                      // 5. Setting Switches (Thermal Print & Send WA)
                      _buildSettingSwitches(isDark),
                      const SizedBox(height: 20),

                      // 6. Action Button (Selesaikan & Cetak Struk)
                      _buildSubmitButton(grandTotal),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // App Bar: Back Arrow, Teal POS Icon, Pembayaran Title & Store Subtitle, Avatar
  Widget _buildTopAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: BlocBuilder<BusinessBloc, BusinessState>(
        builder: (context, bState) {
          final businessLogo = bState.businessInfo?.logoUrl ?? '';
          final businessName =
              bState.businessInfo?.businessName.isNotEmpty == true &&
                  bState.businessInfo?.businessName != 'Toko Saya'
              ? bState.businessInfo!.businessName
              : 'Kopi Senja';
          return Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              if (businessLogo.isNotEmpty)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: CachedNetworkImage(
                      imageUrl: businessLogo,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pembayaran',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    businessName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset("assets/icons/e-receipt.svg", height: 36, width: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Order ${widget.orderCode} • ${widget.itemCount} Menu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '• Kasir Aktif',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFF34D399)
                      : const Color(0xFF065F46),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Total Tagihan Section: TOTAL TAGIHAN, Rp 70.400, Store Icon + Dine-in • Meja 04
  Widget _buildTotalTagihan(double grandTotal, bool isDark) {
    final formatted = _currencyFormatter
        .format(grandTotal)
        .replaceAll('Rp', '')
        .trim();

    return Column(
      children: [
        Text(
          'TOTAL TAGIHAN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Rp ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              formatted,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 14,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                '${widget.orderType} • Meja 04',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMethodPill(
            type: PaymentType.cash,
            label: 'Tunai',
            icon: Icons.payments_outlined,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildMethodPill(
            type: PaymentType.qris,
            label: 'QRIS',
            icon: Icons.qr_code_scanner_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildMethodPill(
            type: PaymentType.debit,
            label: 'Debit EDC',
            icon: Icons.point_of_sale_outlined,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildMethodPill(
            type: PaymentType.transfer,
            label: 'Transfer Bank',
            icon: Icons.account_balance_outlined,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildSplitPill(isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildSplitPill({required bool isDark}) {
    final isSelected = _isSplitMode;

    return InkWell(
      onTap: () {
        setState(() {
          _isSplitMode = true;
          final total = _calculateGrandTotal();
          final rem = _getSplitRemaining(total);
          if (_splitInputAmount <= 0 || _splitInputAmount > rem) {
            _splitInputAmount = rem;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : const Color(0xFF1E293B))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.call_split_rounded,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155)),
            ),
            const SizedBox(width: 6),
            Text(
              'Bagi Bayar (Split)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155)),
              ),
            ),
            if (_splitPayments.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_splitPayments.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMethodPill({
    required PaymentType type,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = !_isSplitMode && _selectedType == type;

    return InkWell(
      onTap: () => setState(() {
        _isSplitMode = false;
        _selectedType = type;
      }),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : const Color(0xFF1E293B))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Cash Payment Section: Uang Diterima, Quick Amounts, & Kembalian Kasir Card
  Widget _buildCashPaymentSection(
    double grandTotal,
    double changeAmount,
    bool isDark,
  ) {
    final quickAmounts = _generateQuickAmounts(grandTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Uang Diterima Header & Input Display Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Uang Diterima',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _showNumericKeypad(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Rp ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF475569),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _currencyFormatter
                              .format(_receivedAmount)
                              .replaceAll('Rp', '')
                              .trim(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _onBackspaceAmount,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Icon(
                            Icons.backspace_outlined,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Shortcut banner when cash received is less than grand total
              if (_receivedAmount > 0 && _receivedAmount < grandTotal) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                          : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.call_split_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kurang ${_currencyFormatter.format(grandTotal - _receivedAmount)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E3A8A),
                              ),
                            ),
                            Text(
                              'Gunakan Bagi Bayar untuk sisa via QRIS/Transfer',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _splitPayments = [
                              PaymentDetail(
                                type: PaymentType.cash,
                                amount: _receivedAmount,
                                timestamp: DateTime.now(),
                              ),
                            ];
                            _isSplitMode = true;
                            final rem = grandTotal - _receivedAmount;
                            _splitInputAmount = rem > 0 ? rem : 0.0;
                            _splitCurrentType = PaymentType.qris;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Bagi Bayar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2x2 Quick Denomination Buttons Grid
        if (quickAmounts.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isTablet = width > 720;
              final isCompact = width < 360;
              final childAspectRatio = isTablet ? 3.85 : 2.55;
              final hPadding = isCompact ? 10.0 : 14.0;
              final vPadding = isCompact ? 8.0 : 4.0;

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: childAspectRatio,
                children: quickAmounts.map((qa) {
                  final amount = qa['amount'] as double;
                  final isSelected = (_receivedAmount == amount);
                  final isExact = qa['isExact'] as bool;
                  final label = qa['label'] as String;

                  return InkWell(
                    onTap: () => setState(() => _receivedAmount = amount),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(
                        horizontal: hPadding,
                        vertical: vPadding,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? AppColors.primary
                                  : const Color(0xFF1E293B))
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: isTablet ? 24 : 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFFF9FAFB)
                                    : (isExact
                                          ? AppColors.primary
                                          : (isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B))),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Rp.${_currencyFormatter.format(amount).replaceAll('Rp', '').trim()}",
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: isTablet ? 32 : 16,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? const Color(0xFFF9FAFB)
                                      : (isExact
                                            ? AppColors.primary
                                            : (isDark
                                                  ? Colors.white
                                                  : const Color(0xFF64748B))),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        const SizedBox(height: 12),

        // Kembalian Kasir Card (Mint Container, NO SHADOW)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset("assets/icons/sync.svg", height: 22),
                  const SizedBox(width: 6),
                  Text(
                    'KEMBALIAN KASIR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFF065F46),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Rp ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFF065F46),
                    ),
                  ),
                  Text(
                    _currencyFormatter
                        .format(changeAmount)
                        .replaceAll('Rp', '')
                        .trim(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF042F2C),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Pastikan hitung uang kembalian sebelum menyerahkan ke pelanggan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF047857),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4b. Split Payment Section: Multi-Tender Breakdown & Builder
  Widget _buildSplitPaymentSection(double grandTotal, bool isDark) {
    final remaining = _getSplitRemaining(grandTotal);
    final change = _getSplitChange(grandTotal);
    final isSettled = remaining <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A. Real-time Status Card (Total, Sudah Dibayar, Sisa / Lunas, Kembalian)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSettled
                  ? (isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0))
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSplitStat(
                      label: 'Total Tagihan',
                      value: _currencyFormatter.format(grandTotal),
                      isDark: isDark,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _buildSplitStat(
                      label: 'Sudah Dibayar',
                      value: _currencyFormatter.format(_totalSplitPaid),
                      isDark: isDark,
                      valueColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSettled ? 'Status Pembayaran' : 'Sisa Tagihan',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (isSettled)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF064E3B)
                                      : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF047857)
                                        : const Color(0xFFA7F3D0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: isDark
                                          ? const Color(0xFF6EE7B7)
                                          : const Color(0xFF059669),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'LUNAS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? const Color(0xFF6EE7B7)
                                            : const Color(0xFF059669),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            _currencyFormatter.format(remaining),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFDC2626),
                              letterSpacing: -0.3,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (change > 0) ...[
                    Container(
                      width: 1,
                      height: 38,
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: _buildSplitStat(
                        label: 'Kembalian Tunai',
                        value: _currencyFormatter.format(change),
                        isDark: isDark,
                        valueColor: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // B. List of Added Payments (Daftar Pembayaran)
        if (_splitPayments.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pembayaran Diterima (${_splitPayments.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _splitPayments.clear();
                    _splitInputAmount = grandTotal;
                  });
                },
                child: const Text(
                  'Reset Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _splitPayments.length,
              separatorBuilder: (context, idx) => Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, idx) {
                final payment = _splitPayments[idx];
                final iconData = _getMethodIcon(payment.type);
                final color = _getMethodColor(payment.type);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(iconData, size: 18, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.typeName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            if (payment.reference != null &&
                                payment.reference!.isNotEmpty)
                              Text(
                                payment.reference!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        _currencyFormatter.format(payment.amount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _splitPayments.removeAt(idx);
                            final rem = _getSplitRemaining(grandTotal);
                            _splitInputAmount = rem > 0 ? rem : 0.0;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        // C. Form Tambah Pembayaran
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Pembayaran',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              // Tender Selector Row
              Row(
                children: [
                  Expanded(
                    child: _buildSplitTenderOption(
                      PaymentType.cash,
                      'Tunai',
                      Icons.payments_outlined,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSplitTenderOption(
                      PaymentType.qris,
                      'QRIS',
                      Icons.qr_code_scanner_rounded,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSplitTenderOption(
                      PaymentType.debit,
                      'Debit',
                      Icons.credit_card_rounded,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSplitTenderOption(
                      PaymentType.transfer,
                      'Transfer',
                      Icons.account_balance_rounded,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Nominal Input Box (Tappable for Keypad)
              InkWell(
                onTap: () {
                  _showNumericKeypad(
                    initialAmount: _splitInputAmount,
                    onAmountChanged: (v) =>
                        setState(() => _splitInputAmount = v),
                    title: 'Nominal ${_getMethodTitle(_splitCurrentType)}',
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Rp ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF475569),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _currencyFormatter
                              .format(_splitInputAmount)
                              .replaceAll('Rp', '')
                              .trim(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            final currentStr = _splitInputAmount
                                .toInt()
                                .toString();
                            if (currentStr.length <= 1) {
                              _splitInputAmount = 0;
                            } else {
                              final newStr = currentStr.substring(
                                0,
                                currentStr.length - 1,
                              );
                              _splitInputAmount = double.tryParse(newStr) ?? 0;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Icon(
                            Icons.backspace_outlined,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Quick Chips (Sisa Pas, +10k, +20k, +50k, +100k)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (remaining > 0) ...[
                      _buildQuickSplitChip(
                        label: 'Sisa Pas (${_formatK(remaining)})',
                        isPrimary: true,
                        isDark: isDark,
                        onTap: () =>
                            setState(() => _splitInputAmount = remaining),
                      ),
                      const SizedBox(width: 6),
                    ],
                    _buildQuickSplitChip(
                      label: '+10rb',
                      isDark: isDark,
                      onTap: () => setState(() => _splitInputAmount += 10000),
                    ),
                    const SizedBox(width: 6),
                    _buildQuickSplitChip(
                      label: '+20rb',
                      isDark: isDark,
                      onTap: () => setState(() => _splitInputAmount += 20000),
                    ),
                    const SizedBox(width: 6),
                    _buildQuickSplitChip(
                      label: '+50rb',
                      isDark: isDark,
                      onTap: () => setState(() => _splitInputAmount += 50000),
                    ),
                    const SizedBox(width: 6),
                    _buildQuickSplitChip(
                      label: '+100rb',
                      isDark: isDark,
                      onTap: () => setState(() => _splitInputAmount += 100000),
                    ),
                  ],
                ),
              ),

              // A. QRIS Preview & Scan Container
              if (_splitCurrentType == PaymentType.qris) ...[
                const SizedBox(height: 12),
                BlocBuilder<BusinessBloc, BusinessState>(
                  builder: (context, bState) {
                    final qrisUrl = bState.businessInfo?.qrisUrl;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tampilkan QRIS ke pelanggan sebesar ${_currencyFormatter.format(_splitInputAmount)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: _buildQrisImageWidget(
                              qrisUrl: qrisUrl,
                              isDark: isDark,
                              size: 170,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pelanggan dapat scan via GoPay, OVO, Dana, ShopeePay, BCA, dll.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              // B. Debit Card EDC Instructions & Fields
              if (_splitCurrentType == PaymentType.debit) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                        : const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.credit_card_rounded,
                        size: 16,
                        color: Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Gesek / Dip kartu di Mesin EDC sebesar ${_currencyFormatter.format(_splitInputAmount)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFDDD6FE)
                                : const Color(0xFF6D28D9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _buildSplitBankSelector(isDark),
                const SizedBox(height: 10),
                TextField(
                  controller: _splitRefCodeController,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    hintText: 'Nomor Kartu / Approval Code (Opsional)',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],

              // C. Bank Transfer Instructions & Fields
              if (_splitCurrentType == PaymentType.transfer) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFD97706).withValues(alpha: 0.15)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Minta transfer ${_currencyFormatter.format(_splitInputAmount)} ke rekening toko',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _buildSplitBankSelector(isDark),
                const SizedBox(height: 10),
                TextField(
                  controller: _splitRefCodeController,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    hintText: 'Nama Pengirim / No Ref Transfer (Opsional)',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Button "+ Tambahkan Pembayaran"
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: _splitInputAmount > 0
                      ? () {
                          // Validation: non-cash overpayment check
                          if (_splitCurrentType != PaymentType.cash &&
                              remaining > 0 &&
                              _splitInputAmount > remaining) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pembayaran non-tunai tidak boleh melebihi sisa tagihan.',
                                ),
                                backgroundColor: Color(0xFFDC2626),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          String? ref;
                          if (_splitCurrentType == PaymentType.debit ||
                              _splitCurrentType == PaymentType.transfer) {
                            final refText = _splitRefCodeController.text.trim();
                            if (refText.isNotEmpty) {
                              ref = '$_splitSelectedBank - $refText';
                            } else {
                              ref = _splitSelectedBank;
                            }
                          }

                          setState(() {
                            _splitPayments.add(
                              PaymentDetail(
                                type: _splitCurrentType,
                                amount: _splitInputAmount,
                                reference: ref,
                                timestamp: DateTime.now(),
                              ),
                            );
                            _splitRefCodeController.clear();
                            final newRem = _getSplitRemaining(grandTotal);
                            _splitInputAmount = newRem > 0 ? newRem : 0.0;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Tambahkan ${_getMethodTitle(_splitCurrentType)} (${_currencyFormatter.format(_splitInputAmount)})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    disabledForegroundColor: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSplitStat({
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color:
                valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitTenderOption(
    PaymentType type,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _splitCurrentType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _splitCurrentType = type;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSplitChip({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary
              ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : const Color(0xFFEFF6FF))
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary
                ? AppColors.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
            color: isPrimary
                ? (isDark ? const Color(0xFF93C5FD) : AppColors.primary)
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitBankSelector(bool isDark) {
    final banks = ['BCA', 'Mandiri', 'BRI', 'BNI', 'Lainnya'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: banks.map((bank) {
          final isSelected = _splitSelectedBank == bank;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => setState(() => _splitSelectedBank = bank),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                ),
                child: Text(
                  bank,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatK(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}jt';
    }
    if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 0)}rb';
    }
    return 'Rp ${amount.toInt()}';
  }

  String _getMethodTitle(PaymentType type) {
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

  IconData _getMethodIcon(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return Icons.payments_outlined;
      case PaymentType.qris:
        return Icons.qr_code_scanner_rounded;
      case PaymentType.debit:
        return Icons.credit_card_rounded;
      case PaymentType.transfer:
        return Icons.account_balance_rounded;
    }
  }

  Color _getMethodColor(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return const Color(0xFF10B981);
      case PaymentType.qris:
        return const Color(0xFF3B82F6);
      case PaymentType.debit:
        return const Color(0xFF8B5CF6);
      case PaymentType.transfer:
        return const Color(0xFFF59E0B);
    }
  }

  // QRIS Section
  Widget _buildQrisSection(double grandTotal, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: BlocBuilder<BusinessBloc, BusinessState>(
        builder: (context, bState) {
          final qrisUrl = bState.businessInfo?.qrisUrl;

          return Column(
            children: [
              Text(
                'Pindai Kode QRIS',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Dapat dipindai via GoPay, OVO, Dana, ShopeePay, BCA, dll.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Center(
                child: _buildQrisImageWidget(
                  qrisUrl: qrisUrl,
                  isDark: isDark,
                  size: 220,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  'Nominal: ${_currencyFormatter.format(grandTotal).trim()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.black,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQrisImageWidget({
    required String? qrisUrl,
    required bool isDark,
    double size = 180,
  }) {
    if (qrisUrl != null && qrisUrl.trim().isNotEmpty) {
      final cleanUrl = qrisUrl.trim();
      if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: cleanUrl,
            height: size,
            width: size,
            fit: BoxFit.contain,
            placeholder: (context, url) => SizedBox(
              height: size,
              width: size,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) =>
                _buildFallbackQrisPlaceholder(isDark, isError: true),
          ),
        );
      } else {
        try {
          final file = File(cleanUrl);
          if (file.existsSync()) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                file,
                height: size,
                width: size,
                fit: BoxFit.contain,
              ),
            );
          }
        } catch (_) {}
      }
    }

    return _buildFallbackQrisPlaceholder(isDark, isError: false);
  }

  Widget _buildFallbackQrisPlaceholder(bool isDark, {bool isError = false}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError ? Icons.broken_image_rounded : Icons.qr_code_2_rounded,
              size: 26,
              color: isError
                  ? const Color(0xFFEF4444)
                  : (isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isError
                ? 'Gagal Memuat Gambar QRIS'
                : 'Barcode QRIS Belum Diunggah',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isError
                ? 'Pastikan koneksi internet aktif atau unggah ulang gambar QRIS.'
                : 'Unggah foto barcode QRIS toko Anda agar muncul di sini saat pembayaran.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessInfoPage()),
              );
              if (mounted) {
                context.read<BusinessBloc>().add(LoadBusinessInfo());
              }
            },
            icon: const Icon(Icons.settings_outlined, size: 14),
            label: const Text(
              'Atur QRIS Toko',
              style: TextStyle(fontSize: 11.5),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebitSection(double grandTotal, bool isDark) {
    final banks = ['BCA', 'Mandiri', 'BRI', 'BNI', 'Lainnya'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Mesin EDC / Bank',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: banks.map((bank) {
                final isSelected = _selectedBank == bank;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedBank = bank),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                      ),
                      child: Text(
                        bank,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _refCodeController,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              labelText: 'Nomor Kartu / Approval Code (Opsional)',
              hintText: 'Contoh: 1234-5678-XXXX',
              labelStyle: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferSection(double grandTotal, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konfirmasi Transfer Bank',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nominal Transfer',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  _currencyFormatter.format(grandTotal).trim(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _refCodeController,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              labelText: 'Catatan / Nama Pengirim / Ref',
              hintText: 'Contoh: BCA Bpk. Aditya',
              labelStyle: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitches(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              SvgPicture.asset("assets/icons/printer.svg", height: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-print struk thermal',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      PrinterService().connectedDeviceName ??
                          'Cetak via Bluetooth 58mm',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _autoPrint,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => setState(() => _autoPrint = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              SvgPicture.asset("assets/icons/e-receipt.svg", height: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kirim struk WA',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Kirim link struk digital',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _sendWa,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => setState(() => _sendWa = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 6. Action Button (Selesaikan & Cetak Struk) (Flat, NO SHADOW)
  Widget _buildSubmitButton(double grandTotal) {
    final remaining = _getSplitRemaining(grandTotal);
    final bool canSubmit = _isSplitMode
        ? (_splitPayments.isNotEmpty && remaining <= 0)
        : ((_selectedType != PaymentType.cash) ||
              (_receivedAmount >= grandTotal));

    String buttonText;
    if (_isSplitMode) {
      if (_splitPayments.isEmpty) {
        buttonText = 'Tambahkan Pembayaran';
      } else if (remaining > 0) {
        buttonText = 'Sisa: ${_currencyFormatter.format(remaining)}';
      } else {
        buttonText = _autoPrint
            ? 'Selesaikan & Cetak Struk'
            : 'Selesaikan Pembayaran';
      }
    } else {
      buttonText = canSubmit
          ? (_autoPrint ? 'Selesaikan & Cetak Struk' : 'Selesaikan Pembayaran')
          : 'Uang Pembayaran Belum Cukup';
    }

    return InkWell(
      onTap: canSubmit ? () => _submitTransaction(grandTotal) : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: canSubmit ? AppColors.primary : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            buttonText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
