import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/style/app_colors.dart';
import '../../core/utils/app_toast.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppUpdateCheckResult result;
  final VoidCallback? onUpdateTap;

  const AppUpdateDialog({
    super.key,
    required this.result,
    this.onUpdateTap,
  });

  static Future<void> show(
    BuildContext context,
    AppUpdateCheckResult result,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !result.isForced,
      builder: (_) => AppUpdateDialog(result: result),
    );
  }

  Future<void> _launchStoreUrl(BuildContext context) async {
    if (onUpdateTap != null) {
      onUpdateTap!();
      return;
    }

    final uri = Uri.tryParse(result.storeUrl);
    if (uri == null) {
      AppToast.showError(context, 'Tautan pembaruan tidak valid.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppToast.showError(
          context,
          'Tidak dapat membuka halaman toko aplikasi.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.showError(
          context,
          'Tidak dapat membuka halaman toko aplikasi.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : AppColors.surface;
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    final isForced = result.isForced;

    return PopScope(
      canPop: !isForced,
      child: Dialog(
        backgroundColor: bgColor,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.16)
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isForced ? 'Pembaruan Diperlukan' : 'Pembaruan Tersedia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isForced
                      ? 'Versi baru Laci POS telah tersedia. Perbarui aplikasi sekarang untuk melanjutkan dan mendapatkan perbaikan terbaru.'
                      : 'Versi terbaru Laci POS kini tersedia dengan peningkatan performa dan fitur baru.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    key: const ValueKey('update_now_button'),
                    onPressed: () => _launchStoreUrl(context),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Perbarui Sekarang',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isForced) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      key: const ValueKey('update_later_button'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Nanti Saja',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: subtextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

