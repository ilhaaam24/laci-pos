import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/business_entity.dart';

class ReceiptService {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  Future<void> printReceipt(
    TransactionEntity transaction,
    BusinessInfo businessInfo,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Business Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      businessInfo.businessName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (businessInfo.address != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        businessInfo.address!,
                        style: const pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                    if (businessInfo.phone != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Tel: ${businessInfo.phone}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),

              // Transaction Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'No. Transaksi:',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    transaction.transactionCode,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tanggal:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    dateFormatter.format(transaction.createdAt),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              if (transaction.customerName != null) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Pelanggan:',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      transaction.customerName!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],

              pw.Divider(thickness: 1),

              // Items Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Item',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'Qty',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Harga',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Subtotal',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),

              pw.Divider(thickness: 0.5),

              // Items
              ...transaction.items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              item.productName,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              '${item.quantity}',
                              style: const pw.TextStyle(fontSize: 10),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              currencyFormatter.format(item.price),
                              style: const pw.TextStyle(fontSize: 10),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              currencyFormatter.format(item.subtotal),
                              style: const pw.TextStyle(fontSize: 10),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              pw.Divider(thickness: 1),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    currencyFormatter.format(transaction.totalAmount),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Metode Pembayaran:',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    transaction.paymentMethod,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),

              pw.Divider(thickness: 1),

              pw.SizedBox(height: 10),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Terima Kasih',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Barang yang sudah dibeli tidak dapat ditukar/dikembalikan',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'receipt_${transaction.transactionCode}.pdf',
    );
  }

  Future<void> sharePDF(
    TransactionEntity transaction,
    BusinessInfo businessInfo,
  ) async {
    final pdf = pw.Document();

    // Same PDF generation as above... (simplified for now as per user request)

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'receipt_${transaction.transactionCode}.pdf',
    );
  }
}
