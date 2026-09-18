import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../main_page.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/transaction_service.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/entities/promo_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/customer/customer_bloc.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/promo/promo_bloc.dart';
import '../../blocs/report/report_bloc.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../customer/add_edit_customer_page.dart';
import 'widgets/payment_dialog.dart';
import 'widgets/transaction_success_dialog.dart';

class CheckoutPage extends StatefulWidget {
  final VoidCallback? onBackToKasir;
  final VoidCallback? onOpenDrawer;

  const CheckoutPage({super.key, this.onBackToKasir, this.onOpenDrawer});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final double _taxPercent = 10.0;
  PromoEntity? _selectedPromo;
  String _orderType = 'Dine In';
  final Map<String, String> _itemNotes = {};
  late final String _orderCode;
  late final String _orderTime;

  @override
  void initState() {
    super.initState();
    context.read<PromoBloc>().add(LoadPromos());
    final now = DateTime.now();
    final orderNum = (now.minute * 10 + now.second % 100).toString().padLeft(
      3,
      '0',
    );
    _orderCode = '#ORD-$orderNum';
    _orderTime = '${DateFormat('HH:mm').format(now)} WIB';
  }

  double get _discountAmount {
    if (_selectedPromo == null) return 0.0;
    final cartState = context.read<CartBloc>().state;
    if (cartState.totalAmount < _selectedPromo!.minPurchase) return 0.0;

    if (_selectedPromo!.type == PromoType.percentage) {
      return cartState.totalAmount * (_selectedPromo!.value / 100);
    } else {
      return _selectedPromo!.value;
    }
  }

  void _handleBackToKasir() {
    if (widget.onBackToKasir != null) {
      widget.onBackToKasir!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final canPopRoute = Navigator.canPop(context);

    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackToKasir();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Pesanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          ),
        ),
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<CartBloc, CartState>(
                  builder: (context, state) {
                    if (state.items.isEmpty) {
                      return _buildEmptyState();
                    }

                    final subtotal = state.totalAmount;
                    final discount = _discountAmount;
                    final taxAmount = (subtotal - discount > 0)
                        ? (subtotal - discount) * (_taxPercent / 100)
                        : 0.0;
                    final grandTotal = subtotal - discount + taxAmount;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                      children: [
                        // Card 1: Order Code & Service Type Segment
                        _buildOrderHeaderCard(),
                        const SizedBox(height: 12),

                        // Card 2: Customer Card
                        _buildCustomerCard(state.customer),
                        const SizedBox(height: 12),

                        // Card 3: Rincian Menu
                        _buildOrderItemsCard(state.items, currencyFormatter),
                        const SizedBox(height: 12),

                        // Card 4: Voucher / Promo Card
                        _buildPromoCard(currencyFormatter),
                        const SizedBox(height: 12),

                        // Card 5: Billing Summary Card
                        _buildSummaryCard(
                          subtotal: subtotal,
                          discount: discount,
                          tax: taxAmount,
                          grandTotal: grandTotal,
                          formatter: currencyFormatter,
                        ),
                        const SizedBox(height: 16),

                        // Card 6: Action Buttons (Payment & Secondary)
                        _buildActionButtons(
                          state: state,
                          grandTotal: grandTotal,
                          formatter: currencyFormatter,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Card 1: Order Number, Active Status, Timestamp & Service Segment (Flat, NO SHADOW)
  Widget _buildOrderHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _orderCode,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '• Aktif',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 4),
              Text(
                _orderTime,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segmented Service Type Toggle (Dine In / Take Away / Delivery)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildServiceSegment('Dine In'),
                _buildServiceSegment('Take Away'),
                _buildServiceSegment('Delivery'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSegment(String type) {
    final isSelected = _orderType == type;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _orderType = type),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: const Color(0xFFE2E8F0))
                : null,
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 3. Card 2: Customer Selector (Flat, NO SHADOW)
  Widget _buildCustomerCard(Customer? customer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          SvgPicture.asset("assets/icons/customer.svg", height: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        customer?.name ?? 'Pelanggan Umum',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        customer != null ? 'Gold' : 'Walk-in',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  customer?.phone ??
                      (customer != null
                          ? '120 Pts terkumpul'
                          : 'Tanpa Akun Member'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _showCustomerPicker(customer),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Text(
                    'Ganti',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Card 3: Rincian Menu (List Items with Trash, Stepper, & Notes)
  Widget _buildOrderItemsCard(
    List<TransactionItem> items,
    NumberFormat formatter,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rincian Menu (${items.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () => _confirmClearCart(context),
                child: const Text(
                  'Kosongkan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final hasNote = _itemNotes[item.productId]?.isNotEmpty == true;

            return Column(
              children: [
                if (index > 0)
                  const Divider(
                    height: 20,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line 1: Name & Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formatter.format(item.subtotal).trim(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Line 2: Note row (tap to edit note)
                      InkWell(
                        onTap: () => _showEditNoteDialog(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                hasNote
                                    ? Icons.notes_rounded
                                    : Icons.add_comment_outlined,
                                size: 14,
                                color: hasNote
                                    ? const Color(0xFF64748B)
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  hasNote
                                      ? _itemNotes[item.productId]!
                                      : 'Tambah Catatan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: hasNote
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    color: hasNote
                                        ? const Color(0xFF64748B)
                                        : AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Line 3: Unit Price, Trash Icon & Stepper
                      Row(
                        children: [
                          Text(
                            '@ ${formatter.format(item.price).trim()}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),

                          // Stepper Pill (- QTY +)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    context.read<CartBloc>().add(
                                      DecreaseQuantity(item.productId),
                                    );
                                  },
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(8),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 15,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 26,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    context.read<CartBloc>().add(
                                      IncrementQuantity(item.productId),
                                    );
                                  },
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(8),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 15,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // 5. Card 4: Voucher & Promo Card (Flat, NO SHADOW)
  Widget _buildPromoCard(NumberFormat formatter) {
    if (_selectedPromo != null) {
      final discountText = _selectedPromo!.type == PromoType.percentage
          ? '-${_selectedPromo!.value.toStringAsFixed(0)}% (Voucher Toko)'
          : '-${formatter.format(_selectedPromo!.value).trim()} (Voucher Toko)';

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _selectedPromo!.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Terpasang',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    discountText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
              onPressed: () => setState(() => _selectedPromo = null),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: _showPromoPicker,
        child: Row(
          children: [
            SvgPicture.asset("assets/icons/discount.svg", height: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Gunakan Voucher / Promo',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Text(
              'Pilih',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  // 6. Card 5: Summary Card (Subtotal, Discount, PB1 Resto, Grand Total)
  Widget _buildSummaryCard({
    required double subtotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required NumberFormat formatter,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', formatter.format(subtotal).trim()),
          if (discount > 0)
            _buildSummaryRow(
              'Diskon Promo',
              '-${formatter.format(discount).trim()}',
              isDiscount: true,
            ),
          _buildSummaryRow(
            'PB1 Resto (${_taxPercent.toStringAsFixed(0)}%)',
            formatter.format(tax).trim(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grand Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Termasuk pajak & layanan',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              Text(
                formatter.format(grandTotal).trim(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDiscount ? AppColors.primary : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Action Buttons (Primary Payment & Secondary Kitchen/Hold Bill)
  Widget _buildActionButtons({
    required CartState state,
    required double grandTotal,
    required NumberFormat formatter,
  }) {
    return Column(
      children: [
        // Primary Button: Pilih Pembayaran (Flat, NO SHADOW)
        InkWell(
          onTap: () => _showPaymentDialog(context, state),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Pilih Pembayaran',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  formatter.format(grandTotal).trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleHoldOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bill order $_orderCode berhasil disimpan sebagai pending bill.',
        ),
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/icons/order.svg", height: 64),
            const SizedBox(height: 16),
            const Text(
              'Belum ada pesanan aktif',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih menu dari tab Kasir untuk mulai transaksi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _handleBackToKasir,
              child: const Text("Kembali ke kasir"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNoteDialog(TransactionItem item) {
    final controller = TextEditingController(
      text: _itemNotes[item.productId] ?? '',
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Catatan: ${item.productName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Contoh: Less Ice, Oatmilk, Hangatkan...',
            border: OutlineInputBorder(),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              setState(() {
                if (controller.text.trim().isEmpty) {
                  _itemNotes.remove(item.productId);
                } else {
                  _itemNotes[item.productId] = controller.text.trim();
                }
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kosongkan Keranjang?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Semua menu yang sudah dipilih akan dihapus dari daftar pesanan ini.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              context.read<CartBloc>().add(ClearCart());
              setState(() {
                _selectedPromo = null;
                _itemNotes.clear();
              });
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Kosongkan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentDialog(
    BuildContext context,
    CartState cartState,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (pageContext) => BlocProvider(
          create: (_) => PaymentBloc(),
          child: PaymentDialog(
            orderCode: _orderCode,
            orderType: _orderType,
            itemCount: cartState.items.length,
            subtotal: cartState.totalAmount,
            taxPercent: _taxPercent,
            discountAmount: _discountAmount,
            customer: cartState.customer,
            onHoldOrder: () {
              Navigator.pop(pageContext);
              _handleHoldOrder();
            },
            onAddDiscount: () {
              Navigator.pop(pageContext);
              _showPromoPicker();
            },
            onConfirm: (payments, changeAmount, shouldPrint, shouldSendWA) {
              Navigator.pop(pageContext);
              _processPayment(
                cartState,
                payments,
                changeAmount,
                shouldPrint: shouldPrint,
                shouldSendWA: shouldSendWA,
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(
    CartState cartState,
    List<PaymentDetail> payments,
    double changeAmount, {
    bool shouldPrint = true,
    bool shouldSendWA = false,
  }) async {
    final businessInfo = context.read<BusinessBloc>().state.businessInfo;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );

      final now = DateTime.now();
      final transactionCode = 'INV-${DateFormat('yyyyMMddHHmmss').format(now)}';
      final taxAmount = (cartState.totalAmount - _discountAmount > 0)
          ? (cartState.totalAmount - _discountAmount) * (_taxPercent / 100)
          : 0.0;
      final grandTotal = cartState.totalAmount + taxAmount - _discountAmount;

      final sessionService = getIt<SessionService>();
      final businessId = sessionService.businessId;
      final userId = sessionService.currentUser?.id ?? 'unknown';

      final items = cartState.items.map((cartItem) {
        return TransactionItem(
          id: const Uuid().v4(),
          productId: cartItem.productId,
          productName: cartItem.productName,
          quantity: cartItem.quantity,
          price: cartItem.price,
          discount: 0,
          subtotal: cartItem.price * cartItem.quantity,
          costPrice: cartItem.costPrice,
          businessId: businessId,
        );
      }).toList();

      final transaction = TransactionEntity(
        id: const Uuid().v4(),
        transactionCode: transactionCode,
        customerId: cartState.customer?.id,
        customerName: cartState.customer?.name,
        subtotal: cartState.totalAmount,
        taxAmount: taxAmount,
        discountAmount: _discountAmount,
        totalAmount: grandTotal,
        payments: payments,
        paymentStatus: PaymentStatus.paid,
        status: TransactionStatus.completed,
        amountPaid: payments.fold(0, (sum, p) => sum + p.amount),
        changeAmount: changeAmount,
        createdAt: now,
        completedAt: now,
        items: items,
        createdBy: userId,
        businessId: businessId,
      );

      final transactionService = getIt<TransactionService>();
      await transactionService.processTransaction(transaction);
      getIt<SyncService>().fullSync();

      if (mounted) {
        context.read<TransactionBloc>().add(LoadTransactions());
        context.read<ReportBloc>().add(LoadDailyReport(DateTime.now()));
        context.read<ProductBloc>().add(LoadProducts());
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      AppToast.showSuccess(context, 'Transaksi berhasil!');

      final printerService = PrinterService();
      if (shouldPrint && printerService.isConnected) {
        await printerService.printReceipt(
          transaction: transaction,
          businessInfo: businessInfo,
        );
      }

      if (shouldSendWA) {
        final customerPhone = cartState.customer?.phone;
        await WhatsappService.shareReceipt(
          transaction: transaction,
          businessInfo: businessInfo,
          phoneNumber: customerPhone,
        );
      }

      if (!mounted) return;
      context.read<CartBloc>().add(ClearCart());
      setState(() {
        _selectedPromo = null;
        _itemNotes.clear();
      });

      if (!mounted) return;
      await _showSuccessDialog(context, transaction);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      AppToast.showError(context, 'Gagal memproses transaksi: $e');
    }
  }

  Future<void> _showSuccessDialog(
    BuildContext context,
    TransactionEntity transaction,
  ) async {
    final businessState = context.read<BusinessBloc>().state;
    final businessInfo = businessState.businessInfo;
    final cartState = context.read<CartBloc>().state;
    final customerPhone = cartState.customer?.phone;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => TransactionSuccessDialog(
        transaction: transaction,
        businessInfo: businessInfo,
        customerPhone: customerPhone,
        onNewTransaction: () {
          Navigator.pop(dialogContext);
          if (widget.onBackToKasir != null) {
            widget.onBackToKasir!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        onBackToKasir: () {
          Navigator.pop(dialogContext);
          if (widget.onBackToKasir != null) {
            widget.onBackToKasir!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showCustomerPicker(Customer? currentCustomer) {
    context.read<CustomerBloc>().add(LoadCustomers());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (contextSheet) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (contextSheet, scrollController) {
          final searchCtrl = TextEditingController();
          return StatefulBuilder(
            builder: (contextSheet, setStateSheet) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pilih Pelanggan',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(contextSheet);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddEditCustomerPage(),
                                ),
                              );
                            },
                            child: const Icon(Icons.person_add_alt_1),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (_) => setStateSheet(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau telepon...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: BlocBuilder<CustomerBloc, CustomerState>(
                        builder: (context, state) {
                          final query = searchCtrl.text.toLowerCase();
                          final filtered = state.customers.where((c) {
                            return c.name.toLowerCase().contains(query) ||
                                (c.phone?.contains(query) ?? false);
                          }).toList();

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: filtered.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFF1F5F9),
                                    child: Icon(
                                      Icons.people_alt_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  title: const Text('Pelanggan Umum / Walk-in'),
                                  trailing: currentCustomer == null
                                      ? const Icon(
                                          Icons.check,
                                          color: AppColors.primary,
                                        )
                                      : null,
                                  onTap: () {
                                    context.read<CartBloc>().add(
                                      SetCartCustomer(null),
                                    );
                                    Navigator.pop(contextSheet);
                                  },
                                );
                              }

                              final customer = filtered[index - 1];
                              final isSelected =
                                  currentCustomer?.id == customer.id;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    customer.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  customer.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(customer.phone ?? '-'),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.primary,
                                      )
                                    : null,
                                onTap: () {
                                  context.read<CartBloc>().add(
                                    SetCartCustomer(customer),
                                  );
                                  Navigator.pop(contextSheet);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPromoPicker() {
    context.read<PromoBloc>().add(LoadPromos());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (sheetContext, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Pilih Voucher Promo',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<PromoBloc, PromoState>(
                      builder: (context, state) {
                        if (state.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }

                        final now = DateTime.now();
                        final activePromos = state.promos.where((p) {
                          if (!p.isActive) return false;
                          if (p.startDate != null) {
                            final startDay = DateTime(
                              p.startDate!.year,
                              p.startDate!.month,
                              p.startDate!.day,
                            );
                            if (now.isBefore(startDay)) return false;
                          }
                          if (p.endDate != null) {
                            final endDay = DateTime(
                              p.endDate!.year,
                              p.endDate!.month,
                              p.endDate!.day,
                              23,
                              59,
                              59,
                            );
                            if (now.isAfter(endDay)) return false;
                          }
                          return true;
                        }).toList();

                        if (activePromos.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.confirmation_number_outlined,
                                      size: 32,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Tidak ada promo aktif saat ini',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Buat promo baru melalui menu Promo untuk memberikan diskon transaksi.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final cartTotal = context
                            .read<CartBloc>()
                            .state
                            .totalAmount;

                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: activePromos.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final promo = activePromos[index];
                            final bool isDisabled =
                                cartTotal < promo.minPurchase;

                            return InkWell(
                              onTap: isDisabled
                                  ? null
                                  : () {
                                      setState(() => _selectedPromo = promo);
                                      Navigator.pop(modalContext);
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDisabled
                                      ? const Color(0xFFF8FAFC)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDisabled
                                        ? const Color(0xFFE2E8F0)
                                        : AppColors.primary,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.confirmation_number_outlined,
                                      color: isDisabled
                                          ? const Color(0xFF94A3B8)
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            promo.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isDisabled
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            promo.minPurchase > 0
                                                ? 'Min. Belanja: Rp ${NumberFormat('#,###', 'id_ID').format(promo.minPurchase)}'
                                                : 'Tanpa minimum belanja',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDisabled
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isDisabled)
                                      const Text(
                                        'Belum Cukup',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFDC2626),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.primary,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
