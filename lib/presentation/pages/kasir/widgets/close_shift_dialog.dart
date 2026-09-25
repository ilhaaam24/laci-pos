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
import '../../../../core/di/injection.dart';
import '../../../../core/services/staff_auth_service.dart';

enum DrawerCashHandoverOption {
  leaveFloatOnly,
  keepAllInDrawer,
  emptyDrawer,
  custom,
}

class CloseShiftResult {
  final bool isClosed;
  final double remainingCashInDrawer;
  final double depositedCash;
  final DrawerCashHandoverOption handoverOption;
  final String handoverNote;

  const CloseShiftResult({
    required this.isClosed,
    required this.remainingCashInDrawer,
    required this.depositedCash,
    required this.handoverOption,
    required this.handoverNote,
  });
}

class CloseShiftDialog extends StatefulWidget {
  final ShiftEntity shift;
  final ShiftSummary summary;

  const CloseShiftDialog({
    super.key,
    required this.shift,
    required this.summary,
  });

  static Future<CloseShiftResult?> show(
    BuildContext context, {
    required ShiftEntity shift,
    required ShiftSummary summary,
  }) {
    return showDialog<CloseShiftResult>(
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
  final TextEditingController _customDepositController =
      TextEditingController();
  bool _hasCalculated = false;
  bool _isClosing = false;
  bool _closedSuccess = false;

  DrawerCashHandoverOption _handoverOption =
      DrawerCashHandoverOption.leaveFloatOnly;

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
    _customDepositController.dispose();
    super.dispose();
  }

  double _getParsedActualCash() {
    final clean = _actualCashController.text.replaceAll(RegExp(r'\D'), '');
    return double.tryParse(clean) ?? 0;
  }

  double get _calculatedRemainingCash {
    final actual = _getParsedActualCash();
    switch (_handoverOption) {
      case DrawerCashHandoverOption.leaveFloatOnly:
        return actual >= widget.shift.startCash
            ? widget.shift.startCash
            : actual;
      case DrawerCashHandoverOption.keepAllInDrawer:
        return actual;
      case DrawerCashHandoverOption.emptyDrawer:
        return 0;
      case DrawerCashHandoverOption.custom:
        final clean = _customDepositController.text.replaceAll(
          RegExp(r'\D'),
          '',
        );
        final deposit = double.tryParse(clean) ?? 0;
        return (actual - deposit).clamp(0, actual);
    }
  }

  double get _calculatedDepositedCash {
    final actual = _getParsedActualCash();
    final remaining = _calculatedRemainingCash;
    return (actual - remaining).clamp(0, actual);
  }

  String get _handoverSummaryNote {
    final depFormatted = _currencyFormatter.format(_calculatedDepositedCash);
    final remFormatted = _currencyFormatter.format(_calculatedRemainingCash);
    switch (_handoverOption) {
      case DrawerCashHandoverOption.leaveFloatOnly:
        return 'Setor omset penjualan ($depFormatted), modal awal ditinggal di laci ($remFormatted)';
      case DrawerCashHandoverOption.keepAllInDrawer:
        return 'Laci bergulir: seluruh uang diteruskan ke kasir berikutnya ($remFormatted)';
      case DrawerCashHandoverOption.emptyDrawer:
        return 'Tutup toko: seluruh uang disetor ($depFormatted), laci dikosongkan';
      case DrawerCashHandoverOption.custom:
        return 'Kustom: setor $depFormatted, sisa di laci $remFormatted';
    }
  }

  void _calculateDifference() {
    if (_actualCashController.text.trim().isEmpty) {
      AppToast.showWarning(context, 'Masukkan jumlah uang fisik di laci');
      return;
    }
    final actual = _getParsedActualCash();
    if (actual >= widget.shift.startCash) {
      _handoverOption = DrawerCashHandoverOption.leaveFloatOnly;
      _customDepositController.text = (actual - widget.shift.startCash)
          .toInt()
          .toString();
    } else {
      _handoverOption = DrawerCashHandoverOption.keepAllInDrawer;
      _customDepositController.text = '0';
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
    final userNotes = _notesController.text.trim();
    final dep = _calculatedDepositedCash;
    final rem = _calculatedRemainingCash;
    final handoverText = _handoverSummaryNote;

    final fullNotes = userNotes.isNotEmpty
        ? '$userNotes | [$handoverText]'
        : '[$handoverText]';

    try {
      final shiftBloc = context.read<ShiftBloc>();
      shiftBloc.add(
        CloseShift(
          shiftId: widget.shift.id,
          actualCash: actualCash,
          notes: fullNotes,
          remainingCash: rem,
          depositedCash: dep,
          handoverNote: handoverText,
        ),
      );

      // Wait for bloc to finish processing
      final nextState = await shiftBloc.stream
          .firstWhere((s) => !s.isLoading)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => shiftBloc.state,
          );

      if (!mounted) return;

      if (nextState.errorMessage != null &&
          nextState.errorMessage!.isNotEmpty) {
        setState(() {
          _isClosing = false;
        });
        AppToast.showError(
          context,
          'Gagal menutup shift: ${nextState.errorMessage}',
        );
        return;
      }

      setState(() {
        _isClosing = false;
        _closedSuccess = true;
        _closedShift = nextState.lastClosedShift ?? widget.shift;
        _closedSummary = nextState.lastClosedSummary ?? widget.summary;
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
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final expectedCash = widget.summary.expectedCashInDrawer;
    final actualCash = _getParsedActualCash();
    final difference = actualCash - expectedCash;

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
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
              onPressed: () => Navigator.of(context).pop(null),
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
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
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
                _buildRow(
                  'Modal Awal',
                  _currencyFormatter.format(widget.shift.startCash),
                  textColor,
                  mutedColor,
                ),
                const SizedBox(height: 6),
                _buildRow(
                  'Penjualan Tunai',
                  '+ ${_currencyFormatter.format(widget.summary.totalCashSales)}',
                  const Color(0xFF10B981),
                  mutedColor,
                ),
                if (widget.summary.totalCashIn > 0) ...[
                  const SizedBox(height: 6),
                  _buildRow(
                    'Kas Masuk',
                    '+ ${_currencyFormatter.format(widget.summary.totalCashIn)}',
                    const Color(0xFF10B981),
                    mutedColor,
                  ),
                ],
                if (widget.summary.totalCashOut > 0) ...[
                  const SizedBox(height: 6),
                  _buildRow(
                    'Kas Keluar',
                    '- ${_currencyFormatter.format(widget.summary.totalCashOut)}',
                    const Color(0xFFEF4444),
                    mutedColor,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
          const SizedBox(height: 16),

          // Alokasi Uang Laci (Serah Terima / Setor)
          Text(
            'Alokasi Kas Laci (Serah Terima / Setor)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tentukan uang fisik yang disetor ke brankas dan yang ditinggal di laci:',
            style: TextStyle(fontSize: 11, color: mutedColor),
          ),
          const SizedBox(height: 10),

          _buildHandoverOptionCard(
            option: DrawerCashHandoverOption.leaveFloatOnly,
            title: 'Setor Hasil Penjualan',
            subtitle:
                'Setor omset ke brankas/pemilik. Sisakan modal awal di laci untuk kasir berikutnya.',
            depositAmount: actualCash >= widget.shift.startCash
                ? actualCash - widget.shift.startCash
                : 0,
            remainingAmount: actualCash >= widget.shift.startCash
                ? widget.shift.startCash
                : actualCash,
            isRecommended: true,
            isDark: isDark,
            textColor: textColor,
            mutedColor: mutedColor,
            borderColor: borderColor,
          ),
          _buildHandoverOptionCard(
            option: DrawerCashHandoverOption.keepAllInDrawer,
            title: 'Laci Bergulir (Teruskan Semua)',
            subtitle:
                'Tidak ada uang yang diambil. Seluruh uang fisik di laci diteruskan ke shift berikutnya.',
            depositAmount: 0,
            remainingAmount: actualCash,
            isDark: isDark,
            textColor: textColor,
            mutedColor: mutedColor,
            borderColor: borderColor,
          ),
          _buildHandoverOptionCard(
            option: DrawerCashHandoverOption.emptyDrawer,
            title: 'Kuras Laci (Tutup Toko)',
            subtitle:
                'Tarik seluruh uang fisik untuk disetor ke brankas/bank. Laci dikosongkan (Rp 0).',
            depositAmount: actualCash,
            remainingAmount: 0,
            isDark: isDark,
            textColor: textColor,
            mutedColor: mutedColor,
            borderColor: borderColor,
          ),
          _buildHandoverOptionCard(
            option: DrawerCashHandoverOption.custom,
            title: 'Nominal Kustom',
            subtitle:
                'Atur nominal setoran dan sisa uang di laci secara manual.',
            depositAmount: _calculatedDepositedCash,
            remainingAmount: _calculatedRemainingCash,
            isDark: isDark,
            textColor: textColor,
            mutedColor: mutedColor,
            borderColor: borderColor,
          ),

          if (_handoverOption == DrawerCashHandoverOption.custom) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: TextField(
                controller: _customDepositController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Nominal yang Disetor ke Brankas/Pemilik',
                  labelStyle: TextStyle(fontSize: 12, color: mutedColor),
                  hintText: '0',
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],

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
                onPressed: () => Navigator.of(context).pop(null),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: borderColor),
                ),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                  ),
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
                    : Text(
                        !_hasCalculated ? 'Hitung Selisih' : 'Tutup Shift',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHandoverOptionCard({
    required DrawerCashHandoverOption option,
    required String title,
    required String subtitle,
    required double depositAmount,
    required double remainingAmount,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    bool isRecommended = false,
  }) {
    final isSelected = _handoverOption == option;
    final primaryColor = AppColors.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _handoverOption = option;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? primaryColor.withValues(alpha: 0.15)
                    : AppColors.darkCharcoal)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SOP Toko',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.white
                          : mutedColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.white,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: mutedColor)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    'Setor: ${_currencyFormatter.format(depositAmount)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    'Sisa Laci: ${_currencyFormatter.format(remainingAmount)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
              const SizedBox(height: 8),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 8),
              _buildRow(
                'Disetor ke Brankas',
                _currencyFormatter.format(_calculatedDepositedCash),
                const Color(0xFF0284C7),
                mutedColor,
                isBold: true,
              ),
              const SizedBox(height: 6),
              _buildRow(
                'Ditinggal di Laci',
                _currencyFormatter.format(_calculatedRemainingCash),
                const Color(0xFF10B981),
                mutedColor,
                isBold: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Actions: Cetak Struk & WhatsApp Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _printZReport,
                icon: Icon(
                  Icons.print_rounded,
                  size: 17,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                label: Text(
                  'Cetak Struk',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  side: BorderSide(color: borderColor),
                  minimumSize: const Size.fromHeight(44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareWhatsApp,
                icon: const Icon(
                  Icons.send_rounded,
                  size: 16,
                  color: Color(0xFF16A34A),
                ),
                label: const Text(
                  'WhatsApp',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.25)
                      : const Color(0xFFF0FDF4),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF059669).withValues(alpha: 0.5)
                        : const Color(0xFF86EFAC),
                  ),
                  minimumSize: const Size.fromHeight(44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Primary Action: Selesai & Kunci Layar
        ElevatedButton(
          onPressed: () {
            getIt<StaffAuthService>().lockScreen();
            Navigator.of(context).pop(
              CloseShiftResult(
                isClosed: true,
                remainingCashInDrawer: _calculatedRemainingCash,
                depositedCash: _calculatedDepositedCash,
                handoverOption: _handoverOption,
                handoverNote: _handoverSummaryNote,
              ),
            );
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Selesai & Kunci Layar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
