import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laci/presentation/blocs/customer/customer_bloc.dart';
import '../../../domain/entities/customer_entity.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../core/services/transaction_service.dart';
import '../../../core/di/injection.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import 'widgets/payment_dialog.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final double _taxPercent = 10.0;
  final double _discountAmount = 0.0;
  Customer? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => context.read<CartBloc>().add(ClearCart()),
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildCustomerSelector(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _buildCartItem(context, item, currencyFormatter);
                  },
                ),
              ),
              _buildOrderSummary(context, state, currencyFormatter),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showPaymentDialog(
    BuildContext context,
    CartState cartState,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) => PaymentBloc(),
        child: PaymentDialog(
          subtotal: cartState.totalAmount,
          taxPercent: _taxPercent,
          discountAmount: _discountAmount,
          onConfirm: (paymentMethod, amountPaid, changeAmount) {
            _processPayment(
              context,
              cartState,
              paymentMethod,
              amountPaid,
              changeAmount,
            );
          },
        ),
      ),
    );
  }

  Future<void> _processPayment(
    BuildContext context,
    CartState cartState,
    String paymentMethod,
    double amountPaid,
    double changeAmount,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final now = DateTime.now();
      final transactionCode = 'INV-${DateFormat('yyyyMMddHHmmss').format(now)}';

      final taxAmount = cartState.totalAmount * (_taxPercent / 100);
      final grandTotal = cartState.totalAmount + taxAmount - _discountAmount;

      final items = cartState.items.map((cartItem) {
        return TransactionItem(
          id: const Uuid().v4(),
          productId: cartItem.productId,
          productName: cartItem.productName,
          quantity: cartItem.quantity,
          price: cartItem.price,
          discount: 0,
          subtotal: cartItem.price * cartItem.quantity,
        );
      }).toList();

      final transaction = TransactionEntity(
        id: const Uuid().v4(),
        transactionCode: transactionCode,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
        subtotal: cartState.totalAmount,
        taxAmount: taxAmount,
        discountAmount: _discountAmount,
        totalAmount: grandTotal,
        paymentMethod: paymentMethod,
        paymentStatus: PaymentStatus.paid,
        status: TransactionStatus.completed,
        amountPaid: amountPaid,
        changeAmount: changeAmount,
        createdAt: now,
        completedAt: now,
        items: items,
        createdBy: 'admin',
      );

      // Process transaction with stock update
      final transactionService = getIt<TransactionService>();
      await transactionService.processTransaction(transaction);

      // Close loading
      if (mounted) Navigator.pop(context);

      // Show success with AppToast
      if (mounted) {
        AppToast.showSuccess(context, 'Transaksi berhasil!');
      }

      // Clear cart
      if (mounted) context.read<CartBloc>().add(ClearCart());

      // Navigate back to Kasir
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      // Show error with AppToast
      if (mounted) {
        AppToast.showError(context, 'Gagal memproses transaksi: $e');
      }
    }
  }

  Widget _buildCustomerSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: _selectedCustomer == null ? Colors.grey : Colors.teal,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCustomer?.name ?? 'Pilih Pelanggan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedCustomer == null
                        ? Colors.grey
                        : AppColors.textPrimary,
                  ),
                ),
                if (_selectedCustomer != null)
                  Text(
                    _selectedCustomer?.phone ?? 'Tanpa nomor telepon',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedCustomer != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.error),
              onPressed: () => setState(() => _selectedCustomer = null),
            ),
          TextButton(
            onPressed: () => _showCustomerPicker(),
            child: Text(_selectedCustomer == null ? 'PILIH' : 'GANTI'),
          ),
        ],
      ),
    );
  }

  void _showCustomerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Pilih Pelanggan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: BlocBuilder<CustomerBloc, CustomerState>(
                  builder: (context, state) {
                    if (state.isLoading && state.customers.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.customers.isEmpty) {
                      return const Center(child: Text('Belum ada pelanggan'));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: state.customers.length,
                      itemBuilder: (context, index) {
                        final customer = state.customers[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(customer.name),
                          subtitle: Text(customer.phone ?? ''),
                          onTap: () {
                            setState(() => _selectedCustomer = customer);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppColors.textDisabled.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keranjang belanja kosong',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    dynamic item,
    NumberFormat formatter,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fastfood_outlined,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${formatter.format(item.price)} x ${item.quantity}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _buildQtyButton(
                  icon: Icons.remove,
                  onTap: () => context.read<CartBloc>().add(
                    DecreaseQuantity(item.productId),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildQtyButton(
                  icon: Icons.add,
                  onTap: () => context.read<CartBloc>().add(
                    DecreaseQuantity(item.productId),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: () => context.read<CartBloc>().add(
                    RemoveFromCart(item.productId),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildOrderSummary(
    BuildContext context,
    CartState state,
    NumberFormat formatter,
  ) {
    final taxAmount = state.totalAmount * (_taxPercent / 100);
    final grandTotal = state.totalAmount + taxAmount - _discountAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', formatter.format(state.totalAmount)),
          _buildSummaryRow(
            'Pajak ($_taxPercent%)',
            formatter.format(taxAmount),
          ),
          if (_discountAmount > 0)
            _buildSummaryRow(
              'Diskon',
              '- ${formatter.format(_discountAmount)}',
              isDiscount: true,
            ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            formatter.format(grandTotal),
            isTotal: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _showPaymentDialog(context, state),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'BAYAR SEKARANG',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isDiscount
                  ? Colors.green
                  : isTotal
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
