import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/business_entity.dart';
import '../../../domain/entities/shift_entity.dart';
import 'receipt_image_service.dart';

class WhatsappService {
  static String buildReceiptMessage({
    required TransactionEntity transaction,
    BusinessInfo? businessInfo,
  }) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    String message = '*STRUK PEMBAYARAN*\n';
    message += '*${businessInfo?.businessName ?? 'LACI POS'}*\n';
    if (businessInfo?.address != null) {
      message += '${businessInfo!.address}\n';
    }
    if (businessInfo?.phone != null) {
      message += 'Telp: ${businessInfo!.phone}\n';
    }
    message += '------------------------------------------\n';
    message += 'No. Invoice: ${transaction.transactionCode}\n';
    message += 'Tanggal: ${dateFormatter.format(transaction.createdAt)}\n';
    if (transaction.customerName != null) {
      message += 'Pelanggan: ${transaction.customerName}\n';
    }
    if (transaction.notes != null && transaction.notes!.trim().isNotEmpty) {
      message += 'Layanan / Meja: ${transaction.notes!.trim()}\n';
    }
    message += '------------------------------------------\n';

    for (var item in transaction.items) {
      message += '*${item.displayName}*\n';
      if (item.selectedModifiers.isNotEmpty) {
        message += '  _(${item.modifiersDisplay})_\n';
      }
      if (item.notes != null && item.notes!.trim().isNotEmpty) {
        message += '  _Catatan: ${item.notes!.trim()}_\n';
      }
      message +=
          '  ${item.quantity} x ${currencyFormatter.format(item.unitPrice)} = ${currencyFormatter.format(item.subtotal)}\n';
    }

    message += '------------------------------------------\n';
    message += 'Subtotal: ${currencyFormatter.format(transaction.subtotal)}\n';
    if (transaction.taxAmount > 0) {
      message += 'Pajak: ${currencyFormatter.format(transaction.taxAmount)}\n';
    }
    if (transaction.discountAmount > 0) {
      message +=
          'Diskon: -${currencyFormatter.format(transaction.discountAmount)}\n';
    }
    message +=
        '*Total: ${currencyFormatter.format(transaction.totalAmount)}*\n';
    message += '------------------------------------------\n';
    for (var payment in transaction.payments) {
      message +=
          '${payment.typeName}: ${currencyFormatter.format(payment.amount)}\n';
    }
    if (transaction.changeAmount > 0) {
      message +=
          'Kembali: ${currencyFormatter.format(transaction.changeAmount)}\n';
    }
    message += '------------------------------------------\n';
    message += 'Terima kasih telah berbelanja!';
    return message;
  }

  static String buildShiftReportMessage({
    required ShiftEntity shift,
    required ShiftSummary summary,
    BusinessInfo? businessInfo,
  }) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    final isZReport = shift.isClosed;
    String message = isZReport
        ? '📊 *LAPORAN TUTUP SHIFT (Z-REPORT)*\n'
        : '📋 *REKAP SEMENTARA SHIFT (X-REPORT)*\n';
    message += '*${businessInfo?.businessName ?? 'LACI POS'}*\n';
    if (businessInfo?.address != null) {
      message += '${businessInfo!.address}\n';
    }
    message += '------------------------------------------\n';
    message += '👤 *Kasir:* ${shift.userName}\n';
    message += '🕒 *Waktu Buka:* ${dateFormatter.format(shift.startTime)}\n';
    if (shift.endTime != null) {
      message += '🕒 *Waktu Tutup:* ${dateFormatter.format(shift.endTime!)}\n';
    } else {
      message += '🕒 *Status:* Sedang Berjalan (Aktif)\n';
    }
    message += '------------------------------------------\n';
    message += '💵 *Modal Awal:* ${currencyFormatter.format(shift.startCash)}\n';
    message += '🧾 *Total Transaksi:* ${summary.totalTransactions} nota\n';
    message += '💰 *Penjualan Tunai:* ${currencyFormatter.format(summary.totalCashSales)}\n';
    if (summary.totalQrisSales > 0) {
      message += '📱 *QRIS:* ${currencyFormatter.format(summary.totalQrisSales)}\n';
    }
    if (summary.totalDebitSales > 0) {
      message += '💳 *Debit EDC:* ${currencyFormatter.format(summary.totalDebitSales)}\n';
    }
    if (summary.totalTransferSales > 0) {
      message += '🏦 *Transfer Bank:* ${currencyFormatter.format(summary.totalTransferSales)}\n';
    }
    message += '------------------------------------------\n';
    message += '🔥 *TOTAL OMSET:* ${currencyFormatter.format(summary.totalSales)}\n';
    message += '------------------------------------------\n';
    message += '📥 *(+) Kas Masuk:* ${currencyFormatter.format(summary.totalCashIn)}\n';
    message += '📤 *(-) Kas Keluar:* ${currencyFormatter.format(summary.totalCashOut)}\n';
    if (summary.cashMovements.isNotEmpty) {
      for (final m in summary.cashMovements) {
        final symbol = m.type == CashMovementType.cashIn ? '+' : '-';
        message += '   • $symbol ${currencyFormatter.format(m.amount)} (${m.reason})\n';
      }
    }
    message += '------------------------------------------\n';
    message += '🏧 *Uang Laci Seharusnya:* ${currencyFormatter.format(summary.expectedCashInDrawer)}\n';

    if (shift.isClosed && shift.endCashActual != null) {
      message += '💵 *Uang Fisik Dihitung:* ${currencyFormatter.format(shift.endCashActual!)}\n';
      final diff = shift.cashDifference ?? 0;
      final diffText = diff == 0
          ? '✅ *PAS (Rp 0)*'
          : diff > 0
              ? '🔵 *LEBIH (+${currencyFormatter.format(diff)})*'
              : '🔴 *KURANG (${currencyFormatter.format(diff)})*';
      message += '⚖️ *Status Selisih:* $diffText\n';
    }

    if (shift.notes != null && shift.notes!.trim().isNotEmpty) {
      message += '📝 *Catatan:* ${shift.notes!.trim()}\n';
    }
    message += '------------------------------------------\n';
    message += '_Laci POS - Sistem Kasir Modern_\n';
    return message;
  }

  /// Shares receipt as a high-resolution JPG image via the system share sheet (WhatsApp pre-selectable)
  static Future<void> shareReceiptAsImage({
    required TransactionEntity transaction,
    BusinessInfo? businessInfo,
    BuildContext? context,
  }) async {
    try {
      final file = await ReceiptImageService.generateReceiptJpgFile(
        transaction: transaction,
        businessInfo: businessInfo,
        context: context,
      );

      final storeName = businessInfo?.businessName ?? 'Laci POS';
      Rect? sharePositionOrigin;
      if (context != null && context.mounted) {
        try {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
          }
        } catch (_) {}
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'image/jpeg',
              name: 'struk_${transaction.transactionCode}.jpg',
            ),
          ],
          text: 'Struk Pembayaran $storeName - ${transaction.transactionCode}',
          subject: 'Struk ${transaction.transactionCode}',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e, stack) {
      debugPrint('WhatsappService.shareReceiptAsImage error: $e\n$stack');
      rethrow;
    }
  }

  /// Shares receipt as plain text message directly opening WhatsApp
  static Future<void> shareReceiptAsText({
    required TransactionEntity transaction,
    BusinessInfo? businessInfo,
    String? phoneNumber,
  }) async {
    final message = buildReceiptMessage(
      transaction: transaction,
      businessInfo: businessInfo,
    );
    await _launchWhatsApp(message, phoneNumber);
  }

  /// Main entry point for sharing receipt. Defaults to JPG image sharing.
  static Future<void> shareReceipt({
    required TransactionEntity transaction,
    BusinessInfo? businessInfo,
    String? phoneNumber,
    bool asImage = true,
    BuildContext? context,
  }) async {
    if (asImage) {
      await shareReceiptAsImage(
        transaction: transaction,
        businessInfo: businessInfo,
        context: context,
      );
    } else {
      await shareReceiptAsText(
        transaction: transaction,
        businessInfo: businessInfo,
        phoneNumber: phoneNumber,
      );
    }
  }

  static Future<void> shareShiftReport({
    required ShiftEntity shift,
    required ShiftSummary summary,
    BusinessInfo? businessInfo,
    String? phoneNumber,
  }) async {
    final message = buildShiftReportMessage(
      shift: shift,
      summary: summary,
      businessInfo: businessInfo,
    );
    await _launchWhatsApp(message, phoneNumber);
  }

  static Future<void> _launchWhatsApp(String message, String? phoneNumber) async {
    final encodedMessage = Uri.encodeComponent(message);

    // Clean phone number (remove +, space, etc.)
    String cleanPhone = phoneNumber?.trim() ?? '';
    cleanPhone = cleanPhone.replaceAll(RegExp(r'\D'), '');

    // Ensure Indonesian numbers start with 62
    if (cleanPhone.isNotEmpty) {
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '62${cleanPhone.substring(1)}';
      } else if (cleanPhone.startsWith('8')) {
        cleanPhone = '62$cleanPhone';
      }
    }

    // Build URIs:
    // If phone is provided: send to specific phone number.
    // If phone is empty: DO NOT include 'phone=' parameter (which causes WhatsApp "Nomor tidak valid" error).
    final Uri appUri = cleanPhone.isNotEmpty
        ? Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedMessage')
        : Uri.parse('whatsapp://send?text=$encodedMessage');

    final Uri webApiUri = cleanPhone.isNotEmpty
        ? Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMessage')
        : Uri.parse('https://api.whatsapp.com/send?text=$encodedMessage');

    final Uri waMeUri = cleanPhone.isNotEmpty
        ? Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage')
        : Uri.parse('https://wa.me/?text=$encodedMessage');

    // 1. Try launching native WhatsApp app intent directly
    try {
      if (await canLaunchUrl(appUri)) {
        final launched = await launchUrl(
          appUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }
    } catch (_) {
      // Continue to next fallback
    }

    // 2. Try api.whatsapp.com with external application
    try {
      if (await canLaunchUrl(webApiUri)) {
        final launched = await launchUrl(
          webApiUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }
    } catch (_) {
      // Continue to next fallback
    }

    // 3. Try wa.me
    try {
      if (await canLaunchUrl(waMeUri)) {
        final launched = await launchUrl(
          waMeUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }
    } catch (_) {
      // Continue to next fallback
    }

    // 4. Force launch appUri without canLaunchUrl check (useful if Android package visibility check fails)
    try {
      final launched = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {
      // Continue to next fallback
    }

    // 5. Final fallback to browser
    try {
      final launched = await launchUrl(
        webApiUri,
        mode: LaunchMode.platformDefault,
      );
      if (launched) return;
    } catch (_) {
      // Fall through to throw
    }

    throw 'Gagal membuka WhatsApp. Pastikan WhatsApp terpasang.';
  }
}
