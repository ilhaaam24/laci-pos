import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/business_entity.dart';

class ExportService {
  static Future<void> exportReportToPdf({
    required Map<String, dynamic> reportData,
    required String period,
    BusinessInfo? businessInfo,
  }) async {
    final pdf = pw.Document();
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd MMMM yyyy HH:mm');
    final now = DateTime.now();

    final startDate = reportData['startDate'] as DateTime;
    final endDate = (reportData['endDate'] as DateTime).subtract(
      const Duration(seconds: 1),
    );

    String dateRange = '';
    if (period == 'Harian') {
      dateRange = DateFormat('dd MMMM yyyy').format(startDate);
    } else {
      dateRange =
          '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      businessInfo?.businessName ?? 'Laci POS Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                    if (businessInfo?.address != null)
                      pw.Text(
                        businessInfo!.address!,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (businessInfo?.phone != null)
                      pw.Text(
                        'Telp: ${businessInfo!.phone!}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'LAPORAN PENDAPATAN',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      period.toUpperCase(),
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(dateRange, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2, color: PdfColors.indigo),
            pw.SizedBox(height: 20),

            // Summary Grid
            pw.Table(
              children: [
                pw.TableRow(
                  children: [
                    _buildSummaryItem(
                      'Total Penjualan',
                      currencyFormatter.format(reportData['totalRevenue']),
                    ),
                    _buildSummaryItem(
                      'Total Modal',
                      currencyFormatter.format(reportData['totalCost']),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildSummaryItem(
                      'Total Laba',
                      currencyFormatter.format(reportData['totalProfit']),
                    ),
                    _buildSummaryItem(
                      'Total Transaksi',
                      '${reportData['totalTransactions']}',
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Best Sellers Table
            pw.Text(
              'Top 5 Produk Terlaris',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildBestSellersTable(
              reportData['bestSellingProducts'] as List<dynamic>,
              currencyFormatter,
            ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Dicetak pada: ${dateFormatter.format(now)}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
                pw.Text(
                  'Laci POS - Solusi Kasir Pintar',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Share PDF
    final bytes = await pdf.save();
    final fileName =
        'Laporan_${period}_${DateFormat('yyyyMMdd').format(now)}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBestSellersTable(
    List<dynamic> items,
    NumberFormat formatter,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: ['Nama Produk', 'Jumlah Terjual', 'Total Penjualan'],
      data: items
          .map(
            (item) => [
              item['productName'],
              '${item['totalQuantity']}',
              formatter.format(item['totalRevenue']),
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
      },
    );
  }
}
