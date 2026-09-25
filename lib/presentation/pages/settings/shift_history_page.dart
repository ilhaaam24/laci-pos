import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:laci/core/services/printer_service.dart';
import 'package:laci/core/services/whatsapp_service.dart';
import 'package:laci/core/style/app_colors.dart';
import 'package:laci/core/utils/app_toast.dart';
import 'package:laci/domain/entities/shift_entity.dart';
import 'package:laci/presentation/blocs/business/business_bloc.dart';
import 'package:laci/presentation/blocs/shift/shift_bloc.dart';

class ShiftHistoryPage extends StatefulWidget {
  const ShiftHistoryPage({super.key});

  @override
  State<ShiftHistoryPage> createState() => _ShiftHistoryPageState();
}

class _ShiftHistoryPageState extends State<ShiftHistoryPage> {
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFormatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    context.read<ShiftBloc>().add(LoadShiftHistory());
  }

  void _showShiftDetail(ShiftEntity shift) async {
    final shiftBloc = context.read<ShiftBloc>();
    final summary = await shiftBloc.repository.getShiftSummary(shift.id);

    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final diff = shift.cashDifference ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Rekap Shift',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kasir: ${shift.userName} • ${_dateFormatter.format(shift.startTime)}',
                          style: TextStyle(fontSize: 12, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: mutedColor),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Discrepancy Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: diff == 0
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : diff > 0
                          ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                          : const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: diff == 0
                            ? const Color(0xFF10B981)
                            : diff > 0
                            ? const Color(0xFF0284C7)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status Selisih Kas:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          diff == 0
                              ? 'PAS (Rp 0)'
                              : diff > 0
                              ? 'LEBIH +${_currencyFormatter.format(diff)}'
                              : 'KURANG ${_currencyFormatter.format(diff)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: diff == 0
                                ? const Color(0xFF10B981)
                                : diff > 0
                                ? const Color(0xFF0284C7)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sales & Drawer Breakdown
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildRow(
                          'Modal Awal',
                          _currencyFormatter.format(shift.startCash),
                          textColor,
                          mutedColor,
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                          'Total Transaksi',
                          '${summary.totalTransactions} nota',
                          textColor,
                          mutedColor,
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                          'Penjualan Tunai',
                          _currencyFormatter.format(summary.totalCashSales),
                          textColor,
                          mutedColor,
                        ),
                        if (summary.totalQrisSales > 0) ...[
                          const SizedBox(height: 8),
                          _buildRow(
                            'QRIS',
                            _currencyFormatter.format(summary.totalQrisSales),
                            textColor,
                            mutedColor,
                          ),
                        ],
                        if (summary.totalDebitSales > 0) ...[
                          const SizedBox(height: 8),
                          _buildRow(
                            'Debit EDC',
                            _currencyFormatter.format(summary.totalDebitSales),
                            textColor,
                            mutedColor,
                          ),
                        ],
                        if (summary.totalTransferSales > 0) ...[
                          const SizedBox(height: 8),
                          _buildRow(
                            'Transfer Bank',
                            _currencyFormatter.format(
                              summary.totalTransferSales,
                            ),
                            textColor,
                            mutedColor,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 10),
                        _buildRow(
                          'TOTAL OMSET',
                          _currencyFormatter.format(summary.totalSales),
                          AppColors.primary,
                          textColor,
                          isBold: true,
                        ),
                        const SizedBox(height: 10),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 10),
                        _buildRow(
                          'Kas Masuk',
                          '+ ${_currencyFormatter.format(summary.totalCashIn)}',
                          const Color(0xFF10B981),
                          mutedColor,
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                          'Kas Keluar',
                          '- ${_currencyFormatter.format(summary.totalCashOut)}',
                          const Color(0xFFEF4444),
                          mutedColor,
                        ),
                        const SizedBox(height: 10),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 10),
                        _buildRow(
                          'Uang Laci Seharusnya',
                          _currencyFormatter.format(
                            summary.expectedCashInDrawer,
                          ),
                          textColor,
                          textColor,
                          isBold: true,
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                          'Uang Fisik Dihitung',
                          _currencyFormatter.format(shift.endCashActual ?? 0),
                          textColor,
                          textColor,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  if (shift.notes != null &&
                      shift.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Catatan: ${shift.notes!.trim()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: mutedColor,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Actions: Cetak Ulang & Kirim WA
                  ElevatedButton.icon(
                    onPressed: () async {
                      final printer = PrinterService();
                      if (printer.isConnected) {
                        final bInfo = context
                            .read<BusinessBloc>()
                            .state
                            .businessInfo;
                        await printer.printShiftReport(
                          shift: shift,
                          summary: summary,
                          businessInfo: bInfo,
                        );
                        if (ctx.mounted) {
                          AppToast.showSuccess(
                            ctx,
                            'Struk shift dicetak ulang',
                          );
                        }
                      } else {
                        AppToast.showWarning(
                          ctx,
                          'Printer Bluetooth belum terhubung',
                        );
                      }
                    },
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text(
                      'Cetak Ulang Struk Z-Report',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final bInfo = context
                          .read<BusinessBloc>()
                          .state
                          .businessInfo;
                      await WhatsappService.shareShiftReport(
                        shift: shift,
                        summary: summary,
                        businessInfo: bInfo,
                      );
                    },
                    icon: const Icon(
                      Icons.send_rounded,
                      size: 18,
                      color: Color(0xFF25D366),
                    ),
                    label: const Text(
                      'Bagikan ke WhatsApp',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25D366),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildRow(
    String label,
    String value,
    Color valueColor,
    Color labelColor, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: labelColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Riwayat Shift Kasir',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: BlocBuilder<ShiftBloc, ShiftState>(
        builder: (context, state) {
          if (state.isLoading && state.historyShifts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final shifts = state.historyShifts;
          if (shifts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 64,
                    color: mutedColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum Ada Riwayat Shift',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Riwayat penutupan shift (Z-Report) akan muncul di sini.',
                    style: TextStyle(fontSize: 13, color: mutedColor),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ShiftBloc>().add(LoadShiftHistory());
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: shifts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final shift = shifts[index];
                final diff = shift.cashDifference ?? 0;
                final isOpen = shift.isOpen;

                return InkWell(
                  onTap: () => _showShiftDetail(shift),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOpen
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF64748B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isOpen
                                      ? 'Shift Sedang Berjalan'
                                      : 'Shift Selesai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isOpen
                                        ? AppColors.primary
                                        : mutedColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? AppColors.primary
                                    : diff == 0
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.12)
                                    : diff > 0
                                    ? const Color(
                                        0xFF0284C7,
                                      ).withValues(alpha: 0.12)
                                    : const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isOpen
                                    ? 'Aktif'
                                    : diff == 0
                                    ? 'Pas'
                                    : diff > 0
                                    ? '+${_currencyFormatter.format(diff)}'
                                    : _currencyFormatter.format(diff),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOpen
                                      ? AppColors.white
                                      : diff == 0
                                      ? const Color(0xFF10B981)
                                      : diff > 0
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          shift.userName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Buka: ${_dateFormatter.format(shift.startTime)}',
                          style: TextStyle(fontSize: 12, color: mutedColor),
                        ),
                        if (shift.endTime != null) ...[
                          Text(
                            'Tutup: ${_dateFormatter.format(shift.endTime!)}',
                            style: TextStyle(fontSize: 12, color: mutedColor),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Modal Awal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: mutedColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currencyFormatter.format(shift.startCash),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total Omset',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: mutedColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currencyFormatter.format(shift.totalSales),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
