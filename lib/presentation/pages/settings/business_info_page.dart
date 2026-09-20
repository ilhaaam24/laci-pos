import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:laci/core/services/cloudinary_service.dart';
import '../../blocs/business/business_bloc.dart';
import '../../../domain/entities/business_entity.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/di/injection.dart';

class BusinessInfoPage extends StatefulWidget {
  const BusinessInfoPage({super.key});

  @override
  State<BusinessInfoPage> createState() => _BusinessInfoPageState();
}

class _BusinessInfoPageState extends State<BusinessInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  String? _logoUrl;
  bool _isUploadingLogo = false;
  String? _qrisUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();

    final state = context.read<BusinessBloc>().state;
    if (state.businessInfo != null) {
      _populateFields(state.businessInfo!);
    } else {
      context.read<BusinessBloc>().add(LoadBusinessInfo());
    }
  }

  void _populateFields(BusinessInfo info) {
    _nameController.text = info.businessName;
    _addressController.text = info.address ?? '';
    _phoneController.text = info.phone ?? '';
    _emailController.text = info.email ?? '';
    _logoUrl = info.logoUrl;
    _qrisUrl = info.qrisUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showLogoPickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Ubah Logo Usaha',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                title: Text(
                  'Ambil dari Kamera',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _onUploadLogo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _onUploadLogo(ImageSource.gallery);
                },
              ),
              if (_logoUrl != null && _logoUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFDC2626),
                  ),
                  title: const Text(
                    'Hapus Logo',
                    style: TextStyle(color: Color(0xFFDC2626)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _logoUrl = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onUploadLogo(ImageSource source) async {
    setState(() => _isUploadingLogo = true);
    try {
      final url = await getIt<CloudinaryService>().uploadImage(source);
      if (url.isNotEmpty) {
        setState(() => _logoUrl = url);
        if (mounted) {
          AppToast.showSuccess(context, 'Logo usaha berhasil diunggah');
        }
      } else {
        if (mounted) {
          AppToast.showError(context, 'Gagal mengunggah logo usaha');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Gagal mengunggah logo usaha: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _onUploadQRIS() async {
    setState(() => _isUploading = true);
    try {
      final url = await getIt<CloudinaryService>().uploadImage(
        ImageSource.gallery,
      );
      if (url.isNotEmpty) {
        setState(() => _qrisUrl = url);
        if (mounted) AppToast.showSuccess(context, 'QRIS berhasil diunggah');
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Gagal mengunggah QRIS: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _onSave(BusinessInfo? currentInfo) {
    if (currentInfo == null) {
      AppToast.showError(context, 'Informasi bisnis belum dimuat');
      return;
    }

    if (_formKey.currentState!.validate()) {
      final updatedInfo = BusinessInfo(
        id: currentInfo.id,
        businessName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        logoUrl: _logoUrl != null && _logoUrl!.isNotEmpty ? _logoUrl : null,
        qrisUrl: _qrisUrl != null && _qrisUrl!.isNotEmpty ? _qrisUrl : null,
        createdAt: currentInfo.createdAt,
        updatedAt: DateTime.now(),
      );

      context.read<BusinessBloc>().add(UpdateBusinessInfo(updatedInfo));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profil Bisnis & QRIS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: BlocConsumer<BusinessBloc, BusinessState>(
        listener: (context, state) {
          if (state.isSuccess && state.message != null) {
            AppToast.showSuccess(context, state.message!);
            Navigator.pop(context);
          }
          if (state.isSuccess && state.businessInfo != null) {
            _populateFields(state.businessInfo!);
          }
          if (state.message != null && !state.isSuccess) {
            AppToast.showError(context, state.message!);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.businessInfo == null) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          final effectiveLogo = _logoUrl ?? state.businessInfo?.logoUrl ?? '';
          final effectiveQris = _qrisUrl ?? state.businessInfo?.qrisUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCardGroup(
                    title: 'IDENTITAS TOKO',
                    isDark: isDark,
                    children: [
                      // Logo Toko / Usaha
                      _buildLabel('Logo Usaha', isDark: isDark),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _isUploadingLogo
                                  ? null
                                  : _showLogoPickerSheet,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _isUploadingLogo
                                            ? AppColors.primary
                                            : (isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFCBD5E1)),
                                        width: _isUploadingLogo ? 2 : 1,
                                      ),
                                    ),
                                    child: _isUploadingLogo
                                        ? const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.primary),
                                              ),
                                            ),
                                          )
                                        : (effectiveLogo.isNotEmpty)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              13,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: effectiveLogo,
                                              width: 76,
                                              height: 76,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                              errorWidget:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Center(
                                                    child: Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                            ),
                                          )
                                        : const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                size: 26,
                                                color: Color(0xFF94A3B8),
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                'Unggah',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                  if (!_isUploadingLogo)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF1E293B)
                                                : Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    effectiveLogo.isNotEmpty
                                        ? 'Logo terpasang'
                                        : 'Belum ada logo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Format PNG/JPG. Ditampilkan pada profil toko dan aplikasi.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Nama Usaha / Toko', isDark: isDark),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: Laci Kopi & Resto',
                          prefixIcon: Icons.storefront_outlined,
                          isDark: isDark,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Nama bisnis tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Alamat Usaha (Dicetak pada Struk)', isDark: isDark),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'Jl. Pemuda No. 12, Kelurahan...',
                          prefixIcon: Icons.location_on_outlined,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCardGroup(
                    title: 'KONTAK BISNIS',
                    isDark: isDark,
                    children: [
                      _buildLabel('Nomor Telepon / WhatsApp', isDark: isDark),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: _buildInputDecoration(
                          hint: '0812xxxxxxxx',
                          prefixIcon: Icons.phone_outlined,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Email Bisnis', isDark: isDark),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'kontak@tokoanda.com',
                          prefixIcon: Icons.email_outlined,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCardGroup(
                    title: 'METODE PEMBAYARAN QRIS',
                    isDark: isDark,
                    children: [
                      Text(
                        'Unggah gambar QRIS statis Anda agar kasir dapat menampilkan barcode QRIS langsung ke pelanggan saat checkout.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (effectiveQris != null && effectiveQris.isNotEmpty)
                        Column(
                          children: [
                            Container(
                              height: 220,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.network(
                                  effectiveQris,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image_outlined,
                                              color: Color(0xFF94A3B8),
                                              size: 32,
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              'Gagal memuat gambar QRIS',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isUploading
                                        ? null
                                        : _onUploadQRIS,
                                    icon: Icon(
                                      Icons.refresh,
                                      size: 16,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    label: Text(
                                      'Ganti Gambar QRIS',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _qrisUrl = ''),
                                  tooltip: 'Hapus QRIS',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _isUploading ? null : _onUploadQRIS,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.qr_code_2,
                                  color: AppColors.primary,
                                ),
                          label: Text(
                            _isUploading
                                ? 'Sedang Mengunggah...'
                                : 'Unggah Barcode QRIS',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state.isLoading || state.businessInfo == null
                          ? null
                          : () => _onSave(state.businessInfo),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text, {bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildCardGroup({
    required String title,
    required List<Widget> children,
    bool isDark = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    bool isDark = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(
        prefixIcon,
        size: 20,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }
}
