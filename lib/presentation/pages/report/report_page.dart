import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../core/services/export_service.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/business_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../blocs/business/business_bloc.dart';
import '../../blocs/report/report_bloc.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../blocs/product/product_bloc.dart';

enum ReportPeriod { today, week, month, custom }

class ReportPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const ReportPage({super.key, this.onOpenDrawer});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  ReportPeriod _selectedPeriod = ReportPeriod.today;
  final DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customDateRange;
  late final String _lastUpdateTime;
  String? _selectedTrendKey;
  bool _showAllTransactions = false;
  bool _isExporting = false;

  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _lastUpdateTime = DateFormat('HH:mm').format(DateTime.now());
    _loadReport();
  }

  void _loadReport() {
    final now = _selectedDate;
    if (_selectedPeriod == ReportPeriod.today) {
      context.read<ReportBloc>().add(LoadDailyReport(now));
    } else if (_selectedPeriod == ReportPeriod.week) {
      context.read<ReportBloc>().add(LoadWeeklyReport(now));
    } else if (_selectedPeriod == ReportPeriod.month) {
      context.read<ReportBloc>().add(LoadMonthlyReport(now));
    } else if (_selectedPeriod == ReportPeriod.custom &&
        _customDateRange != null) {
      context.read<ReportBloc>().add(
        LoadCustomRangeReport(_customDateRange!.start, _customDateRange!.end),
      );
    }
    context.read<TransactionBloc>().add(LoadTransactions());
  }

  ThemeData _buildPickerTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFCCFBF1),
        onPrimaryContainer: AppColors.primary,
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
        surfaceContainerHighest: Color(0xFFF1F5F9),
        outline: Color(0xFFCBD5E1),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headerHelpStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE2E8F0),
        ),
        rangePickerHeaderBackgroundColor: AppColors.primary,
        rangePickerHeaderForegroundColor: Colors.white,
        rangePickerHeaderHeadlineStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        rangePickerHeaderHelpStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE2E8F0),
        ),
        rangeSelectionBackgroundColor: const Color(0xFFCCFBF1),
        rangeSelectionOverlayColor: WidgetStatePropertyAll(
          AppColors.primary.withValues(alpha: 0.12),
        ),
        todayForegroundColor: const WidgetStatePropertyAll(AppColors.primary),
        todayBorder: const BorderSide(color: AppColors.primary, width: 1.5),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFF94A3B8);
          }
          return const Color(0xFF0F172A);
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
        dayOverlayColor: WidgetStatePropertyAll(
          AppColors.primary.withValues(alpha: 0.08),
        ),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return const Color(0xFF0F172A);
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: const Color(0xFF64748B),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showDateFilterSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Filter Periode Tanggal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih 1 hari spesifik atau tentukan rentang tanggal tertentu.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                _buildDateSelectionOption(
                  icon: "assets/icons/tanggal_tertentu.svg",
                  title: 'Pilih 1 Tanggal Tertentu (Per Hari)',
                  subtitle:
                      'Tampilkan laporan transaksi pada satu hari spesifik',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickSingleDate();
                  },
                ),
                const SizedBox(height: 10),
                _buildDateSelectionOption(
                  icon: "assets/icons/rentang_tanggal.svg",
                  title: 'Pilih Rentang Tanggal',
                  subtitle:
                      'Tampilkan laporan transaksi dari tanggal mulai s/d selesai',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickRangeDate();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSelectionOption({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            SvgPicture.asset(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSingleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDateRange?.start ?? now,
      firstDate: DateTime(2022),
      lastDate: now,
      helpText: 'PILIH 1 TANGGAL',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      builder: (context, child) =>
          Theme(data: _buildPickerTheme(context), child: child!),
    );

    if (picked != null) {
      setState(() {
        _customDateRange = DateTimeRange(
          start: DateTime(picked.year, picked.month, picked.day),
          end: DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
        );
        _selectedPeriod = ReportPeriod.custom;
        _showAllTransactions = false;
      });
      _loadReport();
    }
  }

  Future<void> _pickRangeDate() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: now,
      initialDateRange:
          _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      helpText: 'PILIH RENTANG TANGGAL',
      cancelText: 'BATAL',
      saveText: 'SIMPAN',
      builder: (context, child) =>
          Theme(data: _buildPickerTheme(context), child: child!),
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = ReportPeriod.custom;
        _showAllTransactions = false;
      });
      _loadReport();
    }
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case ReportPeriod.today:
        return 'Hari Ini';
      case ReportPeriod.week:
        return 'Minggu Ini';
      case ReportPeriod.month:
        return 'Bulan Ini';
      case ReportPeriod.custom:
        if (_customDateRange != null) {
          final s = _customDateRange!.start;
          final e = _customDateRange!.end;
          if (s.year == e.year && s.month == e.month && s.day == e.day) {
            return DateFormat('dd MMM yyyy').format(s);
          }
          final sStr = DateFormat('dd/MM').format(s);
          final eStr = DateFormat('dd/MM').format(e);
          return '$sStr - $eStr';
        }
        return 'Pilih Tanggal';
    }
  }

  List<TransactionEntity> _filterTransactions(List<TransactionEntity> all) {
    final now = DateTime.now();
    final currentBusinessId = context
        .read<BusinessBloc>()
        .state
        .businessInfo
        ?.id;

    return all.where((txn) {
      if (txn.status == TransactionStatus.cancelled) return false;
      if (currentBusinessId != null &&
          currentBusinessId.isNotEmpty &&
          txn.businessId != null &&
          txn.businessId!.isNotEmpty &&
          txn.businessId != currentBusinessId) {
        return false;
      }

      final date = txn.createdAt.toLocal();
      switch (_selectedPeriod) {
        case ReportPeriod.today:
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        case ReportPeriod.week:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final start = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );
          final end = start.add(const Duration(days: 7));
          return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              date.isBefore(end);
        case ReportPeriod.month:
          return date.year == now.year && date.month == now.month;
        case ReportPeriod.custom:
          if (_customDateRange == null) return true;
          final start = DateTime(
            _customDateRange!.start.year,
            _customDateRange!.start.month,
            _customDateRange!.start.day,
          );
          final end = DateTime(
            _customDateRange!.end.year,
            _customDateRange!.end.month,
            _customDateRange!.end.day,
            23,
            59,
            59,
          );
          return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              date.isBefore(end.add(const Duration(seconds: 1)));
      }
    }).toList();
  }

  Future<void> _handleExport(
    List<TransactionEntity> filteredTxns,
    double totalRevenue,
    double totalProfit,
    int totalItems,
    List<Map<String, dynamic>> topProducts, {
    double cashTotal = 0.0,
    double qrisTotal = 0.0,
    double transferTotal = 0.0,
  }) async {
    final businessInfo = context.read<BusinessBloc>().state.businessInfo;

    final now = DateTime.now();
    DateTime startDate = now;
    DateTime endDate = now;

    if (_selectedPeriod == ReportPeriod.today) {
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
    } else if (_selectedPeriod == ReportPeriod.week) {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 7));
    } else if (_selectedPeriod == ReportPeriod.month) {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
    } else if (_selectedPeriod == ReportPeriod.custom &&
        _customDateRange != null) {
      startDate = _customDateRange!.start;
      endDate = _customDateRange!.end;
    }

    final reportMap = {
      'startDate': startDate,
      'endDate': endDate,
      'totalRevenue': totalRevenue,
      'totalCost': totalRevenue - totalProfit,
      'totalProfit': totalProfit,
      'totalTransactions': filteredTxns.length,
      'totalItems': totalItems,
      'cashTotal': cashTotal,
      'qrisTotal': qrisTotal,
      'transferTotal': transferTotal,
      'bestSellingProducts': topProducts
          .map(
            (p) => {
              'name': p['name'] ?? p['productName'] ?? 'Produk',
              'productName': p['name'] ?? p['productName'] ?? 'Produk',
              'qty': p['qty'] ?? p['totalQuantity'] ?? 0,
              'totalQuantity': p['qty'] ?? p['totalQuantity'] ?? 0,
              'subtotal': p['subtotal'] ?? p['totalRevenue'] ?? 0.0,
              'totalRevenue': p['subtotal'] ?? p['totalRevenue'] ?? 0.0,
            },
          )
          .toList(),
      'transactions': filteredTxns,
      'dailySales': <String, double>{},
    };

    _showExportOptionBottomSheet(reportMap, businessInfo);
  }

  void _showExportOptionBottomSheet(
    Map<String, dynamic> reportMap,
    BusinessInfo? businessInfo,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 720;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: isTablet ? 540 : double.infinity),
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unduh Rekap Laporan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Periode: $_periodLabel',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),
              _buildExportOptionTile(
                icon: "assets/icons/download_pdf.svg",
                title: 'Lihat & Simpan PDF',
                subtitle: 'Pratinjau, simpan ke memori perangkat, atau cetak',
                onTap: () {
                  Navigator.pop(modalContext);
                  _executeExport(
                    () => ExportService.previewAndSavePdf(
                      reportData: reportMap,
                      period: _periodLabel,
                      businessInfo: businessInfo,
                    ),
                    successMessage: 'Rekap PDF berhasil disiapkan',
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildExportOptionTile(
                icon: "assets/icons/share_pdf.svg",
                title: 'Bagikan File PDF',
                subtitle:
                    'Kirim dokumen via WhatsApp, Telegram, Email, atau Drive',
                onTap: () {
                  Navigator.pop(modalContext);
                  _executeExport(
                    () => ExportService.shareReportPdf(
                      reportData: reportMap,
                      period: _periodLabel,
                      businessInfo: businessInfo,
                    ),
                    successMessage: 'Menu bagikan PDF terbuka',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOptionTile({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            SvgPicture.asset(icon, height: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeExport(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _isExporting = true);
    try {
      await action();
      if (!mounted) return;
      AppToast.showSuccess(context, successMessage);
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Gagal memproses PDF: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showEndOfDayDialog({
    required double totalOmzet,
    required int totalTransactions,
    required double cashTotal,
    required double nonCashTotal,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Row(
            children: [
              Icon(
                Icons.lock_clock_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Tutup Kasir Harian',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rekapitulasi Shift Kasir #01 • ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildDialogRow(
                      'Total Omzet',
                      _currencyFormatter.format(totalOmzet).trim(),
                      isBold: true,
                    ),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    _buildDialogRow(
                      'Total Transaksi',
                      '$totalTransactions Nota',
                    ),
                    const SizedBox(height: 6),
                    _buildDialogRow(
                      'Uang Tunai di Laci',
                      _currencyFormatter.format(cashTotal).trim(),
                    ),
                    const SizedBox(height: 6),
                    _buildDialogRow(
                      'Non-Tunai (QRIS/EDC)',
                      _currencyFormatter.format(nonCashTotal).trim(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pastikan fisik uang tunai di laci kasir telah sesuai dengan hitungan sistem sebelum menutup shift.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                AppToast.showSuccess(
                  context,
                  'Kasir berhasil ditutup untuk hari ini!',
                );
              },
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isBold ? AppColors.primary : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: MediaQuery.of(context).size.width >= 720
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
                tooltip: 'Menu Navigasi',
                onPressed: () {
                  if (widget.onOpenDrawer != null) {
                    widget.onOpenDrawer!();
                  } else {
                    context
                        .findRootAncestorStateOfType<ScaffoldState>()
                        ?.openDrawer();
                  }
                },
              )
            : null,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Laporan Penjualan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // _buildTopAppBar(),
            SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, txnState) {
                  List<TransactionEntity> allTxns = [];
                  if (txnState is TransactionLoaded) {
                    allTxns = txnState.transactions;
                  }

                  final filtered = _filterTransactions(allTxns);

                  // Calculate metrics
                  double totalRevenue = 0.0;
                  double totalProfit = 0.0;
                  int totalItems = 0;
                  Map<String, Map<String, dynamic>> productStats = {};

                  double qrisTotal = 0.0;
                  double cashTotal = 0.0;
                  double transferTotal = 0.0;

                  for (var txn in filtered) {
                    totalRevenue += txn.totalAmount;

                    // Payments
                    for (var p in txn.payments) {
                      if (p.type == PaymentType.qris) {
                        qrisTotal += p.amount;
                      } else if (p.type == PaymentType.cash) {
                        cashTotal += p.amount;
                      } else {
                        transferTotal += p.amount;
                      }
                    }

                    // Items & Profit
                    for (var item in txn.items) {
                      totalItems += item.quantity;
                      final cost = item.costPrice > 0
                          ? item.costPrice
                          : (item.price * 0.55); // fallback estimate 45% margin
                      totalProfit += (item.price - cost) * item.quantity;

                      if (productStats.containsKey(item.productId)) {
                        productStats[item.productId]!['qty'] += item.quantity;
                        productStats[item.productId]!['subtotal'] +=
                            item.subtotal;
                      } else {
                        final prodState = context.read<ProductBloc>().state;
                        final pMatch = prodState.products
                            .where((p) => p.id == item.productId)
                            .firstOrNull;
                        final imgUrl = pMatch?.imageUrl;

                        productStats[item.productId] = {
                          'name': item.productName,
                          'qty': item.quantity,
                          'subtotal': item.subtotal,
                          'image': imgUrl,
                        };
                      }
                    }
                  }

                  // Real metrics only (no dummy fallback data)
                  final displayRevenue = totalRevenue;
                  final displayTransactions = filtered.length;
                  final displayAverage = displayTransactions > 0
                      ? (displayRevenue / displayTransactions)
                      : 0.0;
                  final displayProfit = totalProfit;
                  final displayMargin = displayRevenue > 0
                      ? (displayProfit / displayRevenue * 100)
                      : 0.0;
                  final displayItems = totalItems;
                  final displayActiveMenu = productStats.length;

                  // Top 3 products (real sold products only)
                  final List<Map<String, dynamic>> topProducts = [];
                  if (productStats.isNotEmpty) {
                    final sorted = productStats.values.toList()
                      ..sort(
                        (a, b) => (b['qty'] as int).compareTo(a['qty'] as int),
                      );
                    for (var p in sorted.take(3)) {
                      topProducts.add(p);
                    }
                  }

                  // Payment distribution percentages
                  final double totalPaySum =
                      qrisTotal + cashTotal + transferTotal;
                  final double qrisPct = totalPaySum > 0
                      ? (qrisTotal / totalPaySum * 100)
                      : 0.0;
                  final double cashPct = totalPaySum > 0
                      ? (cashTotal / totalPaySum * 100)
                      : 0.0;
                  final double transferPct = totalPaySum > 0
                      ? (transferTotal / totalPaySum * 100)
                      : 0.0;

                  return RefreshIndicator(
                    onRefresh: () async {
                      _loadReport();
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      children: [
                        // Status Bar: Update: 20:45 WIB & Kasir #01
                        _buildStatusBar(),
                        const SizedBox(height: 12),

                        // Period Segmented Filter: Hari Ini | Minggu Ini | Bulan Ini | Custom
                        _buildPeriodSegment(),
                        const SizedBox(height: 14),

                        // 2x2 Metric Cards Grid
                        _buildMetricCards(
                          revenue: displayRevenue,
                          transactions: displayTransactions,
                          average: displayAverage,
                          profit: displayProfit,
                          margin: displayMargin,
                          itemsSold: displayItems,
                          activeMenu: displayActiveMenu,
                        ),
                        const SizedBox(height: 14),

                        // Dynamic Sales Trend Bar Chart Card (Adaptive to period)
                        _buildSalesTrendCard(filtered),
                        const SizedBox(height: 14),

                        // Payment Methods Card
                        _buildPaymentMethodsCard(
                          totalTxns: displayTransactions,
                          qrisPct: qrisPct,
                          qrisAmount: qrisTotal,
                          cashPct: cashPct,
                          cashAmount: cashTotal,
                          transferPct: transferPct,
                          transferAmount: transferTotal,
                        ),
                        const SizedBox(height: 14),

                        // Top 3 Best Selling Products
                        _buildTopProductsCard(topProducts),
                        const SizedBox(height: 14),

                        // Riwayat Transaksi (Transaction History)
                        _buildTransactionHistoryCard(filtered),
                        const SizedBox(height: 16),

                        // Action Buttons: Unduh Rekap & Tutup Kasir Harian
                        _buildActionButtons(
                          isExporting: _isExporting,
                          onExport: () => _handleExport(
                            filtered,
                            displayRevenue,
                            displayProfit,
                            displayItems,
                            topProducts,
                            cashTotal: cashTotal,
                            qrisTotal: qrisTotal,
                            transferTotal: transferTotal,
                          ),
                          onEndOfDay: () => _showEndOfDayDialog(
                            totalOmzet: displayRevenue,
                            totalTransactions: displayTransactions,
                            cashTotal: cashTotal,
                            nonCashTotal: qrisTotal + transferTotal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Status Line: • Update: 20:45 WIB  |  Kasir #01
  Widget _buildStatusBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Update: $_lastUpdateTime WIB',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Period Segmented Control (Flat, NO SHADOW)
  Widget _buildPeriodSegment() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        spacing: 2,
        children: [
          _buildSegmentItem(
            ReportPeriod.today,
            'Hari Ini',
            onTap: () {
              setState(() {
                _selectedPeriod = ReportPeriod.today;
                _showAllTransactions = false;
              });
              _loadReport();
            },
          ),
          _buildSegmentItem(
            ReportPeriod.week,
            'Minggu Ini',
            onTap: () {
              setState(() {
                _selectedPeriod = ReportPeriod.week;
                _showAllTransactions = false;
              });
              _loadReport();
            },
          ),
          _buildSegmentItem(
            ReportPeriod.month,
            'Bulan Ini',
            onTap: () {
              setState(() {
                _selectedPeriod = ReportPeriod.month;
                _showAllTransactions = false;
              });
              _loadReport();
            },
          ),
          _buildSegmentItem(
            ReportPeriod.custom,
            _selectedPeriod == ReportPeriod.custom
                ? _periodLabel
                : 'Pilih Tanggal',
            onTap: _showDateFilterSelectionSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(
    ReportPeriod period,
    String label, {
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap();
          } else {
            setState(() => _selectedPeriod = period);
            _loadReport();
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.darkBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.white : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  // 4. 2x2 Metric Cards Grid (Flat, NO SHADOW)
  Widget _buildMetricCards({
    required double revenue,
    required int transactions,
    required double average,
    required double profit,
    required double margin,
    required int itemsSold,
    required int activeMenu,
  }) {
    return Column(
      children: [
        Row(
          children: [
            // Card 1: Total Omzet
            Expanded(
              child: _buildSingleMetricCard(
                title: 'Total Omzet',
                value: _currencyFormatter.format(revenue).trim(),
                icon: "assets/icons/omzet.svg",
                iconBg: const Color(0xFFCCFBF1),
                iconColor: AppColors.primary,
                footer: transactions > 0
                    ? Text(
                        '$transactions transaksi sukses',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      )
                    : const Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // Card 2: Transaksi
            Expanded(
              child: _buildSingleMetricCard(
                title: 'Transaksi',
                value: '$transactions Nota',
                icon: "assets/icons/transaction.svg",
                iconBg: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4F46E5),
                footer: Text(
                  'Rata-rata ${_currencyFormatter.format(average).trim()}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Card 3: Laba Bersih
            Expanded(
              child: _buildSingleMetricCard(
                title: 'Laba Bersih',
                value: _currencyFormatter.format(profit).trim(),
                icon: "assets/icons/laba_bersih.svg",
                iconBg: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFD97706),
                footer: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'Margin ${margin.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Card 4: Produk Terjual
            Expanded(
              child: _buildSingleMetricCard(
                title: 'Produk Terjual',
                value: '$itemsSold Pcs',
                icon: "assets/icons/terjual.svg",
                iconBg: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF475569),
                footer: Text(
                  '$activeMenu Varian Terjual',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleMetricCard({
    required String title,
    required String value,
    required String icon,
    required Color iconBg,
    required Color iconColor,
    required Widget footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              SvgPicture.asset(icon, height: 36),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          footer,
        ],
      ),
    );
  }

  // 5. Dynamic Sales Trend Bar Chart Card (Adaptive for Today, Week, Month, Custom)
  Widget _buildSalesTrendCard(List<TransactionEntity> filtered) {
    final trend = _generateTrendData(filtered);
    final bars = trend.bars;

    double maxVal = 0.0;
    for (var b in bars) {
      if (b.amount > maxVal) maxVal = b.amount;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trend.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trend.subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Color(0xFF004D40)),
                  const SizedBox(width: 4),
                  Text(
                    trend.legend,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Custom Bar Chart Area
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var bar in bars)
                  Expanded(
                    child: _buildTrendBar(
                      bar: bar,
                      ratio: (maxVal > 0 && bar.amount > 0)
                          ? (bar.amount / maxVal)
                          : 0.0,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBar({required _TrendBarData bar, required double ratio}) {
    final hasAmount = bar.amount > 0;
    final double barHeight = hasAmount ? (ratio.clamp(0.08, 1.0) * 85) : 4.0;
    final isSelected = _selectedTrendKey == bar.key;

    Color barColor;
    if (bar.isPeak) {
      barColor = const Color(0xFF004D40); // Dark Teal Peak
    } else if (ratio > 0.6) {
      barColor = const Color(0xFF5EEAD4); // Soft Teal
    } else if (hasAmount) {
      barColor = const Color(0xFFCBD5E1); // Subtle Slate with amount
    } else {
      barColor = const Color(0xFFF1F5F9); // Subtle baseline for zero sales
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTrendKey = (_selectedTrendKey == bar.key) ? null : bar.key;
        });
        if (hasAmount) {
          AppToast.showInfo(
            context,
            '${bar.fullLabel}: ${_currencyFormatter.format(bar.amount).trim()}',
          );
        } else {
          AppToast.showInfo(context, '${bar.fullLabel}: Belum ada transaksi');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Dot on top of peak or selected
          if (bar.isPeak || isSelected)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(bottom: 3),
              decoration: const BoxDecoration(
                color: Color(0xFF004D40),
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 8),

          // The Bar Container
          Container(
            width: 14,
            height: barHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),

          // Label
          Text(
            bar.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: bar.isPeak ? FontWeight.bold : FontWeight.w500,
              color: bar.isPeak
                  ? const Color(0xFF004D40)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  ({
    String title,
    String subtitle,
    String legend,
    List<_TrendBarData> bars,
    bool hasData,
  })
  _generateTrendData(List<TransactionEntity> filtered) {
    final hasRealData = filtered.isNotEmpty;
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case ReportPeriod.today:
        int minH = 7;
        int maxH = 22;
        final Map<int, double> hourly = {};
        for (var txn in filtered) {
          final h = txn.createdAt.toLocal().hour;
          if (h < minH) minH = h;
          if (h > maxH) maxH = h;
          hourly[h] = (hourly[h] ?? 0) + txn.totalAmount;
        }

        double peakVal = 0.0;
        final List<int> peaks = [];
        for (var entry in hourly.entries) {
          if (entry.value > peakVal) peakVal = entry.value;
        }
        if (peakVal > 0) {
          final sorted = hourly.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          for (var e in sorted.take(2)) {
            if (e.value > 0) peaks.add(e.key);
          }
        }

        final List<_TrendBarData> bars = [];
        for (int h = minH; h <= maxH; h++) {
          final amt = hourly[h] ?? 0.0;
          bars.add(
            _TrendBarData(
              key: 'h_$h',
              label: h.toString().padLeft(2, '0'),
              fullLabel: 'Jam ${h.toString().padLeft(2, '0')}:00',
              amount: amt,
              isPeak: peaks.contains(h),
            ),
          );
        }

        final subtitle = (hasRealData && peaks.isNotEmpty)
            ? 'Puncak transaksi pada ${peaks.map((h) => '${h.toString().padLeft(2, '0')}:00').join(' & ')} (${_currencyFormatter.format(peakVal).trim()})'
            : 'Belum ada transaksi hari ini';

        return (
          title: 'Tren Penjualan Hari Ini',
          subtitle: subtitle,
          legend: 'Jam Sibuk',
          bars: bars,
          hasData: hasRealData,
        );

      case ReportPeriod.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        final fullDayNames = [
          'Senin',
          'Selasa',
          'Rabu',
          'Kamis',
          'Jumat',
          'Sabtu',
          'Minggu',
        ];
        final Map<int, double> daily = {for (int i = 1; i <= 7; i++) i: 0.0};
        for (var txn in filtered) {
          final day = txn.createdAt.toLocal().weekday;
          daily[day] = (daily[day] ?? 0) + txn.totalAmount;
        }

        double peakVal = 0.0;
        int peakDay = 0;
        for (var entry in daily.entries) {
          if (entry.value > peakVal) {
            peakVal = entry.value;
            peakDay = entry.key;
          }
        }

        final List<_TrendBarData> bars = [];
        for (int i = 1; i <= 7; i++) {
          final amt = daily[i] ?? 0.0;
          final date = startOfWeek.add(Duration(days: i - 1));
          bars.add(
            _TrendBarData(
              key: 'day_$i',
              label: dayNames[i - 1],
              fullLabel:
                  '${fullDayNames[i - 1]} (${DateFormat('dd MMM').format(date)})',
              amount: amt,
              isPeak: peakDay == i && amt > 0,
            ),
          );
        }

        final subtitle = (hasRealData && peakDay > 0)
            ? 'Puncak penjualan hari ${fullDayNames[peakDay - 1]} (${_currencyFormatter.format(peakVal).trim()})'
            : 'Belum ada transaksi minggu ini';

        return (
          title: 'Tren Penjualan Mingguan',
          subtitle: subtitle,
          legend: 'Hari Puncak',
          bars: bars,
          hasData: hasRealData,
        );

      case ReportPeriod.month:
        final Map<int, double> weekly = {
          1: 0.0,
          2: 0.0,
          3: 0.0,
          4: 0.0,
          5: 0.0,
        };
        for (var txn in filtered) {
          final day = txn.createdAt.toLocal().day;
          final w = ((day - 1) ~/ 7) + 1;
          weekly[w] = (weekly[w] ?? 0) + txn.totalAmount;
        }

        double peakVal = 0.0;
        int peakW = 0;
        for (var entry in weekly.entries) {
          if (entry.value > peakVal) {
            peakVal = entry.value;
            peakW = entry.key;
          }
        }

        final weekLabels = ['Mgg 1', 'Mgg 2', 'Mgg 3', 'Mgg 4', 'Mgg 5'];
        final weekDesc = [
          'Minggu 1 (Tgl 1-7)',
          'Minggu 2 (Tgl 8-14)',
          'Minggu 3 (Tgl 15-21)',
          'Minggu 4 (Tgl 22-28)',
          'Minggu 5 (Tgl 29-Akhir)',
        ];

        final List<_TrendBarData> bars = [];
        for (int i = 1; i <= 5; i++) {
          final amt = weekly[i] ?? 0.0;
          bars.add(
            _TrendBarData(
              key: 'week_$i',
              label: weekLabels[i - 1],
              fullLabel: weekDesc[i - 1],
              amount: amt,
              isPeak: peakW == i && amt > 0,
            ),
          );
        }

        final subtitle = (hasRealData && peakW > 0)
            ? 'Penjualan tertinggi Minggu ke-$peakW (${_currencyFormatter.format(peakVal).trim()})'
            : 'Belum ada transaksi bulan ini';

        return (
          title: 'Tren Penjualan Bulanan',
          subtitle: subtitle,
          legend: 'Minggu Puncak',
          bars: bars,
          hasData: hasRealData,
        );

      case ReportPeriod.custom:
        final start = _customDateRange?.start ?? now;
        final end = _customDateRange?.end ?? now;
        final diffDays = end.difference(start).inDays + 1;

        final Map<String, double> dailyMap = {};
        for (var txn in filtered) {
          final dateKey = DateFormat(
            'yyyy-MM-dd',
          ).format(txn.createdAt.toLocal());
          dailyMap[dateKey] = (dailyMap[dateKey] ?? 0) + txn.totalAmount;
        }

        double peakVal = 0.0;
        String peakKey = '';
        for (var entry in dailyMap.entries) {
          if (entry.value > peakVal) {
            peakVal = entry.value;
            peakKey = entry.key;
          }
        }

        final List<_TrendBarData> bars = [];
        if (diffDays <= 7) {
          for (int i = 0; i < diffDays; i++) {
            final d = start.add(Duration(days: i));
            final dateKey = DateFormat('yyyy-MM-dd').format(d);
            final amt = dailyMap[dateKey] ?? 0.0;
            bars.add(
              _TrendBarData(
                key: dateKey,
                label: DateFormat('dd/MM').format(d),
                fullLabel: DateFormat('dd MMMM yyyy').format(d),
                amount: amt,
                isPeak: peakKey == dateKey && amt > 0,
              ),
            );
          }
        } else {
          final step = (diffDays / 6).ceil();
          for (int i = 0; i < diffDays; i += step) {
            final segStart = start.add(Duration(days: i));
            int endOffset = i + step - 1;
            if (endOffset >= diffDays) endOffset = diffDays - 1;
            final segEnd = start.add(Duration(days: endOffset));

            double segTotal = 0.0;
            for (int j = i; j <= endOffset; j++) {
              final d = start.add(Duration(days: j));
              final dateKey = DateFormat('yyyy-MM-dd').format(d);
              segTotal += dailyMap[dateKey] ?? 0.0;
            }

            final segKey = 'seg_$i';
            bars.add(
              _TrendBarData(
                key: segKey,
                label: DateFormat('dd/MM').format(segStart),
                fullLabel:
                    '${DateFormat('dd MMM').format(segStart)} - ${DateFormat('dd MMM').format(segEnd)}',
                amount: segTotal,
                isPeak: false,
              ),
            );
          }
        }

        final subtitle = (hasRealData && peakVal > 0)
            ? 'Puncak transaksi: ${_currencyFormatter.format(peakVal).trim()}'
            : 'Belum ada transaksi pada periode ini';

        return (
          title: 'Tren Penjualan Periode Terpilih',
          subtitle: subtitle,
          legend: 'Hari Puncak',
          bars: bars,
          hasData: hasRealData,
        );
    }
  }

  // 6. Payment Method Distribution Card (Multi-segment progress bar & breakdown)
  Widget _buildPaymentMethodsCard({
    required int totalTxns,
    required double qrisPct,
    required double qrisAmount,
    required double cashPct,
    required double cashAmount,
    required double transferPct,
    required double transferAmount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Total $totalTxns Transaksi',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Multi-Segment Progress Bar (Flat, NO SHADOW)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child:
                  (totalTxns > 0 &&
                      (qrisAmount + cashAmount + transferAmount) > 0)
                  ? Row(
                      children: [
                        if (qrisPct > 0)
                          Expanded(
                            flex: qrisPct.round().clamp(1, 100),
                            child: Container(color: AppColors.primary),
                          ),
                        if (qrisPct > 0 && (cashPct > 0 || transferPct > 0))
                          const SizedBox(width: 2),
                        if (cashPct > 0)
                          Expanded(
                            flex: cashPct.round().clamp(1, 100),
                            child: Container(color: const Color(0xFF334155)),
                          ),
                        if (cashPct > 0 && transferPct > 0)
                          const SizedBox(width: 2),
                        if (transferPct > 0)
                          Expanded(
                            flex: transferPct.round().clamp(1, 100),
                            child: Container(color: const Color(0xFFF59E0B)),
                          ),
                      ],
                    )
                  : Container(color: const Color(0xFFF1F5F9)),
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown Columns (QRIS, Tunai, Transfer)
          Row(
            children: [
              _buildPaymentCol(
                dotColor: AppColors.primary,
                label: 'QRIS',
                percent: '${qrisPct.round()}%',
                amount: _currencyFormatter.format(qrisAmount).trim(),
                percentColor: AppColors.primary,
              ),
              _buildPaymentCol(
                dotColor: const Color(0xFF334155),
                label: 'Tunai',
                percent: '${cashPct.round()}%',
                amount: _currencyFormatter.format(cashAmount).trim(),
                percentColor: const Color(0xFF0F172A),
              ),
              _buildPaymentCol(
                dotColor: const Color(0xFFF59E0B),
                label: 'Transfer',
                percent: '${transferPct.round()}%',
                amount: _currencyFormatter.format(transferAmount).trim(),
                percentColor: const Color(0xFFD97706),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCol({
    required Color dotColor,
    required String label,
    required String percent,
    required String amount,
    required Color percentColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            percent,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: percentColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 7. Top 3 Best Selling Products Card (Flat, NO SHADOW)
  Widget _buildTopProductsCard(List<Map<String, dynamic>> products) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '3 Menu Terlaris',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                _periodLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 32,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada menu terjual pada periode ini',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else
            ...products.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              final name = p['name'] as String? ?? 'Menu Produk';
              final qty = p['qty'] as int? ?? 0;
              final subtotal = (p['subtotal'] as num?)?.toDouble() ?? 0.0;
              final imageUrl = p['image'] as String?;

              return Container(
                margin: EdgeInsets.only(
                  bottom: index < products.length - 1 ? 10 : 0,
                ),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    // Product Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 52,
                        height: 52,
                        color: const Color(0xFFE2E8F0),
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.fastfood_rounded,
                                      color: Color(0xFF94A3B8),
                                      size: 24,
                                    ),
                              )
                            : const Icon(
                                Icons.fastfood_rounded,
                                color: Color(0xFF94A3B8),
                                size: 24,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Rank Badge & Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: index == 0
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kontribusi: ${_currencyFormatter.format(subtotal).trim()}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sales Qty Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$qty pcs',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          'terjual',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 7b. Riwayat Transaksi (Flat, Minimalist, NO SHADOW)
  Widget _buildTransactionHistoryCard(List<TransactionEntity> transactions) {
    // Urutkan dari yang terbaru
    final sortedTxns = List<TransactionEntity>.from(transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalCount = sortedTxns.length;
    final displayTxns = _showAllTransactions
        ? sortedTxns
        : sortedTxns.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Judul & Badge Jumlah Nota
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset("assets/icons/order.svg", height: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalCount Nota',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Daftar transaksi penjualan periode $_periodLabel',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Zero / Empty state
          if (sortedTxns.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_outlined,
                      size: 24,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Belum Ada Transaksi',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tidak ada transaksi penjualan pada periode yang dipilih.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            ...displayTxns.map((txn) => _buildTransactionItemRow(txn)),
            if (totalCount > 5) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _showAllTransactions = !_showAllTransactions;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showAllTransactions
                            ? 'Tampilkan Lebih Sedikit'
                            : 'Lihat Semua ($totalCount Nota)',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showAllTransactions
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Row item kartu riwayat transaksi
  Widget _buildTransactionItemRow(TransactionEntity txn) {
    final isCash = txn.payments.any((p) => p.type == PaymentType.cash);
    final isQris = txn.payments.any((p) => p.type == PaymentType.qris);

    Color payColor = const Color(0xFF0D9488);
    String payText = txn.paymentMethodDisplay;

    if (isQris) {
      payColor = const Color(0xFF2563EB);
    } else if (!isCash && txn.payments.isNotEmpty) {
      payColor = const Color(0xFF7C3AED);
    }

    final totalItemsCount = txn.items.fold(0, (sum, i) => sum + i.quantity);
    final dateFormatted = _selectedPeriod == ReportPeriod.today
        ? DateFormat('HH:mm').format(txn.createdAt)
        : DateFormat('dd/MM HH:mm').format(txn.createdAt);

    return InkWell(
      onTap: () => _showTransactionDetailModal(txn),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            SvgPicture.asset("assets/icons/item.svg", height: 32),
            const SizedBox(width: 12),

            // Kode nota & ringkasan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          txn.transactionCode,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (txn.customerName != null &&
                          txn.customerName!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '• ${txn.customerName}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        dateFormatted,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: Color(0xFFCBD5E1)),
                      ),
                      Text(
                        '$totalItemsCount item',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          payText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: payColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Nilai total & chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _currencyFormatter.format(txn.totalAmount).trim(),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Detail',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Modal rincian nota & cetak ulang struk / share WA (Apple-style minimalist)
  void _showTransactionDetailModal(TransactionEntity txn) {
    final businessInfo = context.read<BusinessBloc>().state.businessInfo;
    final isCash = txn.payments.any((p) => p.type == PaymentType.cash);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 720;
    final totalQuantity = txn.items.fold(0, (sum, i) => sum + i.quantity);

    bool isPrinting = false;
    bool isSharingWA = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: isTablet ? 560 : double.infinity),
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // 1. Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 36,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // 2. Navigation Header (Apple Style)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Detail Transaksi',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(modalContext),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // 3. Scrollable Content (Hero + Inset-Grouped Cards)
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      children: [
                        // Hero Section (Apple Wallet / Pay Style)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                _currencyFormatter
                                    .format(txn.totalAmount)
                                    .trim(),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFA7F3D0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      txn.status == TransactionStatus.completed
                                          ? 'Transaksi Berhasil'
                                          : txn.status.name.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat(
                                  'EEEE, d MMMM yyyy • HH:mm',
                                  'id_ID',
                                ).format(txn.createdAt),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                          ),
                        ),

                        // Section 1: INFORMASI NOTA
                        _buildAppleSectionHeader('INFORMASI NOTA'),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              // No. Invoice with copy button
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'No. Invoice',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          txn.transactionCode,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {
                                            Clipboard.setData(
                                              ClipboardData(
                                                text: txn.transactionCode,
                                              ),
                                            );
                                            AppToast.showSuccess(
                                              context,
                                              'No. Invoice disalin',
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.copy_rounded,
                                                  size: 12,
                                                  color: Color(0xFF475569),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Salin',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF475569),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: Color(0xFFF1F5F9),
                              ),

                              // Metode Bayar
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Metode Bayar',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Text(
                                        txn.paymentMethodDisplay,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (txn.customerName != null &&
                                  txn.customerName!.isNotEmpty) ...[
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: Color(0xFFF1F5F9),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Pelanggan',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline_rounded,
                                            size: 15,
                                            color: Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            txn.customerName!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (txn.notes != null &&
                                  txn.notes!.isNotEmpty) ...[
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: Color(0xFFF1F5F9),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Catatan',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        txn.notes!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Section 2: RINCIAN MENU / PRODUK
                        _buildAppleSectionHeader(
                          'PRODUK TERJUAL ($totalQuantity ITEM)',
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < txn.items.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: Color(0xFFF1F5F9),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFF1F5F9),
                                          ),
                                        ),
                                        child: Center(
                                          child: SvgPicture.asset(
                                            "assets/icons/item.svg",
                                            height: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              txn.items[i].productName,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  '${txn.items[i].quantity} × ${_currencyFormatter.format(txn.items[i].price).trim()}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (txn.items[i].discount >
                                                    0) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 5,
                                                          vertical: 1,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFFEF2F2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '-${_currencyFormatter.format(txn.items[i].discount).trim()}',
                                                      style: const TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFFDC2626,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _currencyFormatter
                                            .format(txn.items[i].subtotal)
                                            .trim(),
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Section 3: RINGKASAN PEMBAYARAN
                        _buildAppleSectionHeader('RINGKASAN PEMBAYARAN'),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: _buildDetailRow(
                                  'Subtotal',
                                  _currencyFormatter
                                      .format(txn.subtotal)
                                      .trim(),
                                ),
                              ),
                              if (txn.discountAmount > 0) ...[
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: Color(0xFFF1F5F9),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: _buildDetailRow(
                                    'Diskon Transaksi',
                                    '- ${_currencyFormatter.format(txn.discountAmount).trim()}',
                                    valueColor: const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                              if (txn.taxAmount > 0) ...[
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: Color(0xFFF1F5F9),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: _buildDetailRow(
                                    'Pajak',
                                    '+ ${_currencyFormatter.format(txn.taxAmount).trim()}',
                                  ),
                                ),
                              ],
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFE2E8F0),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: _buildDetailRow(
                                  'Total Akhir',
                                  _currencyFormatter
                                      .format(txn.totalAmount)
                                      .trim(),
                                  isBold: true,
                                  fontSize: 15,
                                  valueColor: const Color(0xFF0F172A),
                                ),
                              ),
                              if (isCash && txn.amountPaid > 0) ...[
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: Color(0xFFF1F5F9),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: _buildDetailRow(
                                    'Tunai Diterima',
                                    _currencyFormatter
                                        .format(txn.amountPaid)
                                        .trim(),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: Color(0xFFF1F5F9),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: _buildDetailRow(
                                    'Kembalian',
                                    _currencyFormatter
                                        .format(txn.changeAmount)
                                        .trim(),
                                    isBold: true,
                                    valueColor: const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // 4. Fixed Apple Bottom Action Bar
                  StatefulBuilder(
                    builder: (actionContext, setModalState) {
                      return Container(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          12 + MediaQuery.of(modalContext).viewPadding.bottom,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // WhatsApp e-Receipt Button
                            Expanded(
                              child: InkWell(
                                onTap: isSharingWA
                                    ? null
                                    : () async {
                                        setModalState(() => isSharingWA = true);
                                        try {
                                          await WhatsappService.shareReceipt(
                                            transaction: txn,
                                            businessInfo: businessInfo,
                                          );
                                        } catch (e) {
                                          if (context.mounted) {
                                            AppToast.showError(
                                              context,
                                              'Gagal kirim WhatsApp: $e',
                                            );
                                          }
                                        } finally {
                                          if (modalContext.mounted) {
                                            setModalState(
                                              () => isSharingWA = false,
                                            );
                                          }
                                        }
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isSharingWA)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF15803D),
                                                ),
                                          ),
                                        )
                                      else
                                        SvgPicture.asset(
                                          "assets/icons/e-receipt.svg",
                                          height: 18,
                                        ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'e-Receipt WA',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Cetak Struk Button (Primary)
                            Expanded(
                              child: InkWell(
                                onTap: isPrinting
                                    ? null
                                    : () async {
                                        final printer = PrinterService();
                                        if (!printer.isConnected) {
                                          AppToast.showWarning(
                                            context,
                                            'Printer belum terhubung. Silakan sambungkan di menu Pengaturan Printer.',
                                          );
                                          return;
                                        }
                                        setModalState(() => isPrinting = true);
                                        try {
                                          final success = await printer
                                              .printReceipt(
                                                transaction: txn,
                                                businessInfo: businessInfo,
                                              );
                                          if (context.mounted) {
                                            if (success) {
                                              AppToast.showSuccess(
                                                context,
                                                'Struk berhasil dicetak ulang',
                                              );
                                            } else {
                                              AppToast.showError(
                                                context,
                                                'Gagal mencetak struk',
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            AppToast.showError(
                                              context,
                                              'Gagal mencetak: $e',
                                            );
                                          }
                                        } finally {
                                          if (modalContext.mounted) {
                                            setModalState(
                                              () => isPrinting = false,
                                            );
                                          }
                                        }
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isPrinting)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      else
                                        SvgPicture.asset(
                                          "assets/icons/printer.svg",
                                          height: 24,
                                        ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Cetak Struk',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppleSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double fontSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            color:
                valueColor ??
                (isBold ? const Color(0xFF0F172A) : const Color(0xFF334155)),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 8. Action Buttons: Unduh Rekap & Tutup Kasir Harian
  Widget _buildActionButtons({
    required VoidCallback onExport,
    required VoidCallback onEndOfDay,
    bool isExporting = false,
  }) {
    return Column(
      children: [
        // Secondary: Unduh Rekap PDF / Excel
        InkWell(
          onTap: isExporting ? null : onExport,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isExporting) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Menyiapkan PDF...',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.file_download_outlined,
                    size: 18,
                    color: Color(0xFF334155),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Unduh Rekap PDF',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Primary: Tutup Kasir Harian (End of Day) (Solid Teal, NO SHADOW)
        InkWell(
          onTap: onEndOfDay,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Tutup Kasir Harian',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendBarData {
  final String key;
  final String label;
  final String fullLabel;
  final double amount;
  final bool isPeak;

  const _TrendBarData({
    required this.key,
    required this.label,
    required this.fullLabel,
    required this.amount,
    this.isPeak = false,
  });
}
