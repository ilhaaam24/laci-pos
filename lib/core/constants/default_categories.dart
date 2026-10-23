import '../../data/models/category_model.dart';

class DefaultCategories {
  /// Mengembalikan daftar kategori default untuk bisnis baru.
  /// Waktu di-stagger agar ketika diurutkan secara descending (terbaru di atas),
  /// urutannya tetap konsisten: Makanan, Minuman, Snack, Dessert, Lainnya.
  static List<CategoryModel> getDefaults(
    String businessId, {
    DateTime? baseTime,
  }) {
    final now = baseTime ?? DateTime.now();
    return [
      CategoryModel(
        id: 'cat_${businessId}_makanan',
        name: 'Makanan',
        description: 'Aneka menu makanan',
        businessId: businessId,
        createdAt: now.add(const Duration(seconds: 4)),
        updatedAt: now.add(const Duration(seconds: 4)),
      ),
      CategoryModel(
        id: 'cat_${businessId}_minuman',
        name: 'Minuman',
        description: 'Aneka menu minuman',
        businessId: businessId,
        createdAt: now.add(const Duration(seconds: 3)),
        updatedAt: now.add(const Duration(seconds: 3)),
      ),
      CategoryModel(
        id: 'cat_${businessId}_snack',
        name: 'Snack',
        description: 'Camilan dan makanan ringan',
        businessId: businessId,
        createdAt: now.add(const Duration(seconds: 2)),
        updatedAt: now.add(const Duration(seconds: 2)),
      ),
      CategoryModel(
        id: 'cat_${businessId}_dessert',
        name: 'Dessert',
        description: 'Makanan penutup & hidangan manis',
        businessId: businessId,
        createdAt: now.add(const Duration(seconds: 1)),
        updatedAt: now.add(const Duration(seconds: 1)),
      ),
      CategoryModel(
        id: 'cat_${businessId}_lainnya',
        name: 'Lainnya',
        description: 'Kategori umum lainnya',
        businessId: businessId,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
