import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../core/style/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../domain/entities/shift_entity.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../blocs/shift/shift_bloc.dart';
import 'close_shift_dialog.dart';
import 'open_shift_dialog.dart';
import 'shift_handover_dialog.dart';

class StaffPinDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isLockMode;
  final UserEntity? preselectedStaff;

  const StaffPinDialog({
    super.key,
    this.title = 'Pilih Staf & Masukkan PIN',
    this.subtitle = 'Masukkan 4 digit PIN',
    this.isLockMode = false,
    this.preselectedStaff,
  });

  static Future<UserEntity?> show(
    BuildContext context, {
    String title = 'Pilih Staf & Masukkan PIN',
    String subtitle = 'Masukkan 4 digit PIN',
    bool isLockMode = false,
    UserEntity? preselectedStaff,
    bool promptOpenShiftIfNoActiveShift = true,
    double? pendingHandoverAmount,
    String? pendingHandoverNote,
  }) async {
    final staff = await showDialog<UserEntity>(
      context: context,
      barrierDismissible: !isLockMode,
      builder: (ctx) => StaffPinDialog(
        title: title,
        subtitle: subtitle,
        isLockMode: isLockMode,
        preselectedStaff: preselectedStaff,
      ),
    );

    if (staff != null && promptOpenShiftIfNoActiveShift && context.mounted) {
      final shiftBloc = context.read<ShiftBloc>();
      final activeShift = shiftBloc.state.activeShift;

      if (!shiftBloc.state.hasActiveShift || activeShift == null) {
        await OpenShiftDialog.show(
          context,
          initialAmount: pendingHandoverAmount,
          handoverNote: pendingHandoverNote,
        );
      } else {
        // Cek apakah staf yang baru login berbeda dengan pemilik shift aktif
        final currentOwnerId = activeShift.userId;
        final currentOwnerName = activeShift.userName;
        final isDifferentStaff =
            (currentOwnerId.isNotEmpty && currentOwnerId != staff.id) ||
            (currentOwnerName.isNotEmpty &&
                staff.name?.isNotEmpty == true &&
                currentOwnerName.toLowerCase() != staff.name!.toLowerCase());

        if (isDifferentStaff) {
          final action = await ShiftHandoverDialog.show(
            context,
            activeShift: activeShift,
            incomingStaff: staff,
          );

          if (action == ShiftHandoverAction.closeAndOpenNew &&
              context.mounted) {
            final summary =
                shiftBloc.state.currentSummary ??
                ShiftSummary(
                  shift: activeShift,
                  startCash: activeShift.startCash,
                  totalCashSales: activeShift.totalCashSales,
                  totalQrisSales: 0,
                  totalDebitSales: 0,
                  totalTransferSales: 0,
                  totalSales: activeShift.totalSales,
                  totalTransactions: activeShift.totalTransactions,
                  totalCashIn: 0,
                  totalCashOut: 0,
                  cashMovements: const [],
                );

            final closeResult = await CloseShiftDialog.show(
              context,
              shift: activeShift,
              summary: summary,
            );
            if (closeResult != null &&
                closeResult.isClosed &&
                context.mounted) {
              final curFmt = NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              );
              await OpenShiftDialog.show(
                context,
                initialAmount: closeResult.remainingCashInDrawer,
                handoverNote:
                    'Serah terima dari ${activeShift.userName}: Ditinggalkan ${curFmt.format(closeResult.remainingCashInDrawer)} di laci (Setor: ${curFmt.format(closeResult.depositedCash)})',
              );
            }
          }
        }
      }
    }

    return staff;
  }

  @override
  State<StaffPinDialog> createState() => _StaffPinDialogState();
}

class _StaffPinDialogState extends State<StaffPinDialog>
    with SingleTickerProviderStateMixin {
  final StaffAuthService _staffService = getIt<StaffAuthService>();
  List<UserEntity> _cachedStaff = [];
  UserEntity? _selectedStaff;
  String _pin = '';
  bool _isShaking = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _selectedStaff = widget.preselectedStaff;
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _loadStaff();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    final list = await _staffService.getCachedStaffList();
    if (mounted) {
      setState(() {
        _cachedStaff = list;
        if (_selectedStaff == null && list.isNotEmpty) {
          // Default to currently active staff if available, or first staff
          _selectedStaff = _staffService.activeStaff ?? list.first;
        }
      });
    }
  }

  void _onDigitPressed(String digit) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit;
    });

    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onClearPressed() {
    if (_pin.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _pin = '';
    });
  }

  Future<void> _verifyPin() async {
    final enteredPin = _pin;
    final staffId = _selectedStaff?.id;

    final matched = await _staffService.verifyPin(
      enteredPin,
      targetStaffId: staffId,
    );

    if (!mounted) return;

    if (matched != null) {
      HapticFeedback.mediumImpact();
      await _staffService.unlockScreen(matched);

      if (!mounted) return;
      Navigator.of(context).pop(matched);
      AppToast.showSuccess(
        context,
        'Selamat bertugas, ${matched.name ?? matched.email}!',
      );
    } else {
      // Wrong PIN animation
      HapticFeedback.heavyImpact();
      setState(() {
        _isShaking = true;
      });
      _shakeController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _isShaking = false;
            _pin = '';
          });
        }
      });
      AppToast.showError(context, 'PIN salah! Silakan coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final surface = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return PopScope(
      canPop: !widget.isLockMode,
      child: Dialog(
        backgroundColor: bg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                widget.subtitle,
                                style: TextStyle(fontSize: 11, color: muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!widget.isLockMode)
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: muted,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Staff Selector Row (if multiple cached staff exists)
                  if (_cachedStaff.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'PILIH KASIR / STAF',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cachedStaff.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final staff = _cachedStaff[idx];
                          final isSelected = _selectedStaff?.id == staff.id;
                          final displayName = staff.name?.isNotEmpty == true
                              ? staff.name!
                              : staff.email.split('@').first;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedStaff = staff;
                                _pin = '';
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.darkBackground.withValues(
                                        alpha: 0.1,
                                      )
                                    : surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.darkBackground.withValues(
                                          alpha: 0.2,
                                        )
                                      : borderColor,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        displayName,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.textPrimary
                                              : textColor,
                                        ),
                                      ),
                                      Text(
                                        staff.role.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: muted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 4 Dots PIN Indicator
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final offset = _isShaking
                          ? (1 - _shakeController.value) *
                                10 *
                                ((_shakeController.value * 20 % 2 == 0)
                                    ? 1
                                    : -1)
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isShaking
                                  ? const Color(0xFFEF4444)
                                  : borderColor,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final isFilled = index < _pin.length;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isFilled
                                      ? (_isShaking
                                            ? const Color(0xFFEF4444)
                                            : AppColors.primary)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isFilled
                                        ? (_isShaking
                                              ? const Color(0xFFEF4444)
                                              : AppColors.primary)
                                        : (isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFFCBD5E1)),
                                    width: 2,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Numeric Keypad
                  _buildKeypad(textColor, surface, borderColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(Color textColor, Color surface, Color borderColor) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', 'DEL'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              final isAction = key == 'C' || key == 'DEL';
              return SizedBox(
                width: 76,
                height: 52,
                child: Material(
                  color: isAction ? Colors.transparent : surface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      if (key == 'C') {
                        _onClearPressed();
                      } else if (key == 'DEL') {
                        _onBackspacePressed();
                      } else {
                        _onDigitPressed(key);
                      }
                    },
                    child: Center(
                      child: key == 'DEL'
                          ? Icon(
                              Icons.backspace_outlined,
                              size: 20,
                              color: textColor,
                            )
                          : Text(
                              key,
                              style: TextStyle(
                                fontSize: isAction ? 14 : 20,
                                fontWeight: isAction
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isAction
                                    ? const Color(0xFF94A3B8)
                                    : textColor,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
