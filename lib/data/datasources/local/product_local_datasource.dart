import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:laci/data/models/product_model.dart';
import 'package:laci/domain/entities/product_variant.dart';
import 'local_database.dart';

/// Local data source for Product operations using Drift/SQLite.
class ProductLocalDataSource {
  final LocalDatabase _db;

  ProductLocalDataSource(this._db);

  /// Watch all products for the given business.
  Stream<List<ProductModel>> watchProducts(String businessId) {
    final query = _db.select(_db.localProducts)
      ..where(
        (t) =>
            t.businessId.equals(businessId) &
            t.syncStatus.equals('pendingDelete').not(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map(
      (rows) => rows.map((row) => _rowToModel(row)).toList(),
    );
  }

  /// Get all products for the given business (one-shot).
  Future<List<ProductModel>> getProducts(String businessId) async {
    final query = _db.select(_db.localProducts)
      ..where(
        (t) =>
            t.businessId.equals(businessId) &
            t.syncStatus.equals('pendingDelete').not(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await query.get();
    return rows.map((row) => _rowToModel(row)).toList();
  }

  /// Get a single product by ID.
  Future<ProductModel?> getProductById(String id) async {
    final query = _db.select(_db.localProducts)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  /// Insert or update a product locally (for offline create/update).
  Future<void> upsertProduct(
    ProductModel product, {
    String syncStatus = 'pendingUpload',
  }) async {
    await _db
        .into(_db.localProducts)
        .insertOnConflictUpdate(
          LocalProductsCompanion.insert(
            id: product.id,
            categoryId: product.categoryId,
            name: product.name,
            description: Value(product.description),
            price: product.price,
            costPrice: product.costPrice,
            stock: product.stock,
            stockThreshold: Value(product.stockThreshold),
            imageUrl: Value(product.imageUrl),
            sku: Value(product.sku),
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
            businessId: Value(product.businessId),
            syncStatus: Value(syncStatus),
            lastSyncAt: Value(syncStatus == 'synced' ? DateTime.now() : null),
            variants: Value(
              product.variants.isNotEmpty
                  ? jsonEncode(product.variants.map((e) => e.toJson()).toList())
                  : null,
            ),
            modifierGroups: Value(
              product.modifierGroups.isNotEmpty
                  ? jsonEncode(
                      product.modifierGroups.map((e) => e.toJson()).toList(),
                    )
                  : null,
            ),
          ),
        );
  }

  /// Mark a product as pending delete.
  Future<void> markAsDeleted(String id) async {
    await (_db.update(_db.localProducts)..where((t) => t.id.equals(id))).write(
      const LocalProductsCompanion(syncStatus: Value('pendingDelete')),
    );
  }

  /// Physically remove a product from local DB.
  Future<void> hardDelete(String id) async {
    await (_db.delete(_db.localProducts)..where((t) => t.id.equals(id))).go();
  }

  /// Bulk upsert products from Firebase (during sync pull).
  Future<void> upsertFromRemote(List<ProductModel> products) async {
    await _db.batch((batch) {
      for (final product in products) {
        batch.insert(
          _db.localProducts,
          LocalProductsCompanion.insert(
            id: product.id,
            categoryId: product.categoryId,
            name: product.name,
            description: Value(product.description),
            price: product.price,
            costPrice: product.costPrice,
            stock: product.stock,
            stockThreshold: Value(product.stockThreshold),
            imageUrl: Value(product.imageUrl),
            sku: Value(product.sku),
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
            businessId: Value(product.businessId),
            syncStatus: const Value('synced'),
            lastSyncAt: Value(DateTime.now()),
            variants: Value(
              product.variants.isNotEmpty
                  ? jsonEncode(product.variants.map((e) => e.toJson()).toList())
                  : null,
            ),
            modifierGroups: Value(
              product.modifierGroups.isNotEmpty
                  ? jsonEncode(
                      product.modifierGroups.map((e) => e.toJson()).toList(),
                    )
                  : null,
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Get all products that need to be synced to Firebase.
  Future<List<ProductModel>> getPendingSync() async {
    final query = _db.select(_db.localProducts)
      ..where((t) => t.syncStatus.equals('synced').not());
    final rows = await query.get();
    return rows.map((row) => _rowToModel(row)).toList();
  }

  /// Mark a product as synced.
  Future<void> markAsSynced(String id) async {
    await (_db.update(_db.localProducts)..where((t) => t.id.equals(id))).write(
      LocalProductsCompanion(
        syncStatus: const Value('synced'),
        lastSyncAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update stock locally (for offline transactions).
  Future<void> updateStock(String productId, int newStock) async {
    await (_db.update(
      _db.localProducts,
    )..where((t) => t.id.equals(productId))).write(
      LocalProductsCompanion(
        stock: Value(newStock),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pendingUpload'),
      ),
    );
  }

  /// Convert a Drift row to ProductModel.
  ProductModel _rowToModel(LocalProduct row) {
    List<ProductVariant> variants = const [];
    if (row.variants != null && row.variants!.isNotEmpty) {
      try {
        final decoded = jsonDecode(row.variants!) as List;
        variants = decoded
            .map((e) => ProductVariant.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }

    List<ModifierGroup> modifierGroups = const [];
    if (row.modifierGroups != null && row.modifierGroups!.isNotEmpty) {
      try {
        final decoded = jsonDecode(row.modifierGroups!) as List;
        modifierGroups = decoded
            .map((e) => ModifierGroup.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }

    return ProductModel(
      id: row.id,
      categoryId: row.categoryId,
      name: row.name,
      description: row.description,
      price: row.price,
      costPrice: row.costPrice,
      stock: row.stock,
      stockThreshold: row.stockThreshold,
      imageUrl: row.imageUrl,
      sku: row.sku,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      businessId: row.businessId,
      variants: variants,
      modifierGroups: modifierGroups,
    );
  }
}
