import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/product_entity.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/di/injection.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';

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
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleImageUpload() async {
    final uploadService = getIt<ImageUploadService>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndUpload(uploadService, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Galeri'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndUpload(uploadService, ImageSource.gallery);
              },
            ),
            if (_imageUrl != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Hapus Foto',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imageUrl = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
    ImageUploadService uploadService,
    ImageSource source,
  ) async {
    setState(() => _isUploading = true);
    try {
      final url = await uploadService.pickAndUploadImage(
        folder: 'products',
        source: source,
      );
      if (url != null) {
        setState(() => _imageUrl = url);
        if (mounted) AppToast.showSuccess(context, 'Foto berhasil diunggah');
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Gagal unggah foto: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _saveProduct),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Image Picker
            Center(
              child: GestureDetector(
                onTap: (_isUploading || _isSaving) ? null : _handleImageUpload,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isUploading
                          ? AppColors.primary
                          : AppColors.divider,
                      width: _isUploading ? 2 : 1,
                    ),
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : _imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: _imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) {
                              debugPrint('Error loading image: $error');
                              return const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                              );
                            },
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 40,
                              color: AppColors.textDisabled,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tambah Foto',
                              style: TextStyle(
                                color: AppColors.textDisabled,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Center(
                  child: Text(
                    'Sedang mengunggah...',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Name
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(48),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Nama tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Category Dropdown
                  BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, state) {
                      final categories = state.categories;

                      return DropdownButtonFormField<String>(
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: categories.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategoryId = v),
                        validator: (v) => v == null ? 'Pilih kategori' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Cost Price & Selling Price
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _costPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Harga Modal',
                            prefixText: 'Rp ',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Isi harga modal' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Harga Jual',
                            prefixText: 'Rp ',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Isi harga jual' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stock
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stok Saat Ini',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Isi stok' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stockThresholdController,
                          decoration: const InputDecoration(
                            labelText: 'Batas Stok',
                            prefixIcon: Icon(
                              Icons.notifications_active_outlined,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Isi batas' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi (Opsional)',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(48),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextButton(
                onPressed: (_isUploading || _isSaving) ? null : _saveProduct,
                child: Text(
                  widget.product == null ? 'Tambah Produk' : 'Simpan Perubahan',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
