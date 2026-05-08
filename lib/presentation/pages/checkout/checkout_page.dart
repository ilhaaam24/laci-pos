import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laci/core/services/session_service.dart';
import 'package:laci/core/services/sync_service.dart';
import 'package:laci/presentation/blocs/customer/customer_bloc.dart';
import 'package:laci/presentation/pages/promo/promo_page.dart';
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
import '../../blocs/promo/promo_bloc.dart';
import '../../../domain/entities/promo_entity.dart';
import 'widgets/payment_dialog.dart';
import '../../blocs/business/business_bloc.dart';
import '../../../core/services/printer_service.dart';
import '../customer/add_edit_customer_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final double _taxPercent = 10.0;
  PromoEntity? _selectedPromo;
  final TextEditingController _customerSearchController =
      TextEditingController();

  @override
  void dispose() {
    _customerSearchController.dispose();
    super.dispose();
  }

  double get _discountAmount {
    if (_selectedPromo == null) return 0.0;

    // Check min purchase
    final cartState = context.read<CartBloc>().state;
    if (cartState.totalAmount < _selectedPromo!.minPurchase) return 0.0;

    if (_selectedPromo!.type == PromoType.percentage) {
      return cartState.totalAmount * (_selectedPromo!.value / 100);
    } else {
      return _selectedPromo!.value;
    }
  }

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
              _buildPromoSelector(),
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
              SizedBox(height: 24),
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
            _processPayment(cartState, paymentMethod, amountPaid, changeAmount);
          },
        ),
      ),
    );
  }

  Future<void> _processPayment(
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
        paymentMethod: paymentMethod,
        paymentStatus: PaymentStatus.paid,
        status: TransactionStatus.completed,
        amountPaid: amountPaid,
        changeAmount: changeAmount,
        createdAt: now,
        completedAt: now,
        items: items,
        createdBy: userId,
        businessId: businessId,
      );

      // Process transaction with stock update
      final transactionService = getIt<TransactionService>();
      await transactionService.processTransaction(transaction);

      // Trigger background sync to push changes to Firebase immediately
      getIt<SyncService>().fullSync();

      // Close loading
      if (!mounted) return;
      Navigator.pop(context);

      // Show success with AppToast
      AppToast.showSuccess(context, 'Transaksi berhasil!');

      // Print Receipt if printer is connected
      final printerService = PrinterService();
      if (printerService.isConnected) {
        final businessState = context.read<BusinessBloc>().state;
        await printerService.printReceipt(
          transaction: transaction,
          businessInfo: businessState.businessInfo,
        );
      }

      if (!mounted) return;

      // Clear cart
      context.read<CartBloc>().add(ClearCart());

      // Navigate back to Kasir
      Navigator.pop(context);
    } catch (e) {
      // Close loading
      if (!mounted) return;
      Navigator.pop(context);

      // Show error with AppToast
      AppToast.showError(context, 'Gagal memproses transaksi: $e');
    }
  }

  Widget _buildCustomerSelector() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final customer = state.customer;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: customer == null ? Colors.grey : Colors.teal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?.name ?? 'Pilih Pelanggan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: customer == null
                            ? Colors.grey
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (customer != null)
                      Text(
                        customer.phone ?? 'Tanpa nomor telepon',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (customer != null)
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.error,
                  ),
                  onPressed: () =>
                      context.read<CartBloc>().add(SetCartCustomer(null)),
                ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                onPressed: () => _showCustomerPicker(customer),
                child: Text(customer == null ? 'PILIH' : 'GANTI'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomerPicker(Customer? currentCustomer) {
    context.read<CustomerBloc>().add(LoadCustomers());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (contextSheet) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (contextSheet, scrollController) {
          return StatefulBuilder(
            builder: (contextSheet, setStateSheet) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 10, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pilih Pelanggan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                contextSheet,
                                MaterialPageRoute(
                                  builder: (_) => const AddEditCustomerPage(),
                                ),
                              );
                              // Refresh customers after adding
                              if (context.mounted) {
                                context.read<CustomerBloc>().add(
                                  LoadCustomers(),
                                );
                              }
                            },
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: const Text('Tambah Baru'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: TextField(
                        onChanged: (value) => setStateSheet(() {}),
                        controller: _customerSearchController,
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau telepon...',
                          prefixIcon: const Icon(Icons.search),
                          fillColor: AppColors.surface,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: BlocBuilder<CustomerBloc, CustomerState>(
                        builder: (context, state) {
                          if (state.isLoading && state.customers.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final query = _customerSearchController.text
                              .toLowerCase();
                          final filteredCustomers = state.customers.where((c) {
                            return c.name.toLowerCase().contains(query) ||
                                (c.phone?.contains(query) ?? false);
                          }).toList();

                          if (filteredCustomers.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_search_outlined,
                                    size: 64,
                                    color: AppColors.textDisabled.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Tidak ada pelanggan ditemukan',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              final isSelected =
                                  currentCustomer?.id == customer.id;

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.divider,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? AppColors.primary
                                        : AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                    child: Text(
                                      customer.name
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    customer.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    customer.phone ?? 'Tanpa nomor telepon',
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                        )
                                      : null,
                                  onTap: () {
                                    context.read<CartBloc>().add(
                                      SetCartCustomer(customer),
                                    );
                                    Navigator.pop(contextSheet);
                                  },
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
            color: AppColors.textDisabled.withValues(alpha: 0.2),
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
                borderRadius: BorderRadius.circular(100),
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
                    IncrementQuantity(item.productId),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            child: TextButton(
              onPressed: () => _showPaymentDialog(context, state),
              style: ButtonStyle(),
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

  Widget _buildPromoSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            color: _selectedPromo == null ? Colors.grey : Colors.pinkAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPromo?.name ?? 'Gunakan Promo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedPromo == null
                        ? Colors.grey
                        : AppColors.textPrimary,
                  ),
                ),
                if (_selectedPromo != null)
                  Text(
                    _selectedPromo!.type == PromoType.percentage
                        ? 'Diskon ${_selectedPromo!.value.toStringAsFixed(0)}%'
                        : 'Potongan Rp ${NumberFormat('#,###', 'id_ID').format(_selectedPromo!.value)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedPromo != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.error),
              onPressed: () => setState(() => _selectedPromo = null),
            ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            onPressed: () => _showPromoPicker(),
            child: Text(_selectedPromo == null ? 'PILIH' : 'GANTI'),
          ),
        ],
      ),
    );
  }

  void _showPromoPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        context.read<PromoBloc>().add(LoadPromos());
        return DraggableScrollableSheet(
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
                    'Pilih Promo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<PromoBloc, PromoState>(
                    builder: (context, state) {
                      final activePromos = state.promos.where((p) {
                        final now = DateTime.now();
                        final isNotFuture =
                            p.startDate == null || p.startDate!.isBefore(now);
                        final isNotExpired =
                            p.endDate == null || p.endDate!.isAfter(now);
                        return p.isActive && isNotFuture && isNotExpired;
                      }).toList();

                      if (state.isLoading && state.promos.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (activePromos.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Tidak ada promo aktif'),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(context); // Close picker
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PromoPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Kelola Promo'),
                              ),
                            ],
                          ),
                        );
                      }

                      final cartTotal = context
                          .read<CartBloc>()
                          .state
                          .totalAmount;

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: activePromos.length,
                        itemBuilder: (context, index) {
                          final promo = activePromos[index];
                          final bool isDisabled = cartTotal < promo.minPurchase;

                          return ListTile(
                            leading: Icon(
                              Icons.confirmation_number_outlined,
                              color: isDisabled
                                  ? Colors.grey
                                  : Colors.pinkAccent,
                            ),
                            title: Text(
                              promo.name,
                              style: TextStyle(
                                decoration: isDisabled
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isDisabled ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Text(
                              promo.minPurchase > 0
                                  ? 'Min. Belanja: Rp ${NumberFormat('#,###', 'id_ID').format(promo.minPurchase)}'
                                  : 'Tanpa minimum belanja',
                              style: TextStyle(
                                color: isDisabled
                                    ? AppColors.error.withValues(alpha: 0.5)
                                    : null,
                              ),
                            ),
                            trailing: isDisabled
                                ? const Text(
                                    'Belum cukup',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.error,
                                    ),
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: isDisabled
                                ? null
                                : () {
                                    setState(() => _selectedPromo = promo);
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
        );
      },
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
