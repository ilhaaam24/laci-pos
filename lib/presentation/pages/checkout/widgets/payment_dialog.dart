import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/printer_service.dart';
import '../../../../core/style/app_colors.dart';
import '../../../../domain/entities/customer_entity.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/business/business_bloc.dart';
import '../../../blocs/payment/payment_bloc.dart';
import '../../../blocs/payment/payment_event.dart';
import '../../../blocs/payment/payment_state.dart';

class PaymentDialog extends StatefulWidget {
  final String orderCode;
  final String orderType;
  final int itemCount;
  final double subtotal;
  final double taxPercent;
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

  @override
  void initState() {
    super.initState();
    _autoPrint = PrinterService().isConnected;
    _sendWa = widget.customer?.phone?.isNotEmpty == true;

    context.read<PaymentBloc>().add(
      CalculatePayment(
        subtotal: widget.subtotal,
        taxPercent: widget.taxPercent,
        discountAmount: widget.discountAmount,
      ),
    );

    final total = _calculateGrandTotal();
    _receivedAmount = _getInitialReceivedAmount(total);
  }

  @override
  void dispose() {
    _refCodeController.dispose();
    super.dispose();
  }

  double _calculateGrandTotal() {
    final tax = (widget.subtotal - widget.discountAmount > 0)
        ? (widget.subtotal - widget.discountAmount) * (widget.taxPercent / 100)
        : 0.0;
    return widget.subtotal - widget.discountAmount + tax;
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

  void _showNumericKeypad(double total) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        String inputStr = _receivedAmount > 0
            ? _receivedAmount.toInt().toString()
            : '';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void appendDigit(String digit) {
              setSheetState(() {
                if (inputStr == '0') inputStr = '';
                if (digit == '000') {
                  if (inputStr.isNotEmpty) inputStr += '000';
                } else {
                  inputStr += digit;
                }
              });
              setState(() {
                _receivedAmount = double.tryParse(inputStr) ?? 0;
              });
            }

            void deleteDigit() {
              setSheetState(() {
                if (inputStr.isNotEmpty) {
                  inputStr = inputStr.substring(0, inputStr.length - 1);
                }
              });
              setState(() {
                _receivedAmount = double.tryParse(inputStr) ?? 0;
              });
            }

            void clearAll() {
              setSheetState(() => inputStr = '');
              setState(() => _receivedAmount = 0);
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
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Input Nominal Pembayaran',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
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
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Rp ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _currencyFormatter
                                  .format(displayVal)
                                  .replaceAll('Rp', '')
                                  .trim(),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.backspace_outlined,
                              size: 20,
                              color: Color(0xFF475569),
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
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  digit,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
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

    if (_selectedType == PaymentType.cash) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            final grandTotal = _calculateGrandTotal();
            final changeAmount = (_receivedAmount >= grandTotal)
                ? _receivedAmount - grandTotal
                : 0.0;

            return Column(
              children: [
                _buildTopAppBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      // 1. Order Info Card
                      _buildOrderInfoCard(),
                      const SizedBox(height: 16),

                      // 2. Total Tagihan Section
                      _buildTotalTagihan(grandTotal),
                      const SizedBox(height: 18),

                      // 3. Payment Method Pills
                      _buildPaymentMethodSelector(),
                      const SizedBox(height: 18),

                      // 4. Content based on selected payment method
                      if (_selectedType == PaymentType.cash) ...[
                        _buildCashPaymentSection(grandTotal, changeAmount),
                      ] else if (_selectedType == PaymentType.qris) ...[
                        _buildQrisSection(grandTotal),
                      ] else if (_selectedType == PaymentType.debit) ...[
                        _buildDebitSection(grandTotal),
                      ] else if (_selectedType == PaymentType.transfer) ...[
                        _buildTransferSection(grandTotal),
                      ],

                      const SizedBox(height: 16),

                      // 5. Setting Switches (Thermal Print & Send WA)
                      _buildSettingSwitches(),
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
  Widget _buildTopAppBar() {
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
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF0F172A),
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              // Container(
              //   width: 36,
              //   height: 36,
              //   decoration: BoxDecoration(
              //     color: AppColors.primary,
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: const Center(
              //     child: Icon(
              //       Icons.point_of_sale_rounded,
              //       color: Colors.white,
              //       size: 20,
              //     ),
              //   ),
              // ),
              if (businessLogo.isNotEmpty)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFF64748B),
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
                  const Text(
                    'Pembayaran',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    businessName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              const Spacer(),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is Authenticated && state.user.photoUrl != null) {
                    return CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFF004D40),
                      backgroundImage: NetworkImage(state.user.photoUrl!),
                    );
                  }
                  return const CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xFF004D40),
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // 1. Order Info Card: Order #KS-0842 • 3 Menu | • Kasir Aktif (Flat, NO SHADOW)
  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          SvgPicture.asset("assets/icons/e-receipt.svg", height: 36, width: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Order ${widget.orderCode} • ${widget.itemCount} Menu',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '• Kasir Aktif',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Total Tagihan Section: TOTAL TAGIHAN, Rp 70.400, Store Icon + Dine-in • Meja 04
  Widget _buildTotalTagihan(double grandTotal) {
    final formatted = _currencyFormatter
        .format(grandTotal)
        .replaceAll('Rp', '')
        .trim();

    return Column(
      children: [
        const Text(
          'TOTAL TAGIHAN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'Rp ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              formatted,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                '${widget.orderType} • Meja 04',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Payment Method Pills: Tunai, QRIS, Debit EDC, Transfer (Flat, NO SHADOW)
  Widget _buildPaymentMethodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMethodPill(
            type: PaymentType.cash,
            label: 'Tunai',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(width: 8),
          _buildMethodPill(
            type: PaymentType.qris,
            label: 'QRIS',
            icon: Icons.qr_code_scanner_rounded,
          ),
          const SizedBox(width: 8),
          _buildMethodPill(
            type: PaymentType.debit,
            label: 'Debit EDC',
            icon: Icons.point_of_sale_outlined,
          ),
          const SizedBox(width: 8),
          _buildMethodPill(
            type: PaymentType.transfer,
            label: 'Transfer Bank',
            icon: Icons.account_balance_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodPill({
    required PaymentType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Cash Payment Section: Uang Diterima, Quick Amounts, & Kembalian Kasir Card
  Widget _buildCashPaymentSection(double grandTotal, double changeAmount) {
    final quickAmounts = _generateQuickAmounts(grandTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Uang Diterima Header & Input Display Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Uang Diterima',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _showNumericKeypad(grandTotal),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Rp ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _currencyFormatter
                              .format(_receivedAmount)
                              .replaceAll('Rp', '')
                              .trim(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _onBackspaceAmount,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Icon(
                            Icons.backspace_outlined,
                            size: 18,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xFFE2E8F0),
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
                                          : const Color(0xFF64748B)),
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
                                            : const Color(0xFF64748B)),
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.transparent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset("assets/icons/sync.svg", height: 22),
                  const SizedBox(width: 6),
                  const Text(
                    'KEMBALIAN KASIR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF065F46),
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
                      color: AppColors.black,
                    ),
                  ),
                  Text(
                    _currencyFormatter
                        .format(changeAmount)
                        .replaceAll('Rp', '')
                        .trim(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF042F2C),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Pastikan hitung uang kembalian sebelum menyerahkan ke pelanggan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // QRIS Section
  Widget _buildQrisSection(double grandTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: BlocBuilder<BusinessBloc, BusinessState>(
        builder: (context, bState) {
          final qrisUrl = bState.businessInfo?.qrisUrl;

          return Column(
            children: [
              const Text(
                'Pindai Kode QRIS',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dapat dipindai via GoPay, OVO, Dana, ShopeePay, BCA, dll.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              if (qrisUrl != null && qrisUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: qrisUrl,
                  height: 240,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    height: 240,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      _buildFallbackQrisPlaceholder(),
                )
              else
                _buildFallbackQrisPlaceholder(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                child: Text(
                  'Nominal: ${_currencyFormatter.format(grandTotal).trim()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFallbackQrisPlaceholder() {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 90, color: Color(0xFF1E293B)),
          SizedBox(height: 4),
          Text(
            'QRIS Standar POS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // Debit EDC Section
  Widget _buildDebitSection(double grandTotal) {
    final banks = ['BCA', 'Mandiri', 'BRI', 'BNI', 'Lainnya'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Mesin EDC / Bank',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
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
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? null
                            : Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        bank,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF334155),
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
            decoration: InputDecoration(
              labelText: 'Nomor Kartu / Approval Code (Opsional)',
              hintText: 'Contoh: 1234-5678-XXXX',
              labelStyle: const TextStyle(fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Transfer Bank Section
  Widget _buildTransferSection(double grandTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfirmasi Transfer Bank',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nominal Transfer',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
            decoration: InputDecoration(
              labelText: 'Catatan / Nama Pengirim / Ref',
              hintText: 'Contoh: BCA Bpk. Aditya',
              labelStyle: const TextStyle(fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Setting Switches (Auto-print struk thermal & Kirim struk WA)
  Widget _buildSettingSwitches() {
    return Column(
      children: [
        // Switch 1: Thermal Print
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              SvgPicture.asset("assets/icons/printer.svg", height: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Auto-print struk thermal',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      PrinterService().connectedDeviceName ??
                          'Cetak via Bluetooth 58mm',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
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

        // Switch 2: Kirim Struk WA
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              SvgPicture.asset("assets/icons/e-receipt.svg", height: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kirim struk WA',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Kirim link struk digital',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
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
    final bool canSubmit =
        (_selectedType != PaymentType.cash) || (_receivedAmount >= grandTotal);

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              canSubmit
                  ? (_autoPrint
                        ? 'Selesaikan & Cetak Struk'
                        : 'Selesaikan Pembayaran')
                  : 'Uang Pembayaran Belum Cukup',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
