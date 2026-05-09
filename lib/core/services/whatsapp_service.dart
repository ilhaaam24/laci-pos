import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/business_entity.dart';

class WhatsappService {
  static Future<void> shareReceipt({
    required TransactionEntity transaction,
    BusinessInfo? businessInfo,
    String? phoneNumber,
  }) async {
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
    message += '------------------------------------------\n';

    for (var item in transaction.items) {
      message += '${item.productName}\n';
      message +=
          '${item.quantity} x ${currencyFormatter.format(item.price)} = ${currencyFormatter.format(item.subtotal)}\n';
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
    message += 'Metode Bayar: ${transaction.paymentMethod}\n';
    message += 'Bayar: ${currencyFormatter.format(transaction.amountPaid)}\n';
    message +=
        'Kembali: ${currencyFormatter.format(transaction.changeAmount)}\n';
    message += '------------------------------------------\n';
    message += 'Terima kasih telah berbelanja!';

    final encodedMessage = Uri.encodeComponent(message);

    // Clean phone number (remove +, space, etc.)
    String cleanPhone = phoneNumber ?? '';
    cleanPhone = cleanPhone.replaceAll(RegExp(r'\D'), '');

    // Ensure it starts with country code if not empty
    if (cleanPhone.isNotEmpty && cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      // Try launching with externalNonBrowserApplication to force opening the app
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );

      if (!launched) {
        // Fallback to platformDefault if externalNonBrowserApplication fails
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // Final fallback to whatsapp:// protocol
      try {
        final whatsappUri = Uri.parse(
          'whatsapp://send?phone=$cleanPhone&text=$encodedMessage',
        );
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } catch (e2) {
        throw 'Gagal membuka WhatsApp. Pastikan WhatsApp terpasang.';
      }
    }
  }
}
