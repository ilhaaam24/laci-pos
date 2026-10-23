import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:laci/core/style/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/app_toast.dart';

/// Shows the premium upgrade sheet or responsive dialog.
Future<void> showUpgradeProSheet(
  BuildContext context, {
  String? featureName,
  VoidCallback? onVoucherTap,
}) {
  final isTablet = MediaQuery.of(context).size.width >= 600;

  if (isTablet) {
    return showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: UpgradeProContent(
            featureName: featureName,
            onVoucherTap: () {
              Navigator.pop(dialogCtx);
              onVoucherTap?.call();
            },
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => UpgradeProContent(
      featureName: featureName,
      onVoucherTap: () {
        Navigator.pop(sheetCtx);
        onVoucherTap?.call();
      },
    ),
  );
}

class UpgradeProContent extends StatefulWidget {
  final String? featureName;
  final VoidCallback? onVoucherTap;

  const UpgradeProContent({super.key, this.featureName, this.onVoucherTap});

  @override
  State<UpgradeProContent> createState() => _UpgradeProContentState();
}

class _UpgradeProContentState extends State<UpgradeProContent> {
  Future<void> _launchWhatsAppOrder() async {
    const messageText =
        'Halo Admin Laci POS, saya ingin membeli Lisensi Laci POS Pro Lifetime (Rp 49.000). Bagaimana cara pembayarannya?';
    final message = Uri.encodeComponent(messageText);
    final url = Uri.parse('https://wa.me/6281615697675?text=$message');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppToast.showError(context, 'Tidak dapat membuka WhatsApp');
        }
      }
    } catch (_) {
      if (mounted) {
        AppToast.showError(context, 'Terjadi kendala saat membuka WhatsApp');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: Clean Icon + Title + Super Minimalist Price Tagline
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/icons/pro_badge.svg'),
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Laci POS',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Rp 49.000 • Sekali Bayar Selamanya',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: subtextColor,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // Feature Lock Alert (if triggered by a specific feature)
              if (widget.featureName != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fitur ini membutuhkan Pro: ${widget.featureName}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Minimalist Checklist Card: 4 Fitur Unggulan Pro (To The Point)
              _buildFeatureChecklistCard(
                isDark,
                cardBg,
                borderColor,
                textColor,
              ),

              const SizedBox(height: 16),

              // Super Minimalist Pricing Card
              _buildMinimalPricingCard(
                isDark,
                textColor,
                subtextColor,
                cardBg,
                borderColor,
              ),

              const SizedBox(height: 20),

              // Primary Action: WhatsApp Order Button
              ElevatedButton(
                onPressed: _launchWhatsAppOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Hubungi Admin',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Trust & Security Note (Short & clean)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: subtextColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Aktivasi instan • Lisensi aktif selamanya',
                        style: TextStyle(fontSize: 11.5, color: subtextColor),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Minimalist Checklist Card: 4 Essential Pro Features
  Widget _buildFeatureChecklistCard(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
  ) {
    const features = [
      'Katalog Produk & Transaksi Tanpa Batas',
      'Multi-Kasir & Hak Akses PIN Staf',
      'Laporan Laba/Rugi & Export Excel/PDF',
      'Cetak Struk Tanpa Watermark + Logo Toko',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'FITUR UNGGULAN PRO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (int i = 0; i < features.length; i++) ...[
            if (i > 0)
              Divider(
                height: 18,
                thickness: 0.8,
                color: borderColor.withValues(alpha: 0.7),
              ),
            Row(
              children: [
                const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    features[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Super Minimalist Pricing Card
  Widget _buildMinimalPricingCard(
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Text(
                      'Rp 49.000',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD97706),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Rp 149.000',
                      style: TextStyle(
                        fontSize: 13,
                        color: subtextColor,
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Sekali bayar • Tanpa langganan bulanan',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Hemat 67%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
