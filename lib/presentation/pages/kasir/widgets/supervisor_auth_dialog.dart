import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../domain/entities/user_entity.dart';

class SupervisorAuthDialog extends StatefulWidget {
  final String actionTitle;
  final String? actionDescription;

  const SupervisorAuthDialog({
    super.key,
    required this.actionTitle,
    this.actionDescription,
  });

  static Future<UserEntity?> verify(
    BuildContext context, {
    required String actionTitle,
    String? actionDescription,
  }) {
    return showDialog<UserEntity>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SupervisorAuthDialog(
        actionTitle: actionTitle,
        actionDescription: actionDescription,
      ),
    );
  }

  @override
  State<SupervisorAuthDialog> createState() => _SupervisorAuthDialogState();
}

class _SupervisorAuthDialogState extends State<SupervisorAuthDialog>
    with SingleTickerProviderStateMixin {
  final StaffAuthService _staffService = getIt<StaffAuthService>();
  String _pin = '';
  bool _isShaking = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit;
    });

    if (_pin.length == 4) {
      _verifySupervisorPin();
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

  Future<void> _verifySupervisorPin() async {
    final enteredPin = _pin;
    final supervisor = await _staffService.verifySupervisorPin(enteredPin);

    if (!mounted) return;

    if (supervisor != null) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(supervisor);
      AppToast.showSuccess(
        context,
        'Otorisasi disetujui oleh ${supervisor.name ?? supervisor.role.name.toUpperCase()}!',
      );
    } else {
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
      AppToast.showError(
        context,
        'Otorisasi gagal! Hanya PIN Manager/Admin/Owner yang dapat menyetujui.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final surface = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shield icon & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Otorisasi Supervisor',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            widget.actionTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: muted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF991B1B)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Text(
                  widget.actionDescription ??
                      'Tindakan ini memerlukan PIN Manager, Admin, atau Pemilik Toko.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFF991B1B),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // PIN Dots
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isShaking ? const Color(0xFFEF4444) : borderColor,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? (_isShaking
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFEF4444))
                            : Colors.transparent,
                        border: Border.all(
                          color: isFilled
                              ? const Color(0xFFEF4444)
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
              const SizedBox(height: 16),

              // Keypad
              _buildKeypad(textColor, surface),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(Color textColor, Color surface) {
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
                width: 74,
                height: 48,
                child: Material(
                  color: isAction ? Colors.transparent : surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
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
                              size: 19,
                              color: textColor,
                            )
                          : Text(
                              key,
                              style: TextStyle(
                                fontSize: isAction ? 13 : 19,
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
