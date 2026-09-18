import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/printer_service.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/style/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../domain/entities/business_entity.dart';
import '../../../../domain/entities/transaction_entity.dart';

class TransactionSuccessDialog extends StatefulWidget {
  final TransactionEntity transaction;
  final BusinessInfo? businessInfo;
  final String? customerPhone;
  final VoidCallback onNewTransaction;
  final VoidCallback onBackToKasir;

  const TransactionSuccessDialog({
    super.key,
    required this.transaction,
    this.businessInfo,
    this.customerPhone,
    required this.onNewTransaction,
    required this.onBackToKasir,
  });

  @override
  State<TransactionSuccessDialog> createState() =>
      _TransactionSuccessDialogState();
}

class _TransactionSuccessDialogState extends State<TransactionSuccessDialog> {
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isPrinting = false;
  bool _isSharingWA = false;

  Future<void> _handleReprint() async {
    setState(() => _isPrinting = true);
    try {
      final printerService = PrinterService();
      if (!printerService.isConnected) {
        AppToast.showWarning(
          context,
          'Printer belum terhubung. Periksa pengaturan printer.',
        );
        return;
      }
      final success = await printerService.printReceipt(
        transaction: widget.transaction,
        businessInfo: widget.businessInfo,
      );
      if (!mounted) return;
      if (success) {
        AppToast.showSuccess(context, 'Struk berhasil dicetak');
      } else {
        AppToast.showError(context, 'Gagal mencetak struk');
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Error mencetak: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _handleShareWhatsApp() async {
    setState(() => _isSharingWA = true);
    try {
      await WhatsappService.shareReceipt(
        transaction: widget.transaction,
        businessInfo: widget.businessInfo,
        phoneNumber: widget.customerPhone,
      );
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Gagal kirim WhatsApp: $e');
    } finally {
      if (mounted) setState(() => _isSharingWA = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txn = widget.transaction;
    final printerService = PrinterService();
    final isPrinterConnected = printerService.isConnected;
    final printerName = printerService.connectedDeviceName ?? 'Thermal 58mm';

    final totalQuantity = txn.items.fold(0, (sum, i) => sum + i.quantity);
    final itemSummary =
        txn.items
            .take(2)
            .map((i) => '${i.quantity}x ${i.productName}')
            .join(', ') +
        (txn.items.length > 2 ? ', +${txn.items.length - 2} lainnya' : '');

    final isCash = txn.payments.any((p) => p.type == PaymentType.cash);
    final receivedCash = isCash
        ? txn.payments
              .where((p) => p.type == PaymentType.cash)
              .fold(0.0, (s, p) => s + p.amount)
        : txn.amountPaid;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 720;
    final dialogMaxWidth = isTablet ? 560.0 : 450.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 16,
        vertical: 24,
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: dialogMaxWidth),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 28 : 20,
            isTablet ? 28 : 24,
            isTablet ? 28 : 20,
            isTablet ? 24 : 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Success Circle Check Icon
              Container(
                width: isTablet ? 68 : 60,
                height: isTablet ? 68 : 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: isTablet ? 38 : 34,
                ),
              ),
              SizedBox(height: isTablet ? 14 : 12),

              // 2. Title
              Text(
                'Transaksi Berhasil',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),

              // 3. Printer Status Pill
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 10,
                  vertical: isTablet ? 5 : 4,
                ),
                decoration: BoxDecoration(
                  color: isPrinterConnected
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPrinterConnected
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPrinterConnected
                          ? Icons.print_outlined
                          : Icons.print_disabled_outlined,
                      size: isTablet ? 14 : 13,
                      color: isPrinterConnected
                          ? const Color(0xFF059669)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPrinterConnected
                          ? '$printerName • Siap'
                          : 'Printer Belum Terhubung',
                      style: TextStyle(
                        fontSize: isTablet ? 12.5 : 11.5,
                        fontWeight: FontWeight.w600,
                        color: isPrinterConnected
                            ? const Color(0xFF059669)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTablet ? 18 : 16),

              // 4. Change Amount Card (Mint Green Card)
              _buildChangeCard(isCash, receivedCash, txn, isTablet: isTablet),
              SizedBox(height: isTablet ? 14 : 12),

              // 5. Transaction Summary Card
              _buildSummaryCard(
                txn,
                isCash,
                receivedCash,
                totalQuantity,
                itemSummary,
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 16 : 14),

              // 6. Action Buttons (e-Receipt WA & Cetak Ulang)
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: "assets/icons/e-receipt.svg",
                      iconColor: const Color(0xFF059669),
                      title: 'e-Receipt WA',
                      subtitle: widget.customerPhone?.isNotEmpty == true
                          ? widget.customerPhone!
                          : 'Kirim WhatsApp',
                      isLoading: _isSharingWA,
                      onTap: _isSharingWA ? null : _handleShareWhatsApp,
                      isTablet: isTablet,
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 10),
                  Expanded(
                    child: _buildActionTile(
                      icon: "assets/icons/printer.svg",
                      iconColor: AppColors.primary,
                      title: 'Cetak Ulang',
                      subtitle: 'Struk Kasir',
                      isLoading: _isPrinting,
                      onTap: _isPrinting ? null : _handleReprint,
                      isTablet: isTablet,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 18 : 16),

              // 7. Primary Button: Mulai Transaksi Baru
              SizedBox(
                width: double.infinity,
                height: isTablet ? 54 : 50,
                child: ElevatedButton(
                  onPressed: widget.onNewTransaction,

                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Buat Transaksi Baru',
                    style: TextStyle(
                      fontSize: isTablet ? 15.5 : 14.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 14 : 12),

              // 8. Secondary Button: Kembali ke Kasir
              InkWell(
                onTap: widget.onBackToKasir,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    'Kembali ke Meja & Kasir',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeCard(
    bool isCash,
    double receivedCash,
    TransactionEntity txn, {
    bool isTablet = false,
  }) {
    final change = txn.changeAmount;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 18 : 14,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            isCash ? 'UANG KEMBALIAN' : 'TOTAL DIBAYAR',
            style: TextStyle(
              fontSize: isTablet ? 12 : 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: Colors.black,
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isCash
                  ? _currencyFormatter.format(change)
                  : _currencyFormatter.format(txn.totalAmount),
              style: TextStyle(
                fontSize: isTablet ? 32 : 26,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    TransactionEntity txn,
    bool isCash,
    double receivedCash,
    int totalQuantity,
    String itemSummary, {
    bool isTablet = false,
  }) {
    final customerName = txn.customerName;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 18 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Row 1: Nomor Nota
          _buildSummaryRow(
            'Nomor Nota',
            '#${txn.transactionCode}',
            isBoldValue: true,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 10 : 8),

          // Row 2: Total Tagihan
          _buildSummaryRow(
            'Total Tagihan',
            _currencyFormatter.format(txn.totalAmount),
            isBoldValue: true,
            valueColor: const Color(0xFF0F172A),
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 10 : 8),

          // Row 3: Metode Bayar
          _buildSummaryRow(
            'Metode Bayar',
            isCash
                ? 'Tunai (Diterima ${_currencyFormatter.format(receivedCash).trim()})'
                : txn.paymentMethodDisplay,
            isTablet: isTablet,
          ),

          // Row 4: Pelanggan (jika ada)
          if (customerName != null && customerName.isNotEmpty) ...[
            SizedBox(height: isTablet ? 10 : 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: isTablet ? 16 : 14,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: isTablet ? 13.5 : 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Member',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '+${(txn.totalAmount / 1000).round()} Pts',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ],

          Padding(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 10),
            child: const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE2E8F0),
            ),
          ),

          // Row 5: Ringkasan Item Menu
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: isTablet ? 16 : 14,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$totalQuantity Item: $itemSummary',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTablet ? 12.5 : 11.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
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
    bool isBoldValue = false,
    Color? valueColor,
    bool isTablet = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 13.5 : 12.5,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12.5,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isLoading,
    required VoidCallback? onTap,
    bool isTablet = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14 : 12,
          vertical: isTablet ? 14 : 11,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            isLoading
                ? Center(
                    child: SizedBox(
                      width: isTablet ? 16 : 14,
                      height: isTablet ? 16 : 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    ),
                  )
                : SvgPicture.asset(icon, height: isTablet ? 28 : 24),
            SizedBox(width: isTablet ? 10 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isTablet ? 11.5 : 10.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
