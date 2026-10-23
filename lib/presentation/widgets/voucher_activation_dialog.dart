import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:laci/core/style/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/license_service.dart';
import '../../core/utils/app_toast.dart';
import '../blocs/business/business_bloc.dart';

/// Shows the voucher activation dialog.
Future<bool?> showVoucherActivationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) => const VoucherActivationDialog(),
  );
}

class VoucherActivationDialog extends StatefulWidget {
  const VoucherActivationDialog({super.key});

  @override
  State<VoucherActivationDialog> createState() =>
      _VoucherActivationDialogState();
}

class _VoucherActivationDialogState extends State<VoucherActivationDialog> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _activateCode() async {
    final rawCode = _codeController.text.trim();
    if (rawCode.isEmpty) {
      setState(() {
        _errorMessage = 'Silakan masukkan kode voucher';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final validation = LicenseService.validateCode(rawCode);

    if (!validation.isValid) {
      setState(() {
        _isLoading = false;
        _errorMessage = validation.errorMessage ?? 'Kode lisensi tidak valid';
      });
      return;
    }

    final bBloc = context.read<BusinessBloc>();
    final currentBusiness = bBloc.state.businessInfo;

    if (currentBusiness == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Data toko belum siap. Silakan coba lagi.';
      });
      return;
    }

    final updatedBusiness = LicenseService.applyVoucherToBusiness(
      current: currentBusiness,
      voucher: validation,
    );

    bBloc.add(UpdateBusinessInfo(updatedBusiness));

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      final expDate = updatedBusiness.subscriptionExpiresAt != null
          ? DateFormat(
              'd MMMM yyyy',
              'id_ID',
            ).format(updatedBusiness.subscriptionExpiresAt!)
          : '-';

      final planTitle = validation.plan == 'yearly'
          ? 'Tahunan'
          : validation.plan == 'monthly'
          ? 'Bulanan'
          : 'Permanen';

      AppToast.showSuccess(
        context,
        'Selamat! Laci POS Pro ($planTitle) aktif hingga $expDate',
      );

      Navigator.of(context).pop(true);
    }
  }

  Future<void> _contactAdminWhatsApp() async {
    const message =
        'Halo Admin Laci POS, saya ingin membeli kode voucher lisensi Laci POS Pro.';
    final url = Uri.parse(
      'https://wa.me/6281615697675?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aktivasi Lisensi Pro',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Masukkan kode voucher untuk mengaktifkan status Pro',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: subtextColor,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: subtextColor,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Voucher Code Input
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: textColor,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                ],
                decoration: InputDecoration(
                  hintText: 'Contoh: PRO365-XXXX-XXXX',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    letterSpacing: 0.5,
                    color: subtextColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.normal,
                  ),
                  filled: true,
                  fillColor: inputBg,
                  prefixIcon: const Icon(
                    Icons.vpn_key_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  suffixIcon: _codeController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _codeController.clear();
                            setState(() => _errorMessage = null);
                          },
                        )
                      : null,
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
                      color: Color(0xFFF59E0B),
                      width: 1.8,
                    ),
                  ),
                  errorText: _errorMessage,
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: subtextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _activateCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Aktifkan',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Contact Admin Link
              Center(
                child: GestureDetector(
                  onTap: _contactAdminWhatsApp,

                  child: const Text(
                    'Belum punya kode? Hubungi Admin',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
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
