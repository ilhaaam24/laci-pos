import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/printer_service.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../core/style/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../domain/entities/shift_entity.dart';
import '../../../blocs/business/business_bloc.dart';
import '../../../blocs/shift/shift_bloc.dart';

class CloseShiftDialog extends StatefulWidget {
  final ShiftEntity shift;
  final ShiftSummary summary;

  const CloseShiftDialog({
    super.key,
    required this.shift,
    required this.summary,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ShiftEntity shift,
    required ShiftSummary summary,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CloseShiftDialog(shift: shift, summary: summary),
    );
  }

  @override
  State<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<CloseShiftDialog> {
  final TextEditingController _actualCashController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _hasCalculated = false;
  bool _isClosing = false;
  bool _closedSuccess = false;

  ShiftEntity? _closedShift;
  ShiftSummary? _closedSummary;

  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _actualCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _getParsedActualCash() {
    final clean = _actualCashController.text.replaceAll(RegExp(r'\D'), '');
    return double.tryParse(clean) ?? 0;
  }

  void _calculateDifference() {
    if (_actualCashController.text.trim().isEmpty) {
      AppToast.showWarning(context, 'Masukkan jumlah uang fisik di laci');
      return;
    }
    setState(() {
      _hasCalculated = true;
    });
  }

  Future<void> _submitCloseShift() async {
    if (!_hasCalculated) {
      _calculateDifference();
      return;
    }

    setState(() {
      _isClosing = true;
    });

    final actualCash = _getParsedActualCash();
    final notes = _notesController.text.trim();

    try {
      final shiftBloc = context.read<ShiftBloc>();
      shiftBloc.add(
        CloseShift(
          shiftId: widget.shift.id,
          actualCash: actualCash,
          notes: notes.isNotEmpty ? notes : null,
        ),
      );

      // Wait a tick for bloc emission
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final state = shiftBloc.state;
      setState(() {
        _isClosing = false;
        _closedSuccess = true;
        _closedShift = state.lastClosedShift ?? widget.shift;
        _closedSummary = state.lastClosedSummary ?? widget.summary;
      });

      AppToast.showSuccess(context, 'Shift berhasil ditutup!');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isClosing = false;
      });
      AppToast.showError(context, 'Gagal menutup shift: $e');
    }
  }

  Future<void> _printZReport() async {
    final printerService = PrinterService();
    if (!printerService.isConnected) {
      AppToast.showWarning(
        context,
        'Printer Bluetooth belum terhubung. Hubungkan di menu Pengaturan Printer.',
      );
      return;
    }

    final bInfo = context.read<BusinessBloc>().state.businessInfo;
    final shift = _closedShift ?? widget.shift;
    final summary = _closedSummary ?? widget.summary;

    final success = await printerService.printShiftReport(
      shift: shift.copyWith(status: ShiftStatus.closed),
      summary: summary,
      businessInfo: bInfo,
    );

    if (!mounted) return;
    if (success) {
      AppToast.showSuccess(context, 'Struk Z-Report berhasil dicetak!');
    } else {
      AppToast.showError(context, 'Gagal mencetak struk Z-Report');
    }
  }

  Future<void> _shareWhatsApp() async {
    final bInfo = context.read<BusinessBloc>().state.businessInfo;
    final shift = _closedShift ?? widget.shift;
    final summary = _closedSummary ?? widget.summary;

    await WhatsappService.shareShiftReport(
      shift: shift.copyWith(status: ShiftStatus.closed),
      summary: summary,
      businessInfo: bInfo,
      phoneNumber: bInfo?.phone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final expectedCash = widget.summary.expectedCashInDrawer;
    final actualCash = _getParsedActualCash();
    final difference = actualCash - expectedCash;

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _closedSuccess
              ? _buildSuccessView(
                  isDark: isDark,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                  inputBg: inputBg,
                )
              : _buildFormView(
                  isDark: isDark,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                  inputBg: inputBg,
                  expectedCash: expectedCash,
                  actualCash: actualCash,
                  difference: difference,
                ),
        ),
      ),
    );
  }

  Widget _buildFormView({
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required Color inputBg,
    required double expectedCash,
    required double actualCash,
    required double difference,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lock_clock_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tutup Shift Kasir (Z-Report)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hitung uang fisik di laci kasir (Blind Close)',
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: mutedColor),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: borderColor),
        const SizedBox(height: 16),

        // Input Uang Fisik Di Laci
        Text(
          'Total Uang Fisik Tunai di Laci',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hitung dan masukkan seluruh uang tunai yang ada di laci saat ini.',
          style: TextStyle(fontSize: 12, color: mutedColor),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _actualCashController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          decoration: InputDecoration(
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                'Rp',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            hintText: '0',
            hintStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: mutedColor.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (_) {
            if (_hasCalculated) {
              setState(() {});
            }
          },
        ),

        const SizedBox(height: 14),

        // Breakdown Card (Shown after entering cash or tapping calculate)
        if (_hasCalculated) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _buildRow('Modal Awal', _currencyFormatter.format(widget.shift.startCash), textColor, mutedColor),
                const SizedBox(height: 6),
                _buildRow('Penjualan Tunai', '+ ${_currencyFormatter.format(widget.summary.totalCashSales)}', const Color(0xFF10B981), mutedColor),
                if (widget.summary.totalCashIn > 0) ...[
                  const SizedBox(height: 6),
                  _buildRow('Kas Masuk', '+ ${_currencyFormatter.format(widget.summary.totalCashIn)}', const Color(0xFF10B981), mutedColor),
                ],
                if (widget.summary.totalCashOut > 0) ...[
                  const SizedBox(height: 6),
                  _buildRow('Kas Keluar', '- ${_currencyFormatter.format(widget.summary.totalCashOut)}', const Color(0xFFEF4444), mutedColor),
                ],
                const SizedBox(height: 8),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 8),
                _buildRow(
                  'Uang Seharusnya',
                  _currencyFormatter.format(expectedCash),
                  textColor,
                  textColor,
                  isBold: true,
                ),
                const SizedBox(height: 6),
                _buildRow(
                  'Uang Fisik Dihitung',
                  _currencyFormatter.format(actualCash),
                  textColor,
                  textColor,
                  isBold: true,
                ),
                const SizedBox(height: 10),

                // Difference Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: difference == 0
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : difference > 0
                            ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                            : const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: difference == 0
                          ? const Color(0xFF10B981)
                          : difference > 0
                              ? const Color(0xFF0284C7)
                              : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status Selisih:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        difference == 0
                            ? 'PAS (Rp 0)'
                            : difference > 0
                                ? 'LEBIH +${_currencyFormatter.format(difference)}'
                                : 'KURANG ${_currencyFormatter.format(difference)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: difference == 0
                              ? const Color(0xFF10B981)
                              : difference > 0
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Optional Notes
        Text(
          'Catatan Tutup Shift',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _notesController,
          maxLines: 2,
          style: TextStyle(fontSize: 13, color: textColor),
          decoration: InputDecoration(
            hintText: 'Tuliskan keterangan jika ada selisih uang...',
            hintStyle: TextStyle(fontSize: 12, color: mutedColor),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: borderColor),
                ),
                child: Text(
                  'Batal',
                  style: TextStyle(fontWeight: FontWeight.w600, color: mutedColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isClosing
                    ? null
                    : (!_hasCalculated
                        ? _calculateDifference
                        : _submitCloseShift),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_hasCalculated
                      ? AppColors.primary
                      : const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isClosing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            !_hasCalculated
                                ? Icons.calculate_outlined
                                : Icons.lock_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            !_hasCalculated
                                ? 'Hitung Selisih'
                                : 'Konfirmasi Tutup Shift',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessView({
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required Color inputBg,
  }) {
    final shift = _closedShift ?? widget.shift;
    final diff = shift.cashDifference ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 38,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Shift Berhasil Ditutup!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Laporan Z-Report telah tersimpan di sistem.',
          style: TextStyle(fontSize: 13, color: mutedColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Summary Tile
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              _buildRow(
                'Total Penjualan',
                _currencyFormatter.format(shift.totalSales),
                textColor,
                mutedColor,
              ),
              const SizedBox(height: 6),
              _buildRow(
                'Total Nota',
                '${shift.totalTransactions} transaksi',
                textColor,
                mutedColor,
              ),
              const SizedBox(height: 6),
              _buildRow(
                'Uang Fisik Dihitung',
                _currencyFormatter.format(shift.endCashActual ?? 0),
                textColor,
                mutedColor,
              ),
              const SizedBox(height: 6),
              _buildRow(
                'Selisih Kas',
                diff == 0
                    ? 'PAS (Rp 0)'
                    : diff > 0
                        ? 'LEBIH +${_currencyFormatter.format(diff)}'
                        : 'KURANG ${_currencyFormatter.format(diff)}',
                diff == 0
                    ? const Color(0xFF10B981)
                    : diff > 0
                        ? const Color(0xFF0284C7)
                        : const Color(0xFFEF4444),
                mutedColor,
                isBold: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Printing & WhatsApp Sharing Buttons
        ElevatedButton.icon(
          onPressed: _printZReport,
          icon: const Icon(Icons.print_rounded, size: 18),
          label: const Text(
            'Cetak Struk Z-Report (Thermal 58mm)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _shareWhatsApp,
          icon: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF25D366)),
          label: const Text(
            'Kirim Rekap Shift ke WhatsApp',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF25D366)),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: Color(0xFF25D366)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Selesai & Keluar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: mutedColor,
            ),
          ),
        ),
      ],
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
}
