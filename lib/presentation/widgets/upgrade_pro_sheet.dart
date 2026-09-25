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
          constraints: const BoxConstraints(maxWidth: 520),
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
  bool _isYearly = true;

  Future<void> _launchWhatsAppOrder() async {
    final plan = _isYearly ? 'Tahunan (Rp 249.000)' : 'Bulanan (Rp 29.000)';
    final message = Uri.encodeComponent(
      'Halo Admin Laci POS, saya ingin berlangganan Laci POS Pro paket $plan. Bagaimana cara pembayarannya?',
    );
    final url = Uri.parse('https://wa.me/6281234567890?text=$message');

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
    final textColor = isDark ? Colors.black : const Color(0xFF0F172A);
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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

              // Header with Crown
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Laci POS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buka potensi penuh toko & bisnis Anda tanpa batasan',
                          style: TextStyle(
                            fontSize: 13,
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
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(8),
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

              const SizedBox(height: 18),

              // Feature Highlights List
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: Icons.all_inclusive_rounded,
                      title: 'Katalog Produk Tanpa Batas',
                      subtitle:
                          'Simpan ribuan produk & varian tanpa batas (Free maks 50)',
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.people_alt_rounded,
                      title: 'Multi-Kasir & PIN Cepat',
                      subtitle:
                          'Kelola kasir & staf dengan proteksi PIN dan hak akses',
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.analytics_rounded,
                      title: 'Laporan Laba Kotor & Analisis HPP',
                      subtitle:
                          'Pantau omset vs modal untuk ketahui laba bersih riil toko',
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.file_download_rounded,
                      title: 'Export Dokumen Excel & PDF',
                      subtitle: 'Unduh dan bagikan pembukuan penjualan lengkap',
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.receipt_long_rounded,
                      title: 'Logo Toko & Bebas Watermark',
                      subtitle:
                          'Cetak logo toko di struk tanpa watermark Laci POS',
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.cloud_sync_rounded,
                      title: 'Cloud Backup & Multi-Perangkat',
                      subtitle:
                          'Pantau penjualan secara langsung dari HP atau tablet mana pun',
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Plan Selector
              Row(
                children: [
                  // Yearly Plan Card
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isYearly = true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isYearly ? Color(0xFFF59E0B) : cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isYearly ? Colors.transparent : borderColor,
                            width: _isYearly ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tahunan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _isYearly
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : textColor,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Hemat 30%',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rp 249.000',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _isYearly
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : textColor,
                              ),
                            ),
                            Text(
                              '/ tahun (~Rp 20rb/bln)',
                              style: TextStyle(
                                fontSize: 11,
                                color: _isYearly
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Monthly Plan Card
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isYearly = false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: !_isYearly ? Color(0xFFF59E0B) : cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: !_isYearly
                                ? Colors.transparent
                                : borderColor,
                            width: !_isYearly ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bulanan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: !_isYearly
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rp 29.000',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: !_isYearly
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : textColor,
                              ),
                            ),
                            Text(
                              '/ bulan fleksibel',
                              style: TextStyle(
                                fontSize: 11,
                                color: !_isYearly
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Upgrade Button
              ElevatedButton(
                onPressed: _launchWhatsAppOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isYearly
                          ? 'Upgrade Sekarang (Rp 249.000 / Tahun)'
                          : 'Upgrade Sekarang (Rp 29.000 / Bulan)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  'Pembayaran aman & data terenkripsi.',
                  style: TextStyle(fontSize: 11, color: subtextColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),

          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: subtextColor,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
