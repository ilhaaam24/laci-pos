import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/style/app_colors.dart';
import '../../../../domain/entities/shift_entity.dart';
import '../../../../domain/entities/user_entity.dart';

enum ShiftHandoverAction {
  closeAndOpenNew,
  continueShift,
}

class ShiftHandoverDialog extends StatelessWidget {
  final ShiftEntity activeShift;
  final UserEntity incomingStaff;

  const ShiftHandoverDialog({
    super.key,
    required this.activeShift,
    required this.incomingStaff,
  });

  static Future<ShiftHandoverAction?> show(
    BuildContext context, {
    required ShiftEntity activeShift,
    required UserEntity incomingStaff,
  }) {
    return showDialog<ShiftHandoverAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ShiftHandoverDialog(
        activeShift: activeShift,
        incomingStaff: incomingStaff,
      ),
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

    final timeStr =
        '${activeShift.startTime.hour.toString().padLeft(2, '0')}:${activeShift.startTime.minute.toString().padLeft(2, '0')}';
    final curFmt = NumberFormat.currency(
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final previousStaffName = activeShift.userName.isNotEmpty
        ? activeShift.userName
        : 'Kasir Sebelumnya';
    final incomingStaffName = (incomingStaff.name?.isNotEmpty == true)
        ? incomingStaff.name!
        : incomingStaff.email;

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Icon
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Color(0xFFD97706),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pergantian Kasir Terdeteksi',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ada shift aktif yang belum ditutup',
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 16),

              // Handover info card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_circle_outlined,
                          size: 18,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shift Aktif Saat Ini:',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          previousStaffName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Waktu Buka Shift:',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          'Pukul $timeStr',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          size: 18,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Modal Awal Laci:',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          curFmt.format(activeShift.startCash),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Anda login sebagai $incomingStaffName. Pilih tindakan serah terima laci kasir:',
                style: TextStyle(
                  fontSize: 12.5,
                  color: mutedColor,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Action 1 (Recommended): Tutup Shift & Buka Shift Baru
              InkWell(
                onTap: () => Navigator.of(context).pop(ShiftHandoverAction.closeAndOpenNew),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lock_clock_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Tutup Shift & Buka Shift Baru',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'SOP Kasir',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hitung laci $previousStaffName, cetak Z-Report, lalu $incomingStaffName input modal awal baru.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: mutedColor,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Action 2: Lanjutkan Shift yang Sama
              InkWell(
                onTap: () => Navigator.of(context).pop(ShiftHandoverAction.continueShift),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.login_rounded,
                          color: textColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lanjutkan Shift $previousStaffName',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gunakan laci kasir yang sama tanpa serah terima (misal: gantian sementara).',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: mutedColor,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: mutedColor,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
