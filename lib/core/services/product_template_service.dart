import 'dart:developer';
import 'package:flutter/material.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/product_repository.dart';

enum BusinessTemplateType { coffeeShop, warung, retail, service }

class SampleProductSpec {
  final String name;
  final String categoryName;
  final double price;
  final double costPrice;
  final int stock;
  final String sku;
  final bool trackStock;
  final String? description;

  const SampleProductSpec({
    required this.name,
    required this.categoryName,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.sku,
    this.trackStock = true,
    this.description,
  });
}

class BusinessTemplateInfo {
  final BusinessTemplateType type;
  final String label;
  final String shortDesc;
  final String businessNameHint;
  final IconData icon;
  final List<String> categories;
  final List<SampleProductSpec> products;

  const BusinessTemplateInfo({
    required this.type,
    required this.label,
    required this.shortDesc,
    required this.businessNameHint,
    required this.icon,
    required this.categories,
    required this.products,
  });
}

class ProductTemplateService {
  final CategoryRepository categoryRepository;
  final ProductRepository productRepository;

  ProductTemplateService({
    required this.categoryRepository,
    required this.productRepository,
  });

  static const List<BusinessTemplateInfo> templates = [
    BusinessTemplateInfo(
      type: BusinessTemplateType.coffeeShop,
      label: 'Kopi & F&B',
      shortDesc: 'Cafe, kedai, resto',
      businessNameHint: 'Contoh: Kedai Kopi Maju',
      icon: Icons.coffee_rounded,
      categories: ['Kopi', 'Non-Kopi', 'Makanan Ringan'],
      products: [
        SampleProductSpec(
          name: 'Es Kopi Susu Gula Aren',
          categoryName: 'Kopi',
          price: 22000,
          costPrice: 9000,
          stock: 50,
          sku: 'KP-001',
          description: 'Espresso dengan susu segar dan gula aren pilihan',
        ),
        SampleProductSpec(
          name: 'Americano',
          categoryName: 'Kopi',
          price: 18000,
          costPrice: 6500,
          stock: 50,
          sku: 'KP-002',
          description: 'Espresso double shot dengan air mineral',
        ),
        SampleProductSpec(
          name: 'Matcha Latte',
          categoryName: 'Non-Kopi',
          price: 25000,
          costPrice: 11000,
          stock: 35,
          sku: 'NK-001',
          description: 'Pure matcha Jepang dengan susu creamy',
        ),
        SampleProductSpec(
          name: 'Teh Lemon Segar',
          categoryName: 'Non-Kopi',
          price: 15000,
          costPrice: 5000,
          stock: 40,
          sku: 'NK-002',
        ),
        SampleProductSpec(
          name: 'Croissant Butter',
          categoryName: 'Makanan Ringan',
          price: 24000,
          costPrice: 12000,
          stock: 20,
          sku: 'MK-001',
        ),
        SampleProductSpec(
          name: 'Kentang Goreng',
          categoryName: 'Makanan Ringan',
          price: 18000,
          costPrice: 8000,
          stock: 30,
          sku: 'MK-002',
        ),
      ],
    ),
    BusinessTemplateInfo(
      type: BusinessTemplateType.warung,
      label: 'Warung & Toko',
      shortDesc: 'Kelontong, sembako',
      businessNameHint: 'Contoh: Warung Berkah Jaya',
      icon: Icons.storefront_rounded,
      categories: ['Sembako', 'Minuman', 'Jajanan'],
      products: [
        SampleProductSpec(
          name: 'Beras Premium 5 kg',
          categoryName: 'Sembako',
          price: 72000,
          costPrice: 65000,
          stock: 20,
          sku: 'SB-001',
        ),
        SampleProductSpec(
          name: 'Minyak Goreng 1L',
          categoryName: 'Sembako',
          price: 18000,
          costPrice: 15500,
          stock: 30,
          sku: 'SB-002',
        ),
        SampleProductSpec(
          name: 'Mie Instan Goreng',
          categoryName: 'Sembako',
          price: 3500,
          costPrice: 2800,
          stock: 100,
          sku: 'SB-003',
        ),
        SampleProductSpec(
          name: 'Air Mineral 600ml',
          categoryName: 'Minuman',
          price: 4000,
          costPrice: 2200,
          stock: 80,
          sku: 'MN-001',
        ),
        SampleProductSpec(
          name: 'Teh Botol 350ml',
          categoryName: 'Minuman',
          price: 5000,
          costPrice: 3500,
          stock: 60,
          sku: 'MN-002',
        ),
        SampleProductSpec(
          name: 'Keripik Singkong',
          categoryName: 'Jajanan',
          price: 8000,
          costPrice: 5000,
          stock: 40,
          sku: 'JJ-001',
        ),
      ],
    ),
    BusinessTemplateInfo(
      type: BusinessTemplateType.retail,
      label: 'Retail & Fashion',
      shortDesc: 'Pakaian, aksesoris',
      businessNameHint: 'Contoh: Butik Gaya Rapi',
      icon: Icons.checkroom_rounded,
      categories: ['Atasan', 'Bawahan', 'Aksesoris'],
      products: [
        SampleProductSpec(
          name: 'Kaos Polos Cotton 30s',
          categoryName: 'Atasan',
          price: 65000,
          costPrice: 35000,
          stock: 30,
          sku: 'AT-001',
        ),
        SampleProductSpec(
          name: 'Kemeja Flanel Lengan Panjang',
          categoryName: 'Atasan',
          price: 145000,
          costPrice: 85000,
          stock: 15,
          sku: 'AT-002',
        ),
        SampleProductSpec(
          name: 'Celana Chino Slim',
          categoryName: 'Bawahan',
          price: 165000,
          costPrice: 95000,
          stock: 15,
          sku: 'BW-001',
        ),
        SampleProductSpec(
          name: 'Topi Baseball Canvas',
          categoryName: 'Aksesoris',
          price: 45000,
          costPrice: 22000,
          stock: 25,
          sku: 'AK-001',
        ),
        SampleProductSpec(
          name: 'Tote Bag Kanvas',
          categoryName: 'Aksesoris',
          price: 55000,
          costPrice: 25000,
          stock: 25,
          sku: 'AK-002',
        ),
      ],
    ),
    BusinessTemplateInfo(
      type: BusinessTemplateType.service,
      label: 'Jasa & Layanan',
      shortDesc: 'Barber, laundry, salon',
      businessNameHint: 'Contoh: Barbershop Klasik',
      icon: Icons.content_cut_rounded,
      categories: ['Layanan Utama', 'Layanan Tambahan'],
      products: [
        SampleProductSpec(
          name: 'Potong Rambut Dewasa',
          categoryName: 'Layanan Utama',
          price: 35000,
          costPrice: 5000,
          stock: 0,
          sku: 'JS-001',
          trackStock: false,
        ),
        SampleProductSpec(
          name: 'Potong Rambut Anak',
          categoryName: 'Layanan Utama',
          price: 25000,
          costPrice: 5000,
          stock: 0,
          sku: 'JS-002',
          trackStock: false,
        ),
        SampleProductSpec(
          name: 'Cuci & Pijat Kepala',
          categoryName: 'Layanan Tambahan',
          price: 20000,
          costPrice: 4000,
          stock: 0,
          sku: 'JS-003',
          trackStock: false,
        ),
        SampleProductSpec(
          name: 'Cukur Jenggot & Kumis',
          categoryName: 'Layanan Tambahan',
          price: 15000,
          costPrice: 3000,
          stock: 0,
          sku: 'JS-004',
          trackStock: false,
        ),
        SampleProductSpec(
          name: 'Pomade Waterbased',
          categoryName: 'Layanan Tambahan',
          price: 65000,
          costPrice: 38000,
          stock: 15,
          sku: 'PR-001',
          trackStock: true,
        ),
      ],
    ),
  ];

  static BusinessTemplateInfo getTemplate(BusinessTemplateType type) {
    return templates.firstWhere((t) => t.type == type);
  }

  /// Seeds sample categories and products for the selected [type].
  /// Returns the number of products successfully created.
  Future<int> seedTemplate(BusinessTemplateType type) async {
    final template = getTemplate(type);
    final now = DateTime.now();

    // Load existing categories to avoid creating duplicates by name
    final Map<String, String> categoryNameToId = {};
    try {
      final existingResult = await categoryRepository.getCategories().first;
      existingResult.fold((_) {}, (existingCategories) {
        for (final cat in existingCategories) {
          categoryNameToId[cat.name.trim().toLowerCase()] = cat.id;
        }
      });
    } catch (e) {
      log('ProductTemplateService: failed reading existing categories: $e');
    }

    // Create missing categories
    for (final catName in template.categories) {
      final key = catName.trim().toLowerCase();
      if (categoryNameToId.containsKey(key)) continue;

      final result = await categoryRepository.createCategory(
        Category(
          id: '',
          name: catName,
          createdAt: now,
          updatedAt: now,
        ),
      );
      result.fold(
        (err) => log('ProductTemplateService: createCategory($catName) error: $err'),
        (createdId) => categoryNameToId[key] = createdId,
      );
    }

    // Create sample products
    int createdCount = 0;
    for (final spec in template.products) {
      final categoryId =
          categoryNameToId[spec.categoryName.trim().toLowerCase()] ?? '';
      if (categoryId.isEmpty) continue;

      final result = await productRepository.createProduct(
        Product(
          id: '',
          categoryId: categoryId,
          name: spec.name,
          description: spec.description,
          price: spec.price,
          costPrice: spec.costPrice,
          stock: spec.stock,
          stockThreshold: 5,
          sku: spec.sku,
          trackStock: spec.trackStock,
          createdAt: now,
          updatedAt: now,
        ),
      );
      result.fold(
        (err) => log('ProductTemplateService: createProduct(${spec.name}) error: $err'),
        (_) => createdCount++,
      );
    }

    return createdCount;
  }
}

