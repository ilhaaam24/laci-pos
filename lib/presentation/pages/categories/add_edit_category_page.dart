import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../blocs/category/category_bloc.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../core/style/app_colors.dart';

class AddEditCategoryPage extends StatefulWidget {
  final Category? category;
  const AddEditCategoryPage({Key? key, this.category}) : super(key: key);

  @override
  State<AddEditCategoryPage> createState() => _AddEditCategoryPageState();
}

class _AddEditCategoryPageState extends State<AddEditCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.category?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (!_formKey.currentState!.validate()) return;

    final category = Category(
      id: widget.category?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      createdAt: widget.category?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.category == null) {
      context.read<CategoryBloc>().add(CreateCategory(category));
    } else {
      context.read<CategoryBloc>().add(UpdateCategory(category));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.category == null ? 'Tambah Kategori' : 'Edit Kategori',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kategori',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
              autofocus: true,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveCategory,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.category == null
                    ? 'SIMPAN KATEGORI'
                    : 'SIMPAN PERUBAHAN',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
