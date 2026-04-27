import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/business/business_bloc.dart';
import '../../../domain/entities/business_entity.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/image_upload_service.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();

    // Load existing info
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Info Bisnis')),
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
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionCard(
                    title: 'Identitas Toko',
                    children: [
                      const Text(
                        'Nama Bisnis',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Nama tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Alamat',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Kontak',
                    children: [
                      const Text(
                        'Nomor Telepon',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Metode Pembayaran QRIS',
                    children: [
                      const Text(
                        'Unggah gambar QRIS Anda agar pelanggan dapat melakukan pembayaran dengan memindai kode.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_qrisUrl != null ||
                          (state.businessInfo?.qrisUrl != null &&
                              state.businessInfo!.qrisUrl!.isNotEmpty))
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _qrisUrl ?? state.businessInfo?.qrisUrl ?? '',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isUploading ? null : _onUploadQRIS,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.qr_code_2),
                        label: Text(
                          _isUploading ? 'Mengunggah...' : 'Unggah QRIS',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(48),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextButton(
                      onPressed: state.isLoading || state.businessInfo == null
                          ? null
                          : () => _onSave(state.businessInfo),
                      child: Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
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
        logoUrl: currentInfo.logoUrl,
        qrisUrl: _qrisUrl ?? currentInfo.qrisUrl,
        createdAt: currentInfo.createdAt,
        updatedAt: DateTime.now(),
      );

      context.read<BusinessBloc>().add(UpdateBusinessInfo(updatedInfo));
    }
  }

  String? _qrisUrl;
  bool _isUploading = false;

  Future<void> _onUploadQRIS() async {
    setState(() => _isUploading = true);
    try {
      final url = await getIt<ImageUploadService>().pickAndUploadImage(
        folder: 'qris',
      );
      if (url != null) {
        setState(() => _qrisUrl = url);
      }
    } catch (e) {
      AppToast.showError(context, 'Gagal mengunggah QRIS: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }
}
