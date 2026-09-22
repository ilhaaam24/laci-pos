import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/receipt_settings_service.dart';
import '../../../../domain/entities/business_entity.dart';
import '../../../../domain/entities/transaction_entity.dart';

/// A widget specifically designed to be rendered into a high-resolution JPG receipt image.
class ReceiptImageWidget extends StatelessWidget {
  final TransactionEntity transaction;
  final BusinessInfo? businessInfo;
  final ReceiptConfig? config;

  const ReceiptImageWidget({
    super.key,
    required this.transaction,
    this.businessInfo,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = config ?? ReceiptSettingsService().config;

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return Material(
      color: Colors.white,
      child: Container(
        width: 380,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Store Logo / Icon
            if (cfg.showLogo) ...[
              Center(
                child: _buildLogoWidget(cfg),
              ),
              const SizedBox(height: 10),
            ],

            // Business Name
            Text(
              (businessInfo?.businessName ?? 'LACI POS').toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: 0.5,
              ),
            ),

            // Tagline / Header Message
            if (cfg.headerMessage.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                cfg.headerMessage.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF475569),
                ),
              ),
            ],

            // Store Address
            if (cfg.showAddress &&
                businessInfo?.address != null &&
                businessInfo!.address!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                businessInfo!.address!.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],

            // Store Phone
            if (cfg.showPhone &&
                businessInfo?.phone != null &&
                businessInfo!.phone!.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Telp: ${businessInfo!.phone!.trim()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],

            const SizedBox(height: 14),
            _buildDashedLine(),
            const SizedBox(height: 12),

            // Metadata
            _buildMetaRow('No. Invoice', transaction.transactionCode),
            _buildMetaRow('Tanggal', dateFormatter.format(transaction.createdAt)),
            if (cfg.showCashierName && transaction.createdBy.isNotEmpty)
              _buildMetaRow('Kasir', transaction.createdBy),
            if (cfg.showCustomerName &&
                transaction.customerName != null &&
                transaction.customerName!.trim().isNotEmpty)
              _buildMetaRow('Pelanggan', transaction.customerName!.trim()),
            if (cfg.showTableNumber &&
                transaction.notes != null &&
                transaction.notes!.trim().isNotEmpty)
              _buildMetaRow(
                'Layanan / Meja',
                transaction.notes!.trim(),
                isHighlight: true,
              ),

            const SizedBox(height: 12),
            _buildDashedLine(),
            const SizedBox(height: 12),

            // Items List
            ...transaction.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (item.modifiersDisplay.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.modifiersDisplay,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (cfg.showItemNotes &&
                        item.notes != null &&
                        item.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Catatan: ${item.notes!.trim()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.quantity} x ${currencyFormatter.format(item.unitPrice)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                        Text(
                          currencyFormatter.format(item.subtotal),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 4),
            _buildDashedLine(),
            const SizedBox(height: 10),

            // Financial Breakdown
            _buildAmountRow(
              'Subtotal',
              currencyFormatter.format(transaction.subtotal),
            ),
            if (transaction.discountAmount > 0)
              _buildAmountRow(
                'Diskon',
                '-${currencyFormatter.format(transaction.discountAmount)}',
                textColor: const Color(0xFFDC2626),
              ),
            if (transaction.taxAmount > 0)
              _buildAmountRow(
                businessInfo?.taxName.isNotEmpty == true
                    ? businessInfo!.taxName
                    : 'Pajak',
                currencyFormatter.format(transaction.taxAmount),
              ),
            if (businessInfo != null &&
                businessInfo!.isServiceChargeEnabled &&
                businessInfo!.serviceChargeRate > 0)
              _buildAmountRow(
                'Biaya Layanan (${businessInfo!.serviceChargeRate}%)',
                currencyFormatter.format(
                  (transaction.subtotal - transaction.discountAmount > 0
                          ? transaction.subtotal - transaction.discountAmount
                          : 0) *
                      (businessInfo!.serviceChargeRate / 100),
                ),
              ),

            const SizedBox(height: 6),
            const Divider(color: Color(0xFF0F172A), thickness: 1.5),
            const SizedBox(height: 4),

            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  currencyFormatter.format(transaction.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            _buildDashedLine(),
            const SizedBox(height: 10),

            // Payment Breakdown
            ...transaction.payments.map(
              (p) => _buildAmountRow(
                p.typeName,
                currencyFormatter.format(p.amount),
              ),
            ),
            if (transaction.changeAmount > 0)
              _buildAmountRow(
                'Kembali',
                currencyFormatter.format(transaction.changeAmount),
                isBold: true,
              ),

            const SizedBox(height: 16),
            _buildDashedLine(),
            const SizedBox(height: 16),

            // Footer
            if (cfg.footerMessage.trim().isNotEmpty) ...[
              Text(
                cfg.footerMessage.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (cfg.footerNote.trim().isNotEmpty) ...[
              Text(
                cfg.footerNote.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
            ],
            if (cfg.socialMediaOrWifi.trim().isNotEmpty) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    cfg.socialMediaOrWifi.trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LACI POS - Sistem Kasir Modern',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoWidget(ReceiptConfig cfg) {
    if (cfg.customLogoPath != null &&
        cfg.customLogoPath!.isNotEmpty &&
        File(cfg.customLogoPath!).existsSync()) {
      return Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          File(cfg.customLogoPath!),
          fit: BoxFit.cover,
        ),
      );
    } else if (businessInfo?.logoUrl != null &&
        businessInfo!.logoUrl!.trim().isNotEmpty) {
      return Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: businessInfo!.logoUrl!.trim(),
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: Icon(
                Icons.store_rounded,
                size: 24,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.store_rounded,
            size: 28,
            color: Color(0xFF0F172A),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.receipt_long_rounded,
          size: 28,
          color: Color(0xFF0F172A),
        ),
      );
    }
  }

  Widget _buildMetaRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    String value, {
    Color? textColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: textColor ?? const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: textColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount =
            (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            );
          }),
        );
      },
    );
  }
}
