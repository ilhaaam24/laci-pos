import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/held_order_service.dart';
import '../../../../core/services/printer_service.dart';
import '../../../../core/style/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../domain/entities/held_order_entity.dart';
import '../../../blocs/business/business_bloc.dart';
import '../../../blocs/cart/cart_bloc.dart';

class HeldOrdersSheet extends StatefulWidget {
  final String cashierName;

  const HeldOrdersSheet({super.key, required this.cashierName});

  static Future<void> show({
    required BuildContext context,
    required String cashierName,
  }) {
    final isTablet = MediaQuery.of(context).size.width >= 720;
    if (isTablet) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 30,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: HeldOrdersSheet(cashierName: cashierName),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: HeldOrdersSheet(cashierName: cashierName),
        ),
      ),
    );
  }

  @override
  State<HeldOrdersSheet> createState() => _HeldOrdersSheetState();
}

class _HeldOrdersSheetState extends State<HeldOrdersSheet> {
  final HeldOrderService _heldOrderService = HeldOrderService();
  String? _printingOrderId;

  String _formatElapsedTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return DateFormat('dd/MM HH:mm').format(dt);
    }
  }

  Future<void> _recallOrder(HeldOrder order) async {
    final cartBloc = context.read<CartBloc>();
    final currentCart = cartBloc.state;

    // If current cart has items, handle switching safely
    if (currentCart.items.isNotEmpty) {
      final shouldProceed = await showDialog<String>(
        context: context,
        builder: (dialogCtx) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Text(
                  'Keranjang Masih Ada Item',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            content: const Text(
              'Keranjang kasir saat ini tidak kosong. Bagaimana Anda ingin memprosesnya?',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, 'cancel'),
                child: const Text('Batal'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogCtx, 'overwrite'),
                child: const Text('Ganti & Timpa'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, 'hold_current'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tahan Keranjang Ini Dulu'),
              ),
            ],
          );
        },
      );

      if (shouldProceed == null || shouldProceed == 'cancel') {
        return;
      }

      if (shouldProceed == 'hold_current') {
        // Automatically hold the current active cart first
        final autoName =
            currentCart.orderName ??
            (currentCart.customer?.name != null
                ? 'Meja ${currentCart.customer!.name}'
                : 'Pesanan #${DateFormat('HH:mm').format(DateTime.now())}');

        final newHeldOrder = HeldOrder(
          id: currentCart.heldOrderId ?? const Uuid().v4(),
          orderName: autoName,
          customerName: currentCart.customer?.name,
          customer: currentCart.customer,
          items: currentCart.items,
          subtotal: currentCart.totalAmount,
          totalAmount: currentCart.totalAmount,
          notes: currentCart.notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: widget.cashierName,
        );

        await _heldOrderService.saveHeldOrder(newHeldOrder);
      }
    }

    if (!mounted) return;

    // Load the selected order into cart
    cartBloc.add(LoadHeldOrderIntoCart(order));

    // Remove it from held list because it is now actively in cart
    await _heldOrderService.removeHeldOrder(order.id);

    if (!mounted) return;
    Navigator.pop(context);
    AppToast.showSuccess(
      context,
      'Pesanan "${order.orderName}" dibuka kembali di kasir',
    );
  }

  Future<void> _printProforma(HeldOrder order) async {
    final printerService = PrinterService();
    if (!printerService.isConnected) {
      AppToast.showWarning(
        context,
        'Printer thermal belum terhubung. Periksa pengaturan printer.',
      );
      return;
    }

    setState(() => _printingOrderId = order.id);
    try {
      final bState = context.read<BusinessBloc>().state;
      final success = await _heldOrderService.printProformaBill(
        order: order,
        businessInfo: bState.businessInfo,
      );

      if (!mounted) return;
      if (success) {
        AppToast.showSuccess(
          context,
          'Struk tagihan sementara "${order.orderName}" berhasil dicetak',
        );
      } else {
        AppToast.showError(context, 'Gagal mencetak struk sementara');
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Error cetak: $e');
    } finally {
      if (mounted) setState(() => _printingOrderId = null);
    }
  }

  Future<void> _confirmDelete(HeldOrder order) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pesanan Tertahan?'),
        content: Text(
          'Pesanan "${order.orderName}" (${order.totalQuantity} item) akan dibatalkan dan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _heldOrderService.removeHeldOrder(order.id);
      if (mounted) {
        AppToast.showSuccess(context, 'Pesanan "${order.orderName}" dihapus');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return ValueListenableBuilder<List<HeldOrder>>(
      valueListenable: _heldOrderService.heldOrdersNotifier,
      builder: (context, heldOrders, _) {
        return Column(
          children: [
            // Drag Handle for bottom sheet on phone
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Daftar Open Bill',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: heldOrders.isNotEmpty
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF94A3B8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${heldOrders.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pesanan aktif yang ditahan / belum dibayar',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Orders List / Empty State
            Expanded(
              child: heldOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(
                                      0xFF334155,
                                    ).withValues(alpha: 0.3)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Tidak Ada Pesanan Tertahan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tekan "Tahan Pesanan" pada keranjang untuk menyimpan transaksi sementara',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: heldOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = heldOrders[index];
                        final isPrintingThis = _printingOrderId == order.id;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card Top Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          order.orderName,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (order.customerName != null) ...[
                                    Flexible(
                                      child: Text(
                                        '• ${order.customerName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  const Spacer(),
                                  Text(
                                    _formatElapsedTime(order.updatedAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Items Summary
                              Text(
                                '${order.totalQuantity} Item: ${order.summaryText}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF334155),
                                  height: 1.3,
                                ),
                              ),
                              if (order.notes != null &&
                                  order.notes!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Catatan: ${order.notes!.trim()}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              // Card Bottom Row: Total & Action Buttons
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Tagihan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        currencyFormatter.format(
                                          order.totalAmount,
                                        ),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),

                                  // Cetak Slip Sementara
                                  GestureDetector(
                                    onTap: isPrintingThis
                                        ? null
                                        : () => _printProforma(order),
                                    child: isPrintingThis
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : SvgPicture.asset(
                                            "assets/icons/printer.svg",
                                            width: 24,
                                            height: 24,
                                          ),
                                  ),
                                  SizedBox(width: 16),

                                  // Hapus / Batal
                                  GestureDetector(
                                    onTap: () => _confirmDelete(order),
                                    child: SvgPicture.asset(
                                      "assets/icons/trash.svg",
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Recall (Lanjutkan) Button
                                  ElevatedButton(
                                    onPressed: () => _recallOrder(order),

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('Buka'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
