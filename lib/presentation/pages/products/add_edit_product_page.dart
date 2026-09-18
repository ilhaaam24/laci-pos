import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laci/core/services/cloudinary_service.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/product_entity.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/di/injection.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../widgets/barcode_scanner_page.dart';

class AddEditProductPage extends StatefulWidget {
  final Product? product;
  const AddEditProductPage({super.key, this.product});

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _costPriceController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _stockThresholdController;
  late TextEditingController _descriptionController;
  late TextEditingController _skuController;

  String? _selectedCategoryId;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _costPriceController = TextEditingController(
      text: widget.product?.costPrice.toStringAsFixed(0) ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toStringAsFixed(0) ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stock.toString() ?? '',
    );
    _stockThresholdController = TextEditingController(
      text: widget.product?.stockThreshold.toString() ?? '5',
    );
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _selectedCategoryId = widget.product?.categoryId;
    _imageUrl = widget.product?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _stockThresholdController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      AppToast.showWarning(context, 'Silakan pilih kategori produk');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final product = Product(
        id: widget.product?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        costPrice: double.parse(_costPriceController.text),
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        stockThreshold: int.parse(_stockThresholdController.text),
        categoryId: _selectedCategoryId!,
        imageUrl: _imageUrl,
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.product == null) {
        context.read<ProductBloc>().add(CreateProduct(product));
      } else {
        context.read<ProductBloc>().add(UpdateProduct(product));
      }

      Navigator.pop(context);
    } catch (e) {
      AppToast.showError(context, 'Gagal menyimpan produk: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleImageUpload() async {
    final uploadService = getIt<ImageUploadService>();
    final cloudinaryService = getIt<CloudinaryService>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Foto Produk',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF0F172A),
                ),
                title: const Text(
                  'Ambil dari Kamera',
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUpload(
                    uploadService,
                    cloudinaryService,
                    ImageSource.camera,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.image_outlined,
                  color: Color(0xFF0F172A),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUpload(
                    uploadService,
                    cloudinaryService,
                    ImageSource.gallery,
                  );
                },
              ),
              if (_imageUrl != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFDC2626),
                  ),
                  title: const Text(
                    'Hapus Foto',
                    style: TextStyle(color: Color(0xFFDC2626)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _imageUrl = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
    ImageUploadService uploadService,
    CloudinaryService cloudinaryService,
    ImageSource source,
  ) async {
    setState(() => _isUploading = true);
    try {
      final url = await cloudinaryService.uploadImage(source);
      if (url.isNotEmpty) {
        setState(() => _imageUrl = url);
        if (mounted) AppToast.showSuccess(context, 'Foto berhasil diunggah');
      } else {
        if (mounted) AppToast.showError(context, 'Gagal unggah foto');
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Gagal unggah foto: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _scanBarcodeForSku() async {
    final scannedCode = await BarcodeScannerPage.scan(
      context,
      title: 'Pindai Barcode Produk',
      instruction: 'Arahkan kamera ke barcode pada produk',
    );
    if (scannedCode != null && scannedCode.isNotEmpty) {
      setState(() {
        _skuController.text = scannedCode;
      });
      if (mounted) {
        AppToast.showSuccess(
          context,
          'Barcode berhasil dipindai: $scannedCode',
        );
      }
    }
  }

  void _generateSku() {
    final randomNum = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
        .toString();
    final newSku = 'PRD-$randomNum';
    setState(() {
      _skuController.text = newSku;
    });
    AppToast.showSuccess(context, 'SKU dibuat: $newSku');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.product == null ? 'Tambah Produk' : 'Edit Produk',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Image Picker
            Center(
              child: GestureDetector(
                onTap: (_isUploading || _isSaving) ? null : _handleImageUpload,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isUploading
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                      width: _isUploading ? 2 : 1,
                    ),
                  ),
                  child: _isUploading
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                      : _imageUrl != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: CachedNetworkImage(
                                imageUrl: _imageUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.broken_image_outlined,
                                      color: Color(0xFF94A3B8),
                                    ),
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 32,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tambah Foto',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Section: Informasi Dasar
            _buildCardGroup(
              title: 'INFORMASI PRODUK',
              children: [
                _buildLabel('Nama Produk'),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Contoh: Es Teh Manis',
                    prefixIcon: Icons.shopping_bag_outlined,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama produk tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('Kategori Produk'),
                BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, state) {
                    final categories = state.categories;

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: _buildInputDecoration(
                        hint: 'Pilih Kategori',
                        prefixIcon: Icons.category_outlined,
                      ),
                      items: categories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                      validator: (v) =>
                          v == null ? 'Pilih salah satu kategori' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildLabel('SKU / Barcode Produk (Opsional)'),
                TextFormField(
                  controller: _skuController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Scan atau ketik SKU / Barcode',
                    prefixIcon: Icons.qr_code_2_outlined,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _scanBarcodeForSku,
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Scan Barcode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _generateSku,
                        icon: const Icon(
                          Icons.auto_awesome_outlined,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                        label: const Text(
                          'Generate SKU',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabel('Deskripsi (Opsional)'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Keterangan atau varian produk...',
                    prefixIcon: Icons.description_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Section: Harga & Stok
            _buildCardGroup(
              title: 'HARGA & STOK',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Harga Modal'),
                          TextFormField(
                            controller: _costPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: _buildInputDecoration(
                              hint: '0',
                              prefixText: 'Rp ',
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Isi harga modal'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Harga Jual'),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: _buildInputDecoration(
                              hint: '0',
                              prefixText: 'Rp ',
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Isi harga jual'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Stok Saat Ini'),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: _buildInputDecoration(
                              hint: '0',
                              prefixIcon: Icons.inventory_2_outlined,
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Isi jumlah stok'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Batas Stok Tipis'),
                          TextFormField(
                            controller: _stockThresholdController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: _buildInputDecoration(
                              hint: '5',
                              prefixIcon: Icons.notifications_active_outlined,
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Isi batas stok'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: (_isUploading || _isSaving) ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.product == null
                            ? 'Simpan Produk'
                            : 'Simpan Perubahan',
                        style: const TextStyle(
                          color: Colors.white,
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
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildCardGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    IconData? prefixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: const Color(0xFF64748B))
          : null,
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
