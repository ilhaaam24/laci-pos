import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/receipt_settings_service.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/business_entity.dart';
import '../../../domain/entities/product_variant.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../blocs/business/business_bloc.dart';
import '../../widgets/pro_badge.dart';
import '../../widgets/upgrade_pro_sheet.dart';
import '../checkout/widgets/receipt_image_widget.dart';

class ReceiptSettingsPage extends StatefulWidget {
  const ReceiptSettingsPage({super.key});

  @override
  State<ReceiptSettingsPage> createState() => _ReceiptSettingsPageState();
}

class _ReceiptSettingsPageState extends State<ReceiptSettingsPage> {
  final _receiptService = ReceiptSettingsService();
  final _picker = ImagePicker();

  late bool _showLogo;
  String? _customLogoPath;
  late bool _showWatermark;
  late TextEditingController _headerMsgController;
  late TextEditingController _footerMsgController;
  late TextEditingController _footerNoteController;
  late TextEditingController _socialWifiController;

  late bool _showAddress;
  late bool _showPhone;
  late bool _showCashierName;
  late bool _showCustomerName;
  late bool _showTableNumber;
  late bool _showItemNotes;

  bool _showLivePreview = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final cfg = _receiptService.config;
    _showLogo = cfg.showLogo;
    _customLogoPath = cfg.customLogoPath;
    _showWatermark = cfg.showWatermark;
    _headerMsgController = TextEditingController(text: cfg.headerMessage);
    _footerMsgController = TextEditingController(text: cfg.footerMessage);
    _footerNoteController = TextEditingController(text: cfg.footerNote);
    _socialWifiController = TextEditingController(text: cfg.socialMediaOrWifi);

    _showAddress = cfg.showAddress;
    _showPhone = cfg.showPhone;
    _showCashierName = cfg.showCashierName;
    _showCustomerName = cfg.showCustomerName;
    _showTableNumber = cfg.showTableNumber;
    _showItemNotes = cfg.showItemNotes;
  }

  @override
  void dispose() {
    _headerMsgController.dispose();
    _footerMsgController.dispose();
    _footerNoteController.dispose();
    _socialWifiController.dispose();
    super.dispose();
  }

  ReceiptConfig get _currentConfig => ReceiptConfig(
    showLogo: _showLogo,
    customLogoPath: _customLogoPath,
    showWatermark: _showWatermark,
    headerMessage: _headerMsgController.text,
    footerMessage: _footerMsgController.text,
    footerNote: _footerNoteController.text,
    socialMediaOrWifi: _socialWifiController.text,
    showAddress: _showAddress,
    showPhone: _showPhone,
    showCashierName: _showCashierName,
    showCustomerName: _showCustomerName,
    showTableNumber: _showTableNumber,
    showItemNotes: _showItemNotes,
  );

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _customLogoPath = picked.path;
          _showLogo = true;
        });
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Gagal memilih gambar: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final bState = context.read<BusinessBloc>().state;
      final isPro = bState.businessInfo?.isPro ?? false;
      final safeConfig = isPro
          ? _currentConfig
          : _currentConfig.copyWith(showLogo: false, showWatermark: true);
      await _receiptService.saveConfig(safeConfig);
      if (mounted) {
        AppToast.showSuccess(context, 'Pengaturan struk berhasil disimpan!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Gagal menyimpan pengaturan: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Pengaturan Struk'),
        content: const Text(
          'Apakah Anda yakin ingin mengembalikan semua format struk ke standar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _receiptService.resetToDefault();
      final cfg = _receiptService.config;
      setState(() {
        _showLogo = cfg.showLogo;
        _customLogoPath = cfg.customLogoPath;
        _showWatermark = cfg.showWatermark;
        _headerMsgController.text = cfg.headerMessage;
        _footerMsgController.text = cfg.footerMessage;
        _footerNoteController.text = cfg.footerNote;
        _socialWifiController.text = cfg.socialMediaOrWifi;
        _showAddress = cfg.showAddress;
        _showPhone = cfg.showPhone;
        _showCashierName = cfg.showCashierName;
        _showCustomerName = cfg.showCustomerName;
        _showTableNumber = cfg.showTableNumber;
        _showItemNotes = cfg.showItemNotes;
      });
      if (mounted) {
        AppToast.showSuccess(
          context,
          'Pengaturan struk dikembalikan ke standar',
        );
      }
    }
  }

  TransactionEntity _getSampleTransaction() {
    final now = DateTime.now();
    return TransactionEntity(
      id: 'sample_id',
      transactionCode: 'INV-20260922001',
      customerName: 'Budi Santoso',
      subtotal: 50000,
      taxAmount: 5000,
      discountAmount: 0,
      totalAmount: 55000,
      amountPaid: 60000,
      changeAmount: 5000,
      createdAt: now,
      createdBy: 'Kasir Utama',
      notes: 'Dine In (Meja 05)',
      payments: [
        PaymentDetail(type: PaymentType.cash, amount: 60000, timestamp: now),
      ],
      items: const [
        TransactionItem(
          id: 's1',
          productId: 'p1',
          productName: 'Kopi Susu Senja',
          selectedVariant: ProductVariant(
            id: 'v1',
            name: 'Regular',
            price: 25000,
          ),
          selectedModifiers: [
            ModifierOption(id: 'm1', name: 'Less Sugar', price: 0),
          ],
          notes: 'Tidak pakai es batu',
          quantity: 2,
          price: 25000,
          costPrice: 12000,
          subtotal: 50000,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final businessInfo = context.watch<BusinessBloc>().state.businessInfo;
    final isPro = businessInfo?.isPro ?? false;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Kustomisasi Struk',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        actions: [
          IconButton(
            tooltip: _showLivePreview
                ? 'Sembunyikan Preview'
                : 'Tampilkan Preview',
            icon: Icon(
              _showLivePreview
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
            onPressed: () =>
                setState(() => _showLivePreview = !_showLivePreview),
          ),
          IconButton(
            tooltip: 'Reset ke Standar',
            icon: const Icon(Icons.restore_rounded),
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            onPressed: _resetSettings,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,

            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isSaving ? 'Menyimpan...' : 'Simpan Pengaturan',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Live Preview Section
          if (_showLivePreview) ...[
            _buildLivePreviewCard(businessInfo, isDark),
            const SizedBox(height: 20),
          ],

          // 2. Logo Section (Fitur PRO)
          _buildLogoConfigCard(businessInfo, isDark, isPro),
          const SizedBox(height: 16),

          // 3. Header & Store Info
          _buildHeaderConfigCard(isDark),
          const SizedBox(height: 16),

          // 4. Transaction Metadata Toggles
          _buildMetadataConfigCard(isDark),
          const SizedBox(height: 16),

          // 5. Footer & Notes Section
          _buildFooterConfigCard(isDark),
          const SizedBox(height: 16),

          // 6. Watermark Section (Fitur PRO)
          _buildWatermarkConfigCard(isDark, isPro),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard(BusinessInfo? businessInfo, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ReceiptImageWidget(
                transaction: _getSampleTransaction(),
                businessInfo: businessInfo,
                config: _currentConfig,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoConfigCard(BusinessInfo? businessInfo, bool isDark, bool isPro) {
    final hasCustomLogo =
        _customLogoPath != null && File(_customLogoPath!).existsSync();
    final hasStoreLogo =
        businessInfo?.logoUrl != null &&
        businessInfo!.logoUrl!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_outlined,
                size: 20,
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              Text(
                'LOGO STRUK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              const ProBadge(),
            ],
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Tampilkan Logo di Struk',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              isPro
                  ? 'Tampilkan logo toko pada bagian atas struk digital & fisik'
                  : 'Cetak logo toko di struk membutuhkan paket Pro',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            value: isPro ? _showLogo : false,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              if (!isPro) {
                showUpgradeProSheet(
                  context,
                  featureName: 'Logo Toko & Bebas Watermark',
                );
                return;
              }
              setState(() => _showLogo = val);
            },
          ),
          if (_showLogo && isPro) ...[
            const Divider(height: 24),
            Row(
              children: [
                // Logo Thumbnail
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasCustomLogo
                      ? Image.file(File(_customLogoPath!), fit: BoxFit.cover)
                      : (hasStoreLogo
                            ? CachedNetworkImage(
                                imageUrl: businessInfo.logoUrl ?? '',
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.store_rounded, size: 28),
                              )
                            : const Icon(
                                Icons.receipt_long_rounded,
                                size: 28,
                                color: Color(0xFF94A3B8),
                              )),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasCustomLogo
                            ? 'Logo Kustom Struk Aktif'
                            : (hasStoreLogo
                                  ? 'Menggunakan Logo Toko Utama'
                                  : 'Belum Ada Logo (Menggunakan Ikon)'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              if (!isPro) {
                                showUpgradeProSheet(
                                  context,
                                  featureName: 'Logo Toko & Bebas Watermark',
                                );
                                return;
                              }
                              _pickLogo(ImageSource.gallery);
                            },
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'Galeri',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              if (!isPro) {
                                showUpgradeProSheet(
                                  context,
                                  featureName: 'Logo Toko & Bebas Watermark',
                                );
                                return;
                              }
                              _pickLogo(ImageSource.camera);
                            },
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'Kamera',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                          ),
                          if (hasCustomLogo)
                            TextButton.icon(
                              onPressed: () =>
                                   setState(() => _customLogoPath = null),
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Hapus Kustom',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWatermarkConfigCard(bool isDark, bool isPro) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.branding_watermark_outlined,
                size: 20,
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              Text(
                'WATERMARK STRUK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              const ProBadge(),
            ],
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Tampilkan Watermark Laci POS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              isPro
                  ? 'Matikan opsi ini untuk mencetak struk bersih tanpa watermark "LACI POS - Sistem Kasir Modern".'
                  : 'Struk akun Free menyertakan watermark. Upgrade ke Pro untuk bebas watermark.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            value: isPro ? _showWatermark : true,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              if (!isPro) {
                showUpgradeProSheet(
                  context,
                  featureName: 'Logo Toko & Bebas Watermark',
                );
                return;
              }
              setState(() => _showWatermark = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderConfigCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.title_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              Text(
                'HEADER & KONTAK TOKO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _headerMsgController,
            decoration: InputDecoration(
              labelText: 'Tagline / Pesan Pembuka Toko',
              hintText: 'Contoh: Spesialis Kopi Susu & Roti Bakar',
              hintStyle: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Tampilkan Alamat Toko',
              style: TextStyle(fontSize: 13.5),
            ),
            value: _showAddress,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _showAddress = val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Tampilkan Nomor Telepon',
              style: TextStyle(fontSize: 13.5),
            ),
            value: _showPhone,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _showPhone = val),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataConfigCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              Text(
                'RINCIAN TRANSAKSI PADA STRUK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Tampilkan Nama Kasir',
              style: TextStyle(fontSize: 13.5),
            ),
            value: _showCashierName,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _showCashierName = val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Tampilkan Nama Pelanggan',
              style: TextStyle(fontSize: 13.5),
            ),
            value: _showCustomerName,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _showCustomerName = val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Tampilkan Nomor Meja / Tipe Pesanan',
              style: TextStyle(fontSize: 13.5),
            ),
            value: _showTableNumber,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _showTableNumber = val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Tampilkan Catatan Khusus Item',
              style: TextStyle(fontSize: 13.5),
            ),
            value: _showItemNotes,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _showItemNotes = val),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterConfigCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              Text(
                'PESAN PENUTUP & FOOTER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _footerMsgController,
            decoration: InputDecoration(
              labelText: 'Pesan Terima Kasih',
              hintText: 'Contoh: TERIMA KASIH TELAH BERBELANJA!',
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _footerNoteController,
            decoration: InputDecoration(
              labelText: 'Catatan Bukti / Kebijakan Retur',
              hintText: 'Contoh: Barang yang sudah dibeli tidak dapat ditukar',
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _socialWifiController,
            decoration: InputDecoration(
              labelText: 'Info Tambahan (Instagram / Wi-Fi Toko)',
              hintText: 'Contoh: IG: @lacicafe | WiFi: KopiNikmat123',
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
