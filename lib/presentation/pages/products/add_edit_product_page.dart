import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:laci/core/services/cloudinary_service.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/product_variant.dart';
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
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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

  List<ProductVariant> _variants = [];
  List<ModifierGroup> _modifierGroups = [];

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
    _variants = List.from(widget.product?.variants ?? []);
    _modifierGroups = List.from(widget.product?.modifierGroups ?? []);
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
        variants: _variants,
        modifierGroups: _modifierGroups,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.product == null ? 'Tambah Produk' : 'Edit Produk',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: borderColor),
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
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isUploading
                          ? AppColors.primary
                          : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1)),
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
                                width: double.infinity,
                                height: 200,
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
                  style: TextStyle(fontSize: 14, color: textColor),
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
                      dropdownColor: cardColor,
                      initialValue: _selectedCategoryId,
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: _buildInputDecoration(
                        hint: 'Pilih Kategori',
                        prefixIcon: Icons.category_outlined,
                      ),
                      items: categories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.name,
                            style: TextStyle(color: textColor),
                          ),
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
                  style: TextStyle(fontSize: 14, color: textColor),
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
                        icon: Icon(
                          Icons.qr_code_scanner,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF475569),
                        ),
                        label: Text(
                          'Scan Barcode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
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
                  style: TextStyle(fontSize: 14, color: textColor),
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
                            style: TextStyle(fontSize: 14, color: textColor),
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
                            style: TextStyle(fontSize: 14, color: textColor),
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
                            style: TextStyle(fontSize: 14, color: textColor),
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
                            style: TextStyle(fontSize: 14, color: textColor),
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
            const SizedBox(height: 16),

            // 4. Section: Varian Produk
            _buildVariantsSection(),
            const SizedBox(height: 16),

            // 5. Section: Modifiers & Topping
            _buildModifiersSection(),
            const SizedBox(height: 24),

            // 6. Submit Button
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

  Widget _buildVariantsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return _buildCardGroup(
      title: 'VARIAN PRODUK (OPSIONAL)',
      children: [
        const Text(
          'Tambahkan varian jika produk memiliki ukuran, rasa, warna, atau tipe berbeda dengan harga khusus.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        if (_variants.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/icons/variant.svg',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada varian produk',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Misal: Regular, Large, Panas, Dingin',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showVariantDialog(),
                  icon: const Icon(Icons.add, size: 16, color: AppColors.white),
                  label: const Text(
                    'Tambah Varian',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _variants.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final variant = _variants[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/variant.svg',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  variant.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (variant.sku != null &&
                                  variant.sku!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    variant.sku!,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                _currencyFormat.format(variant.price),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Stok: ${variant.stock}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              if (variant.costPrice > 0)
                                Text(
                                  'Modal: ${_currencyFormat.format(variant.costPrice)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () => _showVariantDialog(variant, index),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      onPressed: () =>
                          setState(() => _variants.removeAt(index)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showVariantDialog(),
              icon: const Icon(Icons.add, size: 16, color: AppColors.white),
              label: const Text(
                'Tambah Varian',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.primary,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showVariantDialog([ProductVariant? variant, int? index]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    final nameController = TextEditingController(text: variant?.name ?? '');
    final priceController = TextEditingController(
      text: variant != null
          ? variant.price.toStringAsFixed(0)
          : _priceController.text,
    );
    final costPriceController = TextEditingController(
      text: variant != null
          ? variant.costPrice.toStringAsFixed(0)
          : _costPriceController.text,
    );
    final stockController = TextEditingController(
      text: variant != null ? variant.stock.toString() : '',
    );
    final skuController = TextEditingController(text: variant?.sku ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            SvgPicture.asset('assets/icons/variant.svg', width: 32, height: 32),
            const SizedBox(width: 10),
            Text(
              variant == null ? 'Tambah Varian' : 'Edit Varian',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Nama Varian *'),
                TextFormField(
                  style: TextStyle(fontSize: 14, color: textColor),
                  controller: nameController,
                  decoration: _buildInputDecoration(
                    hint: 'Misal: Regular, Large, Panas, Dingin',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama varian wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                _buildLabel('Harga Jual Varian *'),
                TextFormField(
                  style: TextStyle(fontSize: 14, color: textColor),
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _buildInputDecoration(
                    hint: '0',
                    prefixText: 'Rp ',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Harga jual wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Harga Modal'),
                          TextFormField(
                            style: TextStyle(fontSize: 14, color: textColor),
                            controller: costPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _buildInputDecoration(
                              hint: '0',
                              prefixText: 'Rp ',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Stok (Opsional)'),
                          TextFormField(
                            style: TextStyle(fontSize: 14, color: textColor),
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _buildInputDecoration(hint: 'Stok'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildLabel('SKU / Barcode (Opsional)'),
                TextFormField(
                  style: TextStyle(fontSize: 14, color: textColor),
                  controller: skuController,
                  decoration: _buildInputDecoration(
                    hint: 'SKU khusus varian ini',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final newVariant = ProductVariant(
                id: variant?.id ?? const Uuid().v4(),
                name: nameController.text.trim(),
                price: double.parse(priceController.text.trim()),
                costPrice:
                    double.tryParse(costPriceController.text.trim()) ?? 0.0,
                stock: int.tryParse(stockController.text.trim()) ?? 0,
                sku: skuController.text.trim().isEmpty
                    ? null
                    : skuController.text.trim(),
              );
              setState(() {
                if (index != null) {
                  _variants[index] = newVariant;
                } else {
                  _variants.add(newVariant);
                }
              });
              Navigator.pop(dialogCtx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Simpan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifiersSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final containerBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return _buildCardGroup(
      title: 'ADD-ONS (OPSIONAL)',
      children: [
        Text(
          'Pilihan tambahan seperti topping (Boba, Jelly), level gula (Normal/Less), atau level pedas.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        if (_modifierGroups.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: containerBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/icons/group_modifier.svg',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada grup modifier',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Misal: Topping Boba, Extra Shot, Level Gula',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showModifierGroupDialog(),
                  icon: const Icon(Icons.add, size: 16, color: AppColors.white),
                  label: const Text(
                    'Tambah Grup Modifier',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _modifierGroups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final group = _modifierGroups[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: group.isRequired
                                      ? (isDark
                                            ? const Color(0xFF450A0A)
                                            : const Color(0xFFFEF2F2))
                                      : (isDark
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  group.isRequired ? 'Wajib' : 'Opsional',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: group.isRequired
                                        ? const Color(0xFFEF4444)
                                        : (isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF172554)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  group.allowMultiple ? 'Banyak' : '1 Pilihan',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          onPressed: () =>
                              _showModifierGroupDialog(group, index),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          onPressed: () =>
                              setState(() => _modifierGroups.removeAt(index)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: group.options.map((opt) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            opt.price > 0
                                ? '${opt.name} (+${_currencyFormat.format(opt.price)})'
                                : opt.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showModifierGroupDialog(),
              icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
              label: const Text(
                'Tambah Grup Modifier Lain',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showModifierGroupDialog([ModifierGroup? group, int? groupIndex]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    final groupNameController = TextEditingController(text: group?.name ?? '');
    bool isRequired = group?.isRequired ?? false;
    bool allowMultiple = group?.allowMultiple ?? true;
    List<ModifierOption> options = group != null
        ? List.from(group.options)
        : [];

    final optionNameController = TextEditingController();
    final optionPriceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group == null
                        ? 'Tambah Grup Modifier'
                        : 'Edit Grup Modifier',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLabel(
                'Nama Grup (misal: Topping, Level Gula, Level Pedas) *',
              ),
              TextFormField(
                style: TextStyle(fontSize: 14, color: textColor),
                controller: groupNameController,
                decoration: _buildInputDecoration(hint: 'Nama grup modifier'),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Wajib Dipilih?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  isRequired
                      ? 'Pelanggan harus memilih salah satu'
                      : 'Opsional / boleh dilewati',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                value: isRequired,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setSheetState(() => isRequired = val),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Boleh Pilih Lebih dari Satu?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  allowMultiple
                      ? 'Bisa pilih banyak opsi (Checklist)'
                      : 'Hanya boleh 1 opsi (Radio)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                value: allowMultiple,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setSheetState(() => allowMultiple = val),
              ),
              Divider(color: borderColor),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Opsi / Pilihan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${options.length} Opsi',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      style: TextStyle(fontSize: 14, color: textColor),
                      controller: optionNameController,
                      decoration: _buildInputDecoration(
                        hint: 'Nama opsi (mis: Boba)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      style: TextStyle(fontSize: 14, color: textColor),
                      controller: optionPriceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _buildInputDecoration(
                        hint: '0',
                        prefixText: '+Rp ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 20, color: Colors.white),
                    onPressed: () {
                      final name = optionNameController.text.trim();
                      if (name.isEmpty) return;
                      final price =
                          double.tryParse(optionPriceController.text.trim()) ??
                          0.0;
                      setSheetState(() {
                        options.add(
                          ModifierOption(
                            id: const Uuid().v4(),
                            name: name,
                            price: price,
                          ),
                        );
                        optionNameController.clear();
                        optionPriceController.clear();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, optIdx) {
                    final opt = options[optIdx];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          Text(
                            opt.price > 0
                                ? '+${_currencyFormat.format(opt.price)}'
                                : 'Gratis',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: opt.price > 0
                                  ? AppColors.primary
                                  : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                setSheetState(() => options.removeAt(optIdx)),
                            child: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    final groupName = groupNameController.text.trim();
                    if (groupName.isEmpty) {
                      AppToast.showWarning(
                        context,
                        'Nama grup modifier wajib diisi',
                      );
                      return;
                    }
                    if (options.isEmpty) {
                      AppToast.showWarning(
                        context,
                        'Tambahkan minimal 1 opsi untuk grup modifier',
                      );
                      return;
                    }
                    final newGroup = ModifierGroup(
                      id: group?.id ?? const Uuid().v4(),
                      name: groupName,
                      isRequired: isRequired,
                      allowMultiple: allowMultiple,
                      options: options,
                    );
                    setState(() {
                      if (groupIndex != null) {
                        _modifierGroups[groupIndex] = newGroup;
                      } else {
                        _modifierGroups.add(newGroup);
                      }
                    });
                    Navigator.pop(sheetCtx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Simpan Grup Modifier',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildCardGroup({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillCol = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderCol = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final hintCol = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final iconCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: hintCol),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: iconCol)
          : null,
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textCol,
      ),
      filled: true,
      fillColor: fillCol,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderCol),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderCol),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }
}
