import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/printer_service.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/style/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../domain/entities/shift_entity.dart';
import '../../../blocs/business/business_bloc.dart';
import '../../../blocs/shift/shift_bloc.dart';
import 'cash_movement_dialog.dart';

class ShiftControlSheet extends StatelessWidget {
  const ShiftControlSheet({super.key});

  static Future<dynamic> show(BuildContext context) {
    // Refresh shift summary on open
    context.read<ShiftBloc>().add(LoadShiftSummary());

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ShiftControlSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final curFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return BlocBuilder<ShiftBloc, ShiftState>(
      builder: (context, shiftState) {
        final shift = shiftState.activeShift;
        final summary = shiftState.currentSummary;

        if (shift == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 48, color: Colors.orange),
                const SizedBox(height: 12),
                Text(
                  'Tidak ada shift aktif saat ini.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
        }

        final expectedCash = summary?.expectedCashInDrawer ?? shift.startCash;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull handle
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

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Shift Kasir Aktif',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kasir: ${shift.userName} • Buka: ${dateFmt.format(shift.startTime)}',
                            style: TextStyle(fontSize: 12, color: mutedColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: mutedColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Main Drawer Cash Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Uang Laci Seharusnya',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            curFmt.format(expectedCash),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDrawerMiniStat(
                                  'Modal',
                                  curFmt.format(shift.startCash),
                                ),
                                Container(
                                  width: 1,
                                  height: 22,
                                  color: Colors.white24,
                                ),
                                _buildDrawerMiniStat(
                                  'Tunai',
                                  curFmt.format(summary?.totalCashSales ?? 0),
                                ),
                                Container(
                                  width: 1,
                                  height: 22,
                                  color: Colors.white24,
                                ),
                                _buildDrawerMiniStat(
                                  'Kas Masuk',
                                  '+${curFmt.format(summary?.totalCashIn ?? 0)}',
                                ),
                                Container(
                                  width: 1,
                                  height: 22,
                                  color: Colors.white24,
                                ),
                                _buildDrawerMiniStat(
                                  'Kas Keluar',
                                  '-${curFmt.format(summary?.totalCashOut ?? 0)}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Action Buttons (Kas Masuk, Kas Keluar)
                    Row(
                      children: [
                        Expanded(
                          child: CashActionButton(
                            label: 'Kas Masuk',
                            icon: Icons.arrow_downward_rounded,
                            backgroundColor: AppColors.primary,
                            onTap: () => _openCashMovement(
                              context,
                              CashMovementType.cashIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CashActionButton(
                            label: 'Kas Keluar',
                            icon: Icons.arrow_upward_rounded,
                            backgroundColor: AppColors.error,
                            onTap: () => _openCashMovement(
                              context,
                              CashMovementType.cashOut,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Sales Breakdown Details Card
                    Text(
                      'Rincian Penjualan Shift',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Total Nota / Transaksi',
                            '${summary?.totalTransactions ?? 0} nota',
                            textColor,
                            mutedColor,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Penjualan Tunai',
                            curFmt.format(summary?.totalCashSales ?? 0),
                            textColor,
                            mutedColor,
                          ),
                          if ((summary?.totalQrisSales ?? 0) > 0) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'QRIS',
                              curFmt.format(summary!.totalQrisSales),
                              textColor,
                              mutedColor,
                            ),
                          ],
                          if ((summary?.totalDebitSales ?? 0) > 0) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Debit EDC',
                              curFmt.format(summary!.totalDebitSales),
                              textColor,
                              mutedColor,
                            ),
                          ],
                          if ((summary?.totalTransferSales ?? 0) > 0) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Transfer Bank',
                              curFmt.format(summary!.totalTransferSales),
                              textColor,
                              mutedColor,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Divider(height: 1, color: borderColor),
                          const SizedBox(height: 10),
                          _buildDetailRow(
                            'TOTAL OMSET SHIFT',
                            curFmt.format(summary?.totalSales ?? 0),
                            AppColors.primary,
                            textColor,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // List of Cash Movements (if any)
                    if (summary?.cashMovements.isNotEmpty == true) ...[
                      Text(
                        'Mutasi Kas Masuk / Keluar (${summary!.cashMovements.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...summary.cashMovements.reversed.map((m) {
                        final isCashIn = m.type == CashMovementType.cashIn;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCashIn
                                    ? Icons.add_circle_outline
                                    : Icons.remove_circle_outline,
                                color: isCashIn
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.reason,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(m.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isCashIn ? '+' : '-'}${curFmt.format(m.amount)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isCashIn
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    // X-Report / Print temporary
                    OutlinedButton(
                      onPressed: () async {
                        final printer = PrinterService();
                        if (printer.isConnected && summary != null) {
                          final bInfo = context
                              .read<BusinessBloc>()
                              .state
                              .businessInfo;
                          await printer.printShiftReport(
                            shift: shift,
                            summary: summary,
                            businessInfo: bInfo,
                          );
                          if (context.mounted) {
                            AppToast.showSuccess(
                              context,
                              'Struk X-Report dicetak',
                            );
                          }
                        } else {
                          // Share WhatsApp if printer not connected
                          final bInfo = context
                              .read<BusinessBloc>()
                              .state
                              .businessInfo;
                          if (summary != null) {
                            await WhatsappService.shareShiftReport(
                              shift: shift,
                              summary: summary,
                              businessInfo: bInfo,
                            );
                          }
                        }
                      },

                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cetak Rekap Sementara',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tutup Shift Button (Z-Report)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, 'close_shift');
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkBackground,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tutup Shift',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerMiniStat(String label, String value) {
    final textColor = const Color(0xFF0F172A);
    final mutedColor = const Color(0xFF64748B);
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: mutedColor)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
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

  Future<void> _openCashMovement(
    BuildContext context,
    CashMovementType type,
  ) async {
    final result = await CashMovementDialog.show(context, initialType: type);
    if (result == true && context.mounted) {
      context.read<ShiftBloc>().add(LoadShiftSummary());
    }
  }
}

/// Reusable action button for cash transactions (e.g. Kas Masuk / Kas Keluar).
class CashActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Border? border;
  final VoidCallback onTap;

  const CashActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foregroundColor, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
