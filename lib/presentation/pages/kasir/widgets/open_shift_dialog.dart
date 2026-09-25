import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/style/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../blocs/shift/shift_bloc.dart';

class OpenShiftDialog extends StatefulWidget {
  final double? initialAmount;
  final String? handoverNote;

  const OpenShiftDialog({super.key, this.initialAmount, this.handoverNote});

  static Future<bool?> show(
    BuildContext context, {
    double? initialAmount,
    String? handoverNote,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OpenShiftDialog(
        initialAmount: initialAmount,
        handoverNote: handoverNote,
      ),
    );
  }

  @override
  State<OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends State<OpenShiftDialog> {
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<double> _quickPresets = [
    50000,
    100000,
    150000,
    200000,
    300000,
    500000,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null && widget.initialAmount! >= 0) {
      _cashController.text = widget.initialAmount!.toInt().toString();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final shiftState = context.read<ShiftBloc>().state;
        final candidate = shiftState.lastClosedRemainingCash;
        if (candidate != null &&
            candidate >= 0 &&
            _cashController.text.isEmpty) {
          _cashController.text = candidate.toInt().toString();
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyPreset(double amount) {
    _cashController.text = amount.toInt().toString();
    setState(() {});
  }

  double _getParsedAmount() {
    final clean = _cashController.text.replaceAll(RegExp(r'\D'), '');
    return double.tryParse(clean) ?? 0;
  }

  void _submit() {
    final amount = _getParsedAmount();
    if (amount < 0) {
      AppToast.showWarning(context, 'Modal awal tidak valid');
      return;
    }

    final notes = _notesController.text.trim();
    context.read<ShiftBloc>().add(
      OpenShift(startCash: amount, notes: notes.isNotEmpty ? notes : null),
    );
    Navigator.of(context).pop(true);
    AppToast.showSuccess(
      context,
      'Shift berhasil dibuka! Modal awal: ${_currencyFormatter.format(amount)}',
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

    final currentUser = getIt<SessionService>().currentUser;
    final cashierName = currentUser?.name?.isNotEmpty == true
        ? currentUser!.name!
        : (currentUser?.email ?? 'Kasir');

    final shiftState = context.watch<ShiftBloc>().state;
    final effectiveHandoverAmount =
        widget.initialAmount ?? shiftState.lastClosedRemainingCash;
    final effectiveHandoverNote =
        widget.handoverNote ?? shiftState.lastClosedHandoverNote;
    final lastClosedShift = shiftState.lastClosedShift;

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Icon
              Row(
                children: [
                  SvgPicture.asset("assets/icons/shift.svg"),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buka Shift Kasir Baru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kasir: $cashierName',
                          style: TextStyle(
                            fontSize: 13,
                            color: mutedColor,
                            fontWeight: FontWeight.w500,
                          ),
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
              const SizedBox(height: 18),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 18),

              // Banner Serah Terima Uang Laci jika ada shift sebelumnya
              if (effectiveHandoverAmount != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0369A1).withValues(alpha: 0.2)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF0284C7).withValues(alpha: 0.4)
                          : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0284C7,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 18,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lastClosedShift != null
                                  ? 'Serah Terima dari ${lastClosedShift.userName}'
                                  : 'Serah Terima Kas Laci',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.lightBlueAccent
                                    : const Color(0xFF1E40AF),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              effectiveHandoverNote != null &&
                                      effectiveHandoverNote.isNotEmpty
                                  ? effectiveHandoverNote
                                  : 'Uang fisik yang ditinggalkan di laci: ${_currencyFormatter.format(effectiveHandoverAmount)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '💡 Hitung kembali uang fisik di laci sebelum membuka shift.',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Modal Awal Title
              Text(
                'Modal Awal Laci (Cash Float)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Masukkan uang fisik awal di laci untuk modal uang kembalian.',
                style: TextStyle(fontSize: 12, color: mutedColor),
              ),
              const SizedBox(height: 12),

              // Amount Input Field
              TextField(
                controller: _cashController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 20,
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: mutedColor.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 12),

              // Quick presets
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickPresets.map((amount) {
                  final isSelected = _getParsedAmount() == amount;
                  return InkWell(
                    onTap: () => _applyPreset(amount),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : borderColor,
                        ),
                      ),
                      child: Text(
                        _currencyFormatter.format(amount),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Optional Notes Field
              Text(
                'Catatan (Opsional)',
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
                  hintText:
                      'Contoh: Modal kembalian pagi, pecahan Rp 5rb & 10rb',
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

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
                      onPressed: _submit,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Buka Shift',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
