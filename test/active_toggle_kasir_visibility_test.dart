import 'package:flutter_test/flutter_test.dart';
import 'package:laci/domain/entities/product_entity.dart';
import 'package:laci/domain/entities/category_entity.dart';
import 'package:laci/data/models/product_model.dart';
import 'package:laci/data/models/category_model.dart';

void main() {
  group('Product and Category isActive Entity & Model Tests', () {
    test('Product defaults to isActive = true', () {
      final product = Product(
        id: 'p1',
        categoryId: 'c1',
        name: 'Kopi Susu',
        price: 15000,
        costPrice: 8000,
        stock: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(product.isActive, isTrue);
    });

    test('Product copyWith toggles isActive correctly', () {
      final product = Product(
        id: 'p1',
        categoryId: 'c1',
        name: 'Kopi Susu',
        price: 15000,
        costPrice: 8000,
        stock: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      final inactiveProduct = product.copyWith(isActive: false);
      expect(inactiveProduct.isActive, isFalse);
      expect(inactiveProduct.name, 'Kopi Susu');
      expect(inactiveProduct.id, 'p1');

      final reactivated = inactiveProduct.copyWith(isActive: true);
      expect(reactivated.isActive, isTrue);
    });

    test('Category defaults to isActive = true', () {
      final category = Category(
        id: 'c1',
        name: 'Minuman',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(category.isActive, isTrue);
    });

    test('Category copyWith toggles isActive correctly', () {
      final category = Category(
        id: 'c1',
        name: 'Minuman',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      final inactiveCategory = category.copyWith(isActive: false);
      expect(inactiveCategory.isActive, isFalse);
      expect(inactiveCategory.name, 'Minuman');

      final reactivated = inactiveCategory.copyWith(isActive: true);
      expect(reactivated.isActive, isTrue);
    });

    test('ProductModel JSON and Firestore serialization preserves isActive', () {
      final now = DateTime.now();
      final model = ProductModel(
        id: 'prod_123',
        categoryId: 'cat_abc',
        name: 'Es Teh Manis',
        price: 5000,
        costPrice: 2000,
        stock: 50,
        createdAt: now,
        updatedAt: now,
        isActive: false,
      );

      final json = model.toJson();
      expect(json['isActive'], isFalse);

      final fromJson = ProductModel.fromJson(json);
      expect(fromJson.isActive, isFalse);

      final firestoreMap = model.toFirestore();
      expect(firestoreMap['isActive'], isFalse);
    });

    test('CategoryModel JSON and Firestore serialization preserves isActive', () {
      final now = DateTime.now();
      final model = CategoryModel(
        id: 'cat_123',
        name: 'Snack',
        createdAt: now,
        updatedAt: now,
        isActive: false,
      );

      final json = model.toJson();
      expect(json['isActive'], isFalse);

      final fromJson = CategoryModel.fromJson(json);
      expect(fromJson.isActive, isFalse);

      final firestoreMap = model.toFirestore();
      expect(firestoreMap['isActive'], isFalse);
    });
  });

  group('Kasir Filter Logic Tests for Inactive Products and Categories', () {
    final catActive = Category(
      id: 'c_active',
      name: 'Makanan',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    final catInactive = Category(
      id: 'c_inactive',
      name: 'Musiman',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
    );

    final prod1Active = Product(
      id: 'p1',
      categoryId: 'c_active',
      name: 'Nasi Goreng',
      price: 25000,
      costPrice: 15000,
      stock: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    final prod2Inactive = Product(
      id: 'p2',
      categoryId: 'c_active',
      name: 'Mie Goreng (Off)',
      price: 20000,
      costPrice: 12000,
      stock: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false, // Inactive product in active category
    );

    final prod3UnderInactiveCategory = Product(
      id: 'p3',
      categoryId: 'c_inactive',
      name: 'Ketupat Lebaran',
      price: 30000,
      costPrice: 18000,
      stock: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true, // Active product in INACTIVE category
    );

    test('Kasir Category tabs only display categories where isActive == true', () {
      final allCategories = [catActive, catInactive];
      final visibleCategories = allCategories.where((c) => c.isActive).toList();

      expect(visibleCategories.length, 1);
      expect(visibleCategories.first.name, 'Makanan');
      expect(visibleCategories.any((c) => c.id == 'c_inactive'), isFalse);
    });

    test('Kasir Product filter excludes inactive products and products in inactive categories', () {
      final allProducts = [prod1Active, prod2Inactive, prod3UnderInactiveCategory];
      final inactiveCategoryIds = [catActive, catInactive]
          .where((c) => !c.isActive)
          .map((c) => c.id)
          .toSet();

      final kasirProducts = allProducts.where((p) {
        if (!p.isActive) return false;
        if (inactiveCategoryIds.contains(p.categoryId)) return false;
        return true;
      }).toList();

      // Only prod1Active should be visible in Kasir
      expect(kasirProducts.length, 1);
      expect(kasirProducts.first.id, 'p1');
      expect(kasirProducts.first.name, 'Nasi Goreng');
    });
  });
}

