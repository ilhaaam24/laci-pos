import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/entities/transaction_entity.dart';

class ExportService {
  // Theme Colors for PDF (Teal POS branding)
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF0F766E); // Teal 700
  static const PdfColor primaryLight = PdfColor.fromInt(0xFFF0FDFA); // Teal 50
  static const PdfColor textDark = PdfColor.fromInt(0xFF0F172A); // Slate 900
  static const PdfColor textMuted = PdfColor.fromInt(0xFF64748B); // Slate 500
  static const PdfColor borderLight = PdfColor.fromInt(0xFFE2E8F0); // Slate 200
  static const PdfColor bgCard = PdfColor.fromInt(0xFFF8FAFC); // Slate 50
  static const PdfColor successColor = PdfColor.fromInt(0xFF16A34A); // Green 600

  /// Format Rupiah defensively without crash on null or non-breaking spaces
  static String formatRupiah(num? amount) {
    if (amount == null) return 'Rp 0';
    try {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(amount).replaceAll('\u00a0', ' ').trim();
    } catch (_) {
      return 'Rp ${amount.toInt()}';
    }
  }

  /// Sanitize filename to prevent OS file path errors (especially slashes in custom date ranges)
  static String sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }

  /// Generate safe report filename
  static String generateReportFilename({
    required String period,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final safePeriod = sanitizeFilename(period);
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
    return 'Laporan_${safePeriod}_$dateStr.pdf';
  }

  /// Core document builder - pure PDF generation without triggering native dialogs
  static Future<pw.Document> buildReportPdf({
    required Map<String, dynamic> reportData,
    required String period,
    BusinessInfo? businessInfo,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormatter = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

    final DateTime startDate = reportData['startDate'] is DateTime
        ? reportData['startDate'] as DateTime
        : now;
    DateTime endDate = reportData['endDate'] is DateTime
        ? reportData['endDate'] as DateTime
        : startDate;
    if (endDate.isBefore(startDate)) {
      endDate = startDate;
    }

    final totalRevenue = (reportData['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final totalCost = (reportData['totalCost'] as num?)?.toDouble() ?? 0.0;
    final totalProfit = (reportData['totalProfit'] as num?)?.toDouble() ?? 0.0;
    final totalTransactions =
        (reportData['totalTransactions'] as num?)?.toInt() ?? 0;
    final totalItems = (reportData['totalItems'] as num?)?.toInt() ?? 0;
    final cashTotal = (reportData['cashTotal'] as num?)?.toDouble() ?? 0.0;
    final qrisTotal = (reportData['qrisTotal'] as num?)?.toDouble() ?? 0.0;
    final transferTotal =
        (reportData['transferTotal'] as num?)?.toDouble() ?? 0.0;

    final bestSelling =
        (reportData['bestSellingProducts'] as List<dynamic>?) ?? [];
    final transactions =
        (reportData['transactions'] as List<dynamic>?) ?? [];

    // Calculate formatted period string
    String dateRangeStr = '';
    final isSameDay = startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    if (isSameDay || period.toLowerCase().contains('hari')) {
      dateRangeStr = DateFormat('dd MMMM yyyy', 'id_ID').format(startDate);
    } else {
      dateRangeStr =
          '${DateFormat('dd MMM yyyy', 'id_ID').format(startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(endDate)}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: borderLight, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Laci POS - Solusi Kasir Pintar | Dicetak pada ${dateFormatter.format(now)} WIB',
                  style: const pw.TextStyle(fontSize: 8, color: textMuted),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: textMuted),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // 1. Header
            _buildHeader(
              businessInfo: businessInfo,
              period: period,
              dateRange: dateRangeStr,
              printedAt: dateFormatter.format(now),
            ),
            pw.SizedBox(height: 14),

            // 2. Financial Summary Cards
            _buildFinancialSummary(
              totalRevenue: totalRevenue,
              totalCost: totalCost,
              totalProfit: totalProfit,
              totalTransactions: totalTransactions,
              totalItems: totalItems,
            ),
            pw.SizedBox(height: 14),

            // 3. Payment Methods Breakdown (if applicable)
            if (cashTotal > 0 || qrisTotal > 0 || transferTotal > 0) ...[
              _buildPaymentBreakdown(
                cashTotal: cashTotal,
                qrisTotal: qrisTotal,
                transferTotal: transferTotal,
                totalRevenue: totalRevenue,
              ),
              pw.SizedBox(height: 14),
            ],

            // 4. Best Selling Products Table
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Produk Terlaris',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: textDark,
                  ),
                ),
                pw.Text(
                  '${bestSelling.length} Produk',
                  style: const pw.TextStyle(fontSize: 9, color: textMuted),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            _buildBestSellersTable(bestSelling),
            pw.SizedBox(height: 16),

            // 5. Transaction History Table (if available)
            if (transactions.isNotEmpty) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Rincian Transaksi',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  pw.Text(
                    '${transactions.length} Nota Penjualan',
                    style: const pw.TextStyle(fontSize: 9, color: textMuted),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              _buildTransactionsTable(transactions),
            ],
          ];
        },
      ),
    );

    return pdf;
  }

  /// Header component with business branding and period info
  static pw.Widget _buildHeader({
    BusinessInfo? businessInfo,
    required String period,
    required String dateRange,
    required String printedAt,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: primaryColor, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  businessInfo?.businessName ?? 'Laci POS',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                if (businessInfo?.address != null &&
                    businessInfo!.address!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    businessInfo.address!,
                    style: const pw.TextStyle(fontSize: 9, color: textDark),
                  ),
                ],
                if (businessInfo?.phone != null &&
                    businessInfo!.phone!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Telp: ${businessInfo.phone!}',
                    style: const pw.TextStyle(fontSize: 9, color: textMuted),
                  ),
                ],
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: primaryLight,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: primaryColor, width: 0.5),
                ),
                child: pw.Text(
                  'LAPORAN PENJUALAN',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Periode: $period',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: textDark,
                ),
              ),
              pw.Text(
                dateRange,
                style: const pw.TextStyle(fontSize: 9, color: textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4-box financial summary grid
  static pw.Widget _buildFinancialSummary({
    required double totalRevenue,
    required double totalCost,
    required double totalProfit,
    required int totalTransactions,
    required int totalItems,
  }) {
    return pw.Table(
      children: [
        pw.TableRow(
          children: [
            _buildMetricCard(
              title: 'Total Omzet (Penjualan)',
              value: formatRupiah(totalRevenue),
              subtitle: '$totalTransactions Transaksi',
              accentColor: primaryColor,
            ),
            pw.SizedBox(width: 8),
            _buildMetricCard(
              title: 'Total Modal (HPP)',
              value: formatRupiah(totalCost),
              subtitle: 'Estimasi Modal Pokok',
              accentColor: textMuted,
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.SizedBox(height: 8),
            pw.SizedBox(height: 8),
          ],
        ),
        pw.TableRow(
          children: [
            _buildMetricCard(
              title: 'Total Laba Bersih',
              value: formatRupiah(totalProfit),
              subtitle: totalRevenue > 0
                  ? 'Margin ${(totalProfit / totalRevenue * 100).toStringAsFixed(1)}%'
                  : 'Margin 0%',
              accentColor: successColor,
            ),
            pw.SizedBox(width: 8),
            _buildMetricCard(
              title: 'Barang Terjual',
              value: '$totalItems Item',
              subtitle: totalTransactions > 0
                  ? 'Rata-rata ${(totalItems / totalTransactions).toStringAsFixed(1)} item/nota'
                  : '0 item/nota',
              accentColor: primaryColor,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required PdfColor accentColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: bgCard,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderLight),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
          ),
        ],
      ),
    );
  }

  /// Payment methods breakdown box
  static pw.Widget _buildPaymentBreakdown({
    required double cashTotal,
    required double qrisTotal,
    required double transferTotal,
    required double totalRevenue,
  }) {
    final double total = cashTotal + qrisTotal + transferTotal;
    final validTotal = total > 0 ? total : (totalRevenue > 0 ? totalRevenue : 1.0);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgCard,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderLight),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Rincian Metode Pembayaran',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: textDark,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildPaymentSubItem(
                  'Tunai (Cash)',
                  formatRupiah(cashTotal),
                  '${(cashTotal / validTotal * 100).toStringAsFixed(0)}%',
                ),
              ),
              pw.Container(width: 1, height: 28, color: borderLight),
              pw.Expanded(
                child: _buildPaymentSubItem(
                  'QRIS',
                  formatRupiah(qrisTotal),
                  '${(qrisTotal / validTotal * 100).toStringAsFixed(0)}%',
                ),
              ),
              pw.Container(width: 1, height: 28, color: borderLight),
              pw.Expanded(
                child: _buildPaymentSubItem(
                  'Transfer / EDC',
                  formatRupiah(transferTotal),
                  '${(transferTotal / validTotal * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentSubItem(
    String label,
    String amount,
    String percent,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                label,
                style: const pw.TextStyle(fontSize: 8, color: textMuted),
              ),
              pw.Text(
                percent,
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Best sellers table with resilient mapping for all key variations
  static pw.Widget _buildBestSellersTable(List<dynamic> items) {
    if (items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 14),
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: bgCard,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: borderLight),
        ),
        child: pw.Text(
          'Tidak ada data produk terjual pada periode ini',
          style: const pw.TextStyle(
            fontSize: 9,
            color: textMuted,
          ),
        ),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: ['No', 'Nama Produk', 'Terjual', 'Total Omzet'],
      data: items.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final item = entry.value;

        // Support both report_page keys ('name', 'qty', 'subtotal')
        // and legacy keys ('productName', 'totalQuantity', 'totalRevenue')
        final name = (item['name'] ?? item['productName'] ?? 'Produk').toString();
        final dynamic qtyRaw = item['qty'] ?? item['totalQuantity'] ?? item['quantity'] ?? 0;
        final int qty = (qtyRaw is num) ? qtyRaw.toInt() : (int.tryParse(qtyRaw.toString()) ?? 0);

        final dynamic revRaw = item['subtotal'] ?? item['totalRevenue'] ?? item['revenue'] ?? 0.0;
        final num revenue = (revRaw is num) ? revRaw : (num.tryParse(revRaw.toString()) ?? 0);

        return [
          '$idx',
          name,
          '$qty item',
          formatRupiah(revenue),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      cellStyle: const pw.TextStyle(fontSize: 8.5, color: textDark),
      cellHeight: 24,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
      },
    );
  }

  /// Transaction history table with multi-page support
  static pw.Widget _buildTransactionsTable(List<dynamic> txns) {
    final timeFormat = DateFormat('dd/MM HH:mm');

    return pw.TableHelper.fromTextArray(
      headers: ['No', 'Waktu', 'No. Nota', 'Metode Bayar', 'Item', 'Total'],
      data: txns.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final txn = entry.value;

        String code = '-';
        String timeStr = '-';
        String payment = '-';
        int itemCount = 0;
        num total = 0;

        if (txn is TransactionEntity) {
          code = txn.transactionCode;
          timeStr = timeFormat.format(txn.createdAt);
          payment = txn.paymentMethodDisplay;
          itemCount = txn.items.fold(0, (sum, i) => sum + i.quantity);
          total = txn.totalAmount;
        } else if (txn is Map) {
          code = (txn['transactionCode'] ?? txn['code'] ?? '-').toString();
          if (txn['createdAt'] is DateTime) {
            timeStr = timeFormat.format(txn['createdAt'] as DateTime);
          }
          payment = (txn['paymentMethod'] ?? txn['payment'] ?? '-').toString();
          itemCount = (txn['itemCount'] as num?)?.toInt() ?? 0;
          total = (txn['totalAmount'] as num?) ?? 0;
        }

        return [
          '$idx',
          timeStr,
          code,
          payment,
          '$itemCount item',
          formatRupiah(total),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 8.5,
      ),
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      cellStyle: const pw.TextStyle(fontSize: 8, color: textDark),
      cellHeight: 22,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
      },
    );
  }

  /// Opens native print & preview dialog (allows previewing, printing, and direct "Save as PDF" to device)
  static Future<void> previewAndSavePdf({
    required Map<String, dynamic> reportData,
    required String period,
    BusinessInfo? businessInfo,
  }) async {
    final pdf = await buildReportPdf(
      reportData: reportData,
      period: period,
      businessInfo: businessInfo,
    );
    final fileName = generateReportFilename(period: period);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: fileName,
    );
  }

  /// Opens native share sheet (e.g. WhatsApp, Email, Drive, Save to Files)
  static Future<void> shareReportPdf({
    required Map<String, dynamic> reportData,
    required String period,
    BusinessInfo? businessInfo,
  }) async {
    final pdf = await buildReportPdf(
      reportData: reportData,
      period: period,
      businessInfo: businessInfo,
    );
    final fileName = generateReportFilename(period: period);
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  /// Default export method (backward compatibility)
  static Future<void> exportReportToPdf({
    required Map<String, dynamic> reportData,
    required String period,
    BusinessInfo? businessInfo,
  }) async {
    // By default, layoutPdf allows previewing, printing, and saving directly as PDF
    await previewAndSavePdf(
      reportData: reportData,
      period: period,
      businessInfo: businessInfo,
    );
  }
}
