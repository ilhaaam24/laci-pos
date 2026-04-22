import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../core/style/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import 'add_edit_category_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kelola Kategori')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditCategoryPage()),
          );
        },
        backgroundColor: Colors.orange.shade700,
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state.isSuccess && state.message != null) {
            AppToast.showSuccess(context, state.message!);
          }
          if (state is CategoryError) {
            AppToast.showError(context, state.message!);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.categories.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: state.categories.length,
            itemBuilder: (context, index) {
              final category = state.categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: const Icon(Icons.category, color: Colors.orange),
                  ),
                  title: Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      category.description?.isNotEmpty == true
                          ? category.description!
                          : 'Tidak ada deskripsi',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddEditCategoryPage(category: category),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () => _showDeleteDialog(context, category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 100,
            color: Colors.orange.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada kategori',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan kategori untuk mengelompokkan produk Anda',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Hapus kategori "${category.name}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CategoryBloc>().add(DeleteCategory(category.id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
