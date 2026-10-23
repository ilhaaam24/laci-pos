import 'package:drift/drift.dart';
import 'package:laci/data/models/promo_model.dart';
import 'package:laci/domain/entities/promo_entity.dart';
import 'local_database.dart';

/// Local data source for Promo operations using Drift/SQLite.
class PromoLocalDataSource {
  final LocalDatabase _db;

  PromoLocalDataSource(this._db);

  Stream<List<PromoModel>> watchPromos(String businessId) {
    final hasBusiness = businessId.isNotEmpty;
    final query = _db.select(_db.localPromos)
      ..where(
        (t) =>
            (hasBusiness
                ? (t.businessId.equals(businessId) |
                    t.businessId.isNull() |
                    t.businessId.equals(''))
                : const Constant(true)) &
            t.syncStatus.equals('pendingDelete').not(),
      );
    return query.watch().map(
      (rows) => rows.map((row) => _rowToModel(row)).toList(),
    );
  }

  Future<void> upsertPromo(
    PromoModel promo, {
    String syncStatus = 'pendingUpload',
  }) async {
    await _db
        .into(_db.localPromos)
        .insertOnConflictUpdate(
          LocalPromosCompanion.insert(
            id: promo.id,
            name: promo.name,
            type: promo.type.name,
            value: promo.value,
            minPurchase: Value(promo.minPurchase),
            isActive: Value(promo.isActive),
            startDate: Value(promo.startDate),
            endDate: Value(promo.endDate),
            businessId: Value(promo.businessId),
            syncStatus: Value(syncStatus),
            lastSyncAt: Value(syncStatus == 'synced' ? DateTime.now() : null),
          ),
        );
  }

  Future<void> markAsDeleted(String id) async {
    await (_db.update(_db.localPromos)..where((t) => t.id.equals(id))).write(
      const LocalPromosCompanion(syncStatus: Value('pendingDelete')),
    );
  }

  Future<void> hardDelete(String id) async {
    await (_db.delete(_db.localPromos)..where((t) => t.id.equals(id))).go();
  }

  Future<void> upsertFromRemote(List<PromoModel> promos) async {
    await _db.batch((batch) {
      for (final promo in promos) {
        batch.insert(
          _db.localPromos,
          LocalPromosCompanion.insert(
            id: promo.id,
            name: promo.name,
            type: promo.type.name,
            value: promo.value,
            minPurchase: Value(promo.minPurchase),
            isActive: Value(promo.isActive),
            startDate: Value(promo.startDate),
            endDate: Value(promo.endDate),
            businessId: Value(promo.businessId),
            syncStatus: const Value('synced'),
            lastSyncAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<PromoModel>> getPendingSync() async {
    final query = _db.select(_db.localPromos)
      ..where((t) => t.syncStatus.equals('synced').not());
    final rows = await query.get();
    return rows.map((row) => _rowToModel(row)).toList();
  }

  Future<void> markAsSynced(String id) async {
    await (_db.update(_db.localPromos)..where((t) => t.id.equals(id))).write(
      LocalPromosCompanion(
        syncStatus: const Value('synced'),
        lastSyncAt: Value(DateTime.now()),
      ),
    );
  }

  PromoModel _rowToModel(LocalPromo row) {
    return PromoModel(
      id: row.id,
      name: row.name,
      type: PromoType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => PromoType.fixed,
      ),
      value: row.value,
      minPurchase: row.minPurchase,
      isActive: row.isActive,
      startDate: row.startDate,
      endDate: row.endDate,
      businessId: row.businessId,
    );
  }
}
