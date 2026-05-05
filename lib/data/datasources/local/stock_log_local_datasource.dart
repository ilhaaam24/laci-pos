import 'package:drift/drift.dart';
import 'package:laci/data/models/stock_log_model.dart';
import 'package:laci/domain/entities/stock_log_entity.dart';
import 'local_database.dart';

/// Local data source for StockLog operations using Drift/SQLite.
class StockLogLocalDataSource {
  final LocalDatabase _db;

  StockLogLocalDataSource(this._db);

  Stream<List<StockLogModel>> watchStockLogs(String businessId,
      {String? productId}) {
    var query = _db.select(_db.localStockLogs)
      ..where((t) =>
          t.businessId.equals(businessId) &
          t.syncStatus.equals('pendingDelete').not())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (productId != null) {
      query = _db.select(_db.localStockLogs)
        ..where((t) =>
            t.businessId.equals(businessId) &
            t.productId.equals(productId) &
            t.syncStatus.equals('pendingDelete').not())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    }
    return query.watch().map(
        (rows) => rows.map((row) => _rowToModel(row)).toList());
  }

  Future<void> insertStockLog(StockLogModel log,
      {String syncStatus = 'pendingUpload'}) async {
    await _db.into(_db.localStockLogs).insert(
          LocalStockLogsCompanion.insert(
            id: log.id,
            productId: log.productId,
            productName: log.productName,
            type: log.type.name,
            quantity: log.quantity,
            previousStock: log.previousStock,
            newStock: log.newStock,
            reason: Value(log.reason),
            createdAt: log.createdAt,
            businessId: Value(log.businessId),
            syncStatus: Value(syncStatus),
            lastSyncAt: Value(syncStatus == 'synced' ? DateTime.now() : null),
          ),
        );
  }

  Future<void> upsertFromRemote(List<StockLogModel> logs) async {
    await _db.batch((batch) {
      for (final log in logs) {
        batch.insert(
          _db.localStockLogs,
          LocalStockLogsCompanion.insert(
            id: log.id,
            productId: log.productId,
            productName: log.productName,
            type: log.type.name,
            quantity: log.quantity,
            previousStock: log.previousStock,
            newStock: log.newStock,
            reason: Value(log.reason),
            createdAt: log.createdAt,
            businessId: Value(log.businessId),
            syncStatus: const Value('synced'),
            lastSyncAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<StockLogModel>> getPendingSync() async {
    final query = _db.select(_db.localStockLogs)
      ..where((t) => t.syncStatus.equals('synced').not());
    final rows = await query.get();
    return rows.map((row) => _rowToModel(row)).toList();
  }

  Future<void> markAsSynced(String id) async {
    await (_db.update(_db.localStockLogs)..where((t) => t.id.equals(id)))
        .write(LocalStockLogsCompanion(
      syncStatus: const Value('synced'),
      lastSyncAt: Value(DateTime.now()),
    ));
  }

  StockLogModel _rowToModel(LocalStockLog row) {
    return StockLogModel(
      id: row.id,
      productId: row.productId,
      productName: row.productName,
      type: StockLogType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => StockLogType.adjustment,
      ),
      quantity: row.quantity,
      previousStock: row.previousStock,
      newStock: row.newStock,
      reason: row.reason,
      createdAt: row.createdAt,
      businessId: row.businessId,
    );
  }
}
