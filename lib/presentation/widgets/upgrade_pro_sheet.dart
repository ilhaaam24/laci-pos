import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header with Crown
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            Text(
                              'Laci POS',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'PRO',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buka potensi penuh bisnis Anda dengan lisensi sekali bayar selamanya.',
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
                    icon: Icon(Icons.close_rounded, color: subtextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              if (widget.featureName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fitur ini membutuhkan Pro: ${widget.featureName}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Visual Comparison Card: Free vs PRO
              _buildComparisonCard(
                isDark,
                cardBg,
                borderColor,
                textColor,
                subtextColor,
              ),

              const SizedBox(height: 14),

              // Lifetime Pricing Hero Card
              _buildLifetimePricingCard(
                isDark,
                cardBg,
                borderColor,
                textColor,
                subtextColor,
              ),

              const SizedBox(height: 16),

              // Primary Action: WhatsApp Order Button
              ElevatedButton(
                onPressed: _launchWhatsAppOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch_rounded, size: 19),
                    SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Beli Lisensi via WhatsApp (Rp 49.000)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Secondary Action: Outlined Voucher Activation Button
              if (widget.onVoucherTap != null) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: widget.onVoucherTap,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFF59E0B),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 18,
                        color: Color(0xFFF59E0B),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Sudah Punya Kode Voucher? Aktivasi di Sini',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF59E0B),
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Trust & Security Note
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: subtextColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Aktivasi instan via kode voucher • Garansi lisensi selamanya',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                        textAlign: TextAlign.center,
                        maxLines: 2,
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

  /// Comparison table container highlighting Free vs PRO features
  Widget _buildComparisonCard(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                  : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'FITUR BISNIS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: subtextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'FREE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: subtextColor,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRO 👑',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Comparison rows
          _buildComparisonRow(
            icon: Icons.all_inclusive_rounded,
            feature: 'Katalog Produk',
            freeVal: 'Maks 150',
            proVal: 'Tanpa Batas 🚀',
            isDark: isDark,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          _buildDivider(borderColor),
          _buildComparisonRow(
            icon: Icons.people_alt_rounded,
            feature: 'Multi-Kasir & PIN',
            freeVal: '1 Kasir',
            proVal: 'Banyak Staf 👥',
            isDark: isDark,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          _buildDivider(borderColor),
          _buildComparisonRow(
            icon: Icons.analytics_rounded,
            feature: 'Laporan Laba & HPP',
            freeVal: 'Omset Dasar',
            proVal: 'Analisis Real 📊',
            isDark: isDark,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          _buildDivider(borderColor),
          _buildComparisonRow(
            icon: Icons.file_download_rounded,
            feature: 'Export Excel & PDF',
            freeVal: '—',
            proVal: 'Lengkap 📑',
            isDark: isDark,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          _buildDivider(borderColor),
          _buildComparisonRow(
            icon: Icons.receipt_long_rounded,
            feature: 'Logo & Bebas Watermark',
            freeVal: 'Watermark',
            proVal: 'Logo Sendiri ✨',
            isDark: isDark,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          _buildDivider(borderColor),
          _buildComparisonRow(
            icon: Icons.cloud_sync_rounded,
            feature: 'Cloud Backup & Sync',
            freeVal: 'Lokal (1 HP)',
            proVal: 'Multi-Device ☁️',
            isDark: isDark,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Color borderColor) {
    return Divider(height: 1, thickness: 1, color: borderColor);
  }

  Widget _buildComparisonRow({
    required IconData icon,
    required String feature,
    required String freeVal,
    required String proVal,
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  freeVal,
                  style: TextStyle(
                    fontSize: 11,
                    color: subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  proVal,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lifetime Pricing Hero Card (Rp 49.000)
  Widget _buildLifetimePricingCard(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SEKALI BAYAR • AKTIF SELAMANYA',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Hemat 67%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                ),
              ),
              Text(
                'Rp 149.000',
                style: TextStyle(
                  fontSize: 12.5,
                  color: subtextColor,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Akses Seumur Hidup',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white : const Color(0xFF92400E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Tanpa tagihan bulanan. Sudah termasuk seluruh pembaruan fitur di masa depan.',
            style: TextStyle(fontSize: 11.5, color: subtextColor, height: 1.3),
          ),
        ],
      ),
    );
  }
}
