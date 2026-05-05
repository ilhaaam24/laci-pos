import 'package:drift/drift.dart';
import 'package:laci/data/models/category_model.dart';
import 'local_database.dart';

/// Local data source for Category operations using Drift/SQLite.
class CategoryLocalDataSource {
  final LocalDatabase _db;

  CategoryLocalDataSource(this._db);

  Stream<List<CategoryModel>> watchCategories(String businessId) {
    final query = _db.select(_db.localCategories)
      ..where((t) =>
          t.businessId.equals(businessId) &
          t.syncStatus.equals('pendingDelete').not())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map(
        (rows) => rows.map((row) => _rowToModel(row)).toList());
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final query = _db.select(_db.localCategories)
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  Future<void> upsertCategory(CategoryModel category,
      {String syncStatus = 'pendingUpload'}) async {
    await _db.into(_db.localCategories).insertOnConflictUpdate(
          LocalCategoriesCompanion.insert(
            id: category.id,
            name: category.name,
            description: Value(category.description),
            imageUrl: Value(category.imageUrl),
            createdAt: category.createdAt,
            updatedAt: category.updatedAt,
            businessId: Value(category.businessId),
            syncStatus: Value(syncStatus),
            lastSyncAt: Value(syncStatus == 'synced' ? DateTime.now() : null),
          ),
        );
  }

  Future<void> markAsDeleted(String id) async {
    await (_db.update(_db.localCategories)..where((t) => t.id.equals(id)))
        .write(const LocalCategoriesCompanion(
      syncStatus: Value('pendingDelete'),
    ));
  }

  Future<void> hardDelete(String id) async {
    await (_db.delete(_db.localCategories)..where((t) => t.id.equals(id))).go();
  }

  Future<void> upsertFromRemote(List<CategoryModel> categories) async {
    await _db.batch((batch) {
      for (final cat in categories) {
        batch.insert(
          _db.localCategories,
          LocalCategoriesCompanion.insert(
            id: cat.id,
            name: cat.name,
            description: Value(cat.description),
            imageUrl: Value(cat.imageUrl),
            createdAt: cat.createdAt,
            updatedAt: cat.updatedAt,
            businessId: Value(cat.businessId),
            syncStatus: const Value('synced'),
            lastSyncAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<CategoryModel>> getPendingSync() async {
    final query = _db.select(_db.localCategories)
      ..where((t) => t.syncStatus.equals('synced').not());
    final rows = await query.get();
    return rows.map((row) => _rowToModel(row)).toList();
  }

  Future<void> markAsSynced(String id) async {
    await (_db.update(_db.localCategories)..where((t) => t.id.equals(id)))
        .write(LocalCategoriesCompanion(
      syncStatus: const Value('synced'),
      lastSyncAt: Value(DateTime.now()),
    ));
  }

  CategoryModel _rowToModel(LocalCategory row) {
    return CategoryModel(
      id: row.id,
      name: row.name,
      description: row.description,
      imageUrl: row.imageUrl,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      businessId: row.businessId,
    );
  }
}
